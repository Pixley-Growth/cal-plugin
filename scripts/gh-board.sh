#!/usr/bin/env bash
set -euo pipefail

# gh-board.sh — GitHub Projects V2 wrapper for Cal
# Provides atomic board operations. All output is plain text or JSON.
# Exits 0 on success, 1 on failure. Warnings go to stderr.

EPICS_BOARD="Epics"
FEATURES_BOARD="Features"
EPICS_COLUMNS=("Idea" "In Progress" "Ready to Ship" "Released")
FEATURES_COLUMNS=("Cal" "Lisa" "Ralph" "QA" "Cleanup")

# --- Helpers ---

get_repo() {
  gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null
}

get_owner() {
  gh repo view --json owner -q '.owner.login' 2>/dev/null
}

check_auth() {
  if ! gh auth status &>/dev/null; then
    echo "WARNING: gh CLI not authenticated. Skipping board operations." >&2
    exit 1
  fi
  if ! get_repo &>/dev/null; then
    echo "WARNING: No GitHub remote found. Skipping board operations." >&2
    exit 1
  fi
}

# Get the node ID of the repo
get_repo_id() {
  local repo
  repo=$(get_repo)
  gh api graphql -f query="
    query {
      repository(owner: \"${repo%/*}\", name: \"${repo#*/}\") {
        id
      }
    }" -q '.data.repository.id'
}

# Find a project by title owned by the current user
find_project() {
  local title="$1"
  local owner
  owner=$(get_owner)
  gh api graphql -f query="
    query {
      user(login: \"${owner}\") {
        projectsV2(first: 20) {
          nodes {
            title
            id
            number
          }
        }
      }
    }" -q ".data.user.projectsV2.nodes[] | select(.title == \"${title}\") | .id" 2>/dev/null || echo ""
}

# Create a project owned by the current user
create_project() {
  local title="$1"
  local owner_id
  owner_id=$(gh api graphql -f query='query { viewer { id } }' -q '.data.viewer.id')
  gh api graphql -f query="
    mutation {
      createProjectV2(input: {ownerId: \"${owner_id}\", title: \"${title}\"}) {
        projectV2 {
          id
          number
        }
      }
    }" -q '.data.createProjectV2.projectV2.id'
}

# Get the Status field ID for a project
get_status_field_id() {
  local project_id="$1"
  gh api graphql -f query="
    query {
      node(id: \"${project_id}\") {
        ... on ProjectV2 {
          field(name: \"Status\") {
            ... on ProjectV2SingleSelectField {
              id
            }
          }
        }
      }
    }" -q '.data.node.field.id'
}

# Get all status options for a project
get_status_options() {
  local project_id="$1"
  gh api graphql -f query="
    query {
      node(id: \"${project_id}\") {
        ... on ProjectV2 {
          field(name: \"Status\") {
            ... on ProjectV2SingleSelectField {
              id
              options {
                id
                name
              }
            }
          }
        }
      }
    }" -q '.data.node.field'
}

# Create a status option (column) on a project
create_status_option() {
  local project_id="$1"
  local field_id="$2"
  local option_name="$3"
  gh api graphql -f query="
    mutation {
      updateProjectV2Field(input: {
        projectId: \"${project_id}\",
        fieldId: \"${field_id}\",
        singleSelectOptions: $(get_options_with_new "$project_id" "$option_name")
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            options { id name }
          }
        }
      }
    }" -q '.data.updateProjectV2Field.projectV2Field.options[-1].id' 2>/dev/null
}

# Build the options array including a new option
get_options_with_new() {
  local project_id="$1"
  local new_name="$2"
  local existing
  existing=$(gh api graphql -f query="
    query {
      node(id: \"${project_id}\") {
        ... on ProjectV2 {
          field(name: \"Status\") {
            ... on ProjectV2SingleSelectField {
              options { name }
            }
          }
        }
      }
    }" -q '[.data.node.field.options[].name]')

  # Build JSON array of all options (existing + new)
  echo "$existing" | python3 -c "
import json, sys
names = json.load(sys.stdin)
names.append('$new_name')
print(json.dumps([{'name': n} for n in names]))
"
}

# Set up columns on a project by replacing default options
setup_columns() {
  local project_id="$1"
  shift
  local columns=("$@")

  local field_id
  field_id=$(get_status_field_id "$project_id")

  # Build the full options array
  local options_json="["
  local first=true
  for col in "${columns[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      options_json+=","
    fi
    options_json+="{\"name\":\"${col}\"}"
  done
  options_json+="]"

  gh api graphql -f query="
    mutation {
      updateProjectV2Field(input: {
        projectId: \"${project_id}\",
        fieldId: \"${field_id}\",
        singleSelectOptions: ${options_json}
      }) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            options { id name }
          }
        }
      }
    }" >/dev/null 2>&1
}

# Link a project to a repository
link_project_to_repo() {
  local project_id="$1"
  local repo_id="$2"
  gh api graphql -f query="
    mutation {
      linkProjectV2ToRepository(input: {
        projectId: \"${project_id}\",
        repositoryId: \"${repo_id}\"
      }) {
        repository { id }
      }
    }" >/dev/null 2>&1
}

# Get issue node ID from issue number
get_issue_node_id() {
  local issue_number="$1"
  local repo
  repo=$(get_repo)
  gh api graphql -f query="
    query {
      repository(owner: \"${repo%/*}\", name: \"${repo#*/}\") {
        issue(number: ${issue_number}) {
          id
        }
      }
    }" -q '.data.repository.issue.id'
}

# Add an issue to a project, return the item ID
add_issue_to_project() {
  local project_id="$1"
  local issue_id="$2"
  gh api graphql -f query="
    mutation {
      addProjectV2ItemById(input: {
        projectId: \"${project_id}\",
        contentId: \"${issue_id}\"
      }) {
        item { id }
      }
    }" -q '.data.addProjectV2ItemById.item.id'
}

# Get the option ID for a column name
get_option_id() {
  local project_id="$1"
  local column_name="$2"
  gh api graphql -f query="
    query {
      node(id: \"${project_id}\") {
        ... on ProjectV2 {
          field(name: \"Status\") {
            ... on ProjectV2SingleSelectField {
              options {
                id
                name
              }
            }
          }
        }
      }
    }" -q ".data.node.field.options[] | select(.name == \"${column_name}\") | .id"
}

# Set the status of a project item
set_item_status() {
  local project_id="$1"
  local item_id="$2"
  local field_id="$3"
  local option_id="$4"
  gh api graphql -f query="
    mutation {
      updateProjectV2ItemFieldValue(input: {
        projectId: \"${project_id}\",
        itemId: \"${item_id}\",
        fieldId: \"${field_id}\",
        value: {singleSelectOptionId: \"${option_id}\"}
      }) {
        projectV2Item { id }
      }
    }" >/dev/null 2>&1
}

# Find the project item ID for an issue in a project
find_item_in_project() {
  local project_id="$1"
  local issue_node_id="$2"
  gh api graphql -f query="
    query {
      node(id: \"${project_id}\") {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              content {
                ... on Issue {
                  id
                  number
                }
              }
            }
          }
        }
      }
    }" -q ".data.node.items.nodes[] | select(.content.id == \"${issue_node_id}\") | .id"
}

# Get the current status/column of an item
get_item_status() {
  local project_id="$1"
  local item_id="$2"
  gh api graphql -f query="
    query {
      node(id: \"${item_id}\") {
        ... on ProjectV2Item {
          fieldValueByName(name: \"Status\") {
            ... on ProjectV2ItemFieldSingleSelectValue {
              name
            }
          }
        }
      }
    }" -q '.data.node.fieldValueByName.name'
}

# --- Commands ---

cmd_ensure_boards() {
  check_auth
  local repo_id
  repo_id=$(get_repo_id)

  local created=""

  # Epics board
  local epics_id
  epics_id=$(find_project "$EPICS_BOARD")
  if [ -z "$epics_id" ]; then
    epics_id=$(create_project "$EPICS_BOARD")
    setup_columns "$epics_id" "${EPICS_COLUMNS[@]}"
    link_project_to_repo "$epics_id" "$repo_id"
    created="${created}Epics "
  fi

  # Features board
  local features_id
  features_id=$(find_project "$FEATURES_BOARD")
  if [ -z "$features_id" ]; then
    features_id=$(create_project "$FEATURES_BOARD")
    setup_columns "$features_id" "${FEATURES_COLUMNS[@]}"
    link_project_to_repo "$features_id" "$repo_id"
    created="${created}Features "
  fi

  if [ -n "$created" ]; then
    echo "Created boards: ${created}"
  else
    echo "Both boards already exist"
  fi
}

cmd_create_issue() {
  check_auth
  local title="$1"
  local body="${2:-}"
  local labels="${3:-}"
  local repo
  repo=$(get_repo)

  # Ensure labels exist (gh issue create fails if label doesn't exist)
  if [ -n "$labels" ]; then
    IFS=',' read -ra label_arr <<< "$labels"
    for label in "${label_arr[@]}"; do
      if ! gh api "repos/${repo}/labels/$(python3 -c "import urllib.parse; print(urllib.parse.quote('${label}', safe=''))")" &>/dev/null; then
        gh api "repos/${repo}/labels" -f name="$label" -f color="ededed" >/dev/null 2>&1 || true
      fi
    done
  fi

  local args=(gh issue create --title "$title" --body "$body")
  if [ -n "$labels" ]; then
    for label in "${label_arr[@]}"; do
      args+=(--label "$label")
    done
  fi

  # Create issue and capture the URL
  local url
  url=$("${args[@]}" 2>&1)
  # Extract issue number from URL
  local number
  number=$(echo "$url" | grep -oE '[0-9]+$')
  echo "$number"
}

cmd_move_card() {
  check_auth
  local issue_number="$1"
  local board_name="$2"
  local column_name="$3"

  local project_id
  project_id=$(find_project "$board_name")
  if [ -z "$project_id" ]; then
    echo "ERROR: Board '${board_name}' not found" >&2
    exit 1
  fi

  local issue_node_id
  issue_node_id=$(get_issue_node_id "$issue_number")

  # Find or add item to project
  local item_id
  item_id=$(find_item_in_project "$project_id" "$issue_node_id")
  if [ -z "$item_id" ]; then
    item_id=$(add_issue_to_project "$project_id" "$issue_node_id")
  fi

  # Get field ID and option ID
  local field_id
  field_id=$(get_status_field_id "$project_id")
  local option_id
  option_id=$(get_option_id "$project_id" "$column_name")
  if [ -z "$option_id" ]; then
    echo "ERROR: Column '${column_name}' not found on board '${board_name}'" >&2
    exit 1
  fi

  set_item_status "$project_id" "$item_id" "$field_id" "$option_id"
  echo "Moved #${issue_number} to ${board_name}/${column_name}"
}

cmd_get_card_column() {
  check_auth
  local issue_number="$1"
  local board_name="$2"

  local project_id
  project_id=$(find_project "$board_name")
  if [ -z "$project_id" ]; then
    echo "ERROR: Board '${board_name}' not found" >&2
    exit 1
  fi

  local issue_node_id
  issue_node_id=$(get_issue_node_id "$issue_number")

  local item_id
  item_id=$(find_item_in_project "$project_id" "$issue_node_id")
  if [ -z "$item_id" ]; then
    echo "NOT_ON_BOARD"
    exit 0
  fi

  get_item_status "$project_id" "$item_id"
}

cmd_get_board_state() {
  check_auth
  local board_name="$1"

  local project_id
  project_id=$(find_project "$board_name")
  if [ -z "$project_id" ]; then
    echo "ERROR: Board '${board_name}' not found" >&2
    exit 1
  fi

  gh api graphql -f query="
    query {
      node(id: \"${project_id}\") {
        ... on ProjectV2 {
          title
          items(first: 100) {
            nodes {
              fieldValueByName(name: \"Status\") {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                }
              }
              content {
                ... on Issue {
                  number
                  title
                  state
                  labels(first: 10) {
                    nodes { name }
                  }
                }
              }
            }
          }
        }
      }
    }" -q '.data.node'
}

cmd_create_milestone() {
  check_auth
  local title="$1"
  local repo
  repo=$(get_repo)

  # Check if milestone already exists
  local existing
  existing=$(gh api "repos/${repo}/milestones" -q ".[] | select(.title == \"${title}\") | .title" 2>/dev/null || echo "")
  if [ -n "$existing" ]; then
    echo "$title"
    return 0
  fi

  gh api "repos/${repo}/milestones" -f title="$title" -q '.title'
}

cmd_list_epics_for_milestone() {
  check_auth
  local milestone="$1"
  local repo
  repo=$(get_repo)

  # Get milestone number
  local milestone_number
  milestone_number=$(gh api "repos/${repo}/milestones" -q ".[] | select(.title == \"${milestone}\") | .number" 2>/dev/null)
  if [ -z "$milestone_number" ]; then
    echo "ERROR: Milestone '${milestone}' not found" >&2
    exit 1
  fi

  gh issue list --milestone "$milestone" --label "type:epic" --json number,title -q '.[] | "#\(.number) \(.title)"'
}

cmd_list_features_for_epic() {
  check_auth
  local epic_slug="$1"
  gh issue list --label "epic:${epic_slug}" --label "type:feature" --json number,title,state -q '.[] | "#\(.number) [\(.state)] \(.title)"'
}

cmd_get_issue_by_title() {
  check_auth
  local title="$1"
  gh issue list --search "\"${title}\" in:title" --json number,title -q ".[] | select(.title == \"${title}\") | .number" | head -1
}

cmd_close_issue() {
  check_auth
  local issue_number="$1"
  gh issue close "$issue_number"
  echo "Closed #${issue_number}"
}

cmd_set_milestone_on_issue() {
  check_auth
  local issue_number="$1"
  local milestone="$2"
  local repo
  repo=$(get_repo)

  # Get milestone number
  local milestone_number
  milestone_number=$(gh api "repos/${repo}/milestones" -q ".[] | select(.title == \"${milestone}\") | .number" 2>/dev/null)
  if [ -z "$milestone_number" ]; then
    echo "ERROR: Milestone '${milestone}' not found" >&2
    exit 1
  fi

  gh api "repos/${repo}/issues/${issue_number}" -X PATCH -f milestone="$milestone_number" >/dev/null 2>&1
  echo "Set milestone '${milestone}' on #${issue_number}"
}

# --- Main dispatch ---

cmd="${1:-}"
shift || true

case "$cmd" in
  ensure-boards)          cmd_ensure_boards ;;
  create-issue)           cmd_create_issue "$@" ;;
  move-card)              cmd_move_card "$@" ;;
  get-card-column)        cmd_get_card_column "$@" ;;
  create-milestone)       cmd_create_milestone "$@" ;;
  list-epics-for-milestone) cmd_list_epics_for_milestone "$@" ;;
  list-features-for-epic) cmd_list_features_for_epic "$@" ;;
  get-board-state)        cmd_get_board_state "$@" ;;
  get-issue-by-title)     cmd_get_issue_by_title "$@" ;;
  close-issue)            cmd_close_issue "$@" ;;
  set-milestone-on-issue) cmd_set_milestone_on_issue "$@" ;;
  *)
    echo "Usage: gh-board.sh <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  ensure-boards                          Create Epics + Features boards"
    echo "  create-issue <title> <body> [labels]   Create issue, return number"
    echo "  move-card <issue> <board> <column>     Move issue to column"
    echo "  get-card-column <issue> <board>        Get current column"
    echo "  create-milestone <title>               Create milestone"
    echo "  list-epics-for-milestone <milestone>   List Epics in milestone"
    echo "  list-features-for-epic <epic-slug>     List Features for Epic"
    echo "  get-board-state <board>                Dump board state"
    echo "  get-issue-by-title <title>             Find issue by title"
    echo "  close-issue <issue>                    Close an issue"
    echo "  set-milestone-on-issue <issue> <ms>    Set milestone on issue"
    exit 1
    ;;
esac
