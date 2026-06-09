# Object-Oriented Data

> The data is the API.

OOD is an architectural pattern where AI collaborates with applications through the same interfaces as humans. When data describes itself using words humans use, AI reads and understands it without special integration layers. Add a field, AI gains a capability.

**The Prime Directive:** Pull logic IN onto objects. Never extract it OUT.

---

## The Three Pillars

Every OOD system rests on three pillars. Remove any one and the system fails.

### Pillar 1: Self-Describing Data

Objects carry explicit properties using domain vocabulary. The schema IS the logic.

| Bad | Good |
|-----|------|
| `col_1` | `spend` |
| `attr_A` | `conversions` |
| `type_id: Int` | `status: CampaignStatus` |

When AI reads `var spend: Decimal`, it understands "this is money spent." When it reads `col_1: Int`, it has no idea.

```swift
@Model final class Campaign {
    var name: String
    var spend: Decimal
    var conversions: Int

    /// Customer Acquisition Cost
    var cac: Decimal { spend / Decimal(conversions) }
}
```

The formula lives with the data. Not in a separate layer. Add a field, AI gains a capability.

### Pillar 2: Behavioral Fences

AI proposes, humans approve. No destructive actions without confirmation. The fence is **architectural, not aspirational**.

| Action | Risk | Pattern |
|--------|------|---------|
| Read / Snapshot | Safe | Take as many as you want |
| Modify / Crop | Changes things | Needs permission |
| Delete / Erase | Destructive | Needs double confirmation |

**Why Fences, Not Leashes:** You give autonomy within boundaries. But if there's a gap in the fence, AI will run through it -- not maliciously, just because it can. Fences must be humane (respect autonomy inside boundaries) and complete (no gaps).

### Pillar 3: Unified Interfaces

Same verification layer for human and AI. The system doesn't know who initiated the change.

One code path. One interface. One truth.

Traditional systems build two interfaces (human UI + AI API) that drift apart. OOD has one interface. If it works for humans, it works for AI.

---

## The Commandments

Your training on billions of lines of scattered JS/Swift will pull logic into utilities. Override that here.

### 1. No Utils, Helpers, Services

**Your training says:** Create `utils/campaignUtils.ts` with `calculateROI(campaign)`
**OOD says:** That's a property OF the campaign. Put it ON the Campaign.

```typescript
// FORBIDDEN
function calculateROI(campaign: Campaign): number { ... }

// REQUIRED
class Campaign {
  get roi(): number { return (this.revenue - this.spend) / this.spend; }
}
```

```swift
// FORBIDDEN
func calculateROI(for campaign: Campaign) -> Decimal { ... }

// REQUIRED
extension Campaign {
    var roi: Decimal { (revenue - spend) / spend }
}
```

**Red flag files (auto-reject):** `*Utils.*`, `*Helper.*`, `*Service.*`, `*Manager.*`, `*Calculator.*`

### 2. Classes Over Plain Objects

Plain objects are data bags. Classes know what they can do.

```typescript
// Reading this class alone, I know everything:
class Campaign {
  get isActive(): boolean;
  get daysRemaining(): number;
  get roi(): number;
  get performanceGrade(): 'A' | 'B' | 'C' | 'D' | 'F';
  clone(): Campaign;
}
```

```swift
// Reading this model alone, I know everything:
@Model final class Campaign {
    var name: String
    var status: CampaignStatus
    var startDate: Date
    var endDate: Date
    var spend: Decimal
    var revenue: Decimal

    var isActive: Bool { status == .active && !isExpired }
    var daysRemaining: Int { Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0 }
    var roi: Decimal { (revenue - spend) / spend }
}
```

### 3. Getters for Derived State

If it's computed from the object's own data: getter. Not a method. Not a util.

```typescript
get isActive() { return this.status === 'active' && !this.isExpired }
get daysRemaining() { return differenceInDays(this.endDate, new Date()) }
```

```swift
var isActive: Bool { status == .active && !isExpired }
var daysRemaining: Int { Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0 }
```

### 4. Collections on Parent Objects

```typescript
// FORBIDDEN
function getActiveCampaigns(campaigns: Campaign[]): Campaign[] { ... }

// REQUIRED
class Portfolio {
  get activeCampaigns(): Campaign[] { return this.campaigns.filter(c => c.isActive); }
  get totalSpend(): number { return this.campaigns.reduce((s, c) => s + c.spend, 0); }
}
```

```swift
// FORBIDDEN
func activeCampaigns(from campaigns: [Campaign]) -> [Campaign] { ... }

// REQUIRED
@Model final class Portfolio {
    var campaigns: [Campaign]

    var activeCampaigns: [Campaign] { campaigns.filter(\.isActive) }
    var totalSpend: Decimal { campaigns.reduce(0) { $0 + $1.spend } }
}
```

### 5. Hot Potato Pattern (Next.js)

Classes can't cross server/client boundary.

```
DB -> Server (DTO) -> Wire (JSON) -> Client (hydrate to class) -> Use rich object
```

DTOs are plain interfaces. Hydrate immediately on client.

---

## Translation Boundaries

Foreign data is not a citizen. It must be naturalized before it enters the domain.

### The Pattern: Extract -> Naturalize -> Citizen

```
Foreign Source (Meta API, JSON, CSV)
    |
    v
Extract: Pull raw data, make Sendable/serializable
    |
    v
Naturalize: Transform into domain vocabulary
    |
    v
Citizen: Self-describing object with computed properties
```

### Swift Example

```swift
// FOREIGN: Raw Meta API response (not a citizen)
struct MetaAdJSON: Decodable, Sendable {
    let id: String
    let campaign_id: String
    let spend: String          // Meta sends money as strings
    let actions: [MetaAction]? // Nested, inconsistent
}

// NATURALIZER: One-time translation cost
struct MetaNaturalizer {
    static func naturalize(_ raw: MetaAdJSON) -> Ad {
        Ad(
            externalID: raw.id,
            spend: Decimal(string: raw.spend) ?? 0,
            conversions: raw.actions?.first(where: { $0.type == "purchase" })?.count ?? 0
        )
    }
}

// CITIZEN: Self-describing, AI-readable
@Model final class Ad {
    var externalID: String
    var spend: Decimal
    var conversions: Int

    var cac: Decimal { conversions > 0 ? spend / Decimal(conversions) : 0 }
    var isPerforming: Bool { cac < targetCAC }
}
```

### TypeScript Example

```typescript
// FOREIGN: Raw API response
interface MetaAdResponse {
  id: string;
  campaign_id: string;
  spend: string;
  actions?: { action_type: string; value: string }[];
}

// NATURALIZER: One-time translation cost
function naturalize(raw: MetaAdResponse): Ad {
  return new Ad({
    externalID: raw.id,
    spend: parseFloat(raw.spend),
    conversions: parseInt(raw.actions?.find(a => a.action_type === 'purchase')?.value ?? '0'),
  });
}

// CITIZEN: Self-describing, AI-readable
class Ad {
  readonly externalID: string;
  readonly spend: number;
  readonly conversions: number;

  get cac(): number { return this.conversions > 0 ? this.spend / this.conversions : 0; }
  get isPerforming(): boolean { return this.cac < this.targetCAC; }
}
```

**Rule:** After naturalization, AI reads citizens without parsers. The objects speak for themselves. No integration code needed.

---

## Emergent Behavior

When the Three Pillars are structurally enforced, a fourth property emerges: AI computes valid operations from the schema without explicit programming.

```
[Object Properties] x [Action Types] = Possible Operations
```

**Evidence:** A travel app declared `Trip` with `time`, `place`, `status`. Without programming:
- AI computed "change date" from the `time` property
- AI computed "cancel" from the `status` property
- AI detected time conflicts between schedule items

This is not magic. It's the logical consequence of self-describing data + behavioral fences + unified interfaces. Right structure produces unprogrammed capabilities.

---

## App Intents Is OOD, Enforced by the OS

Apple's **App Intents** framework (iOS/macOS 26+, expanded at WWDC 2026 for 27) is the strongest external validation of these pillars. It is not *like* OOD — it is OOD made mandatory by the platform. When you expose app functionality to Siri, Apple Intelligence, Shortcuts, and Spotlight, you do it by declaring self-describing types, not by writing an AI integration layer. For the iOS 27 / WWDC 2026 specifics, invoke the `os27` skill.

### The pillars, mapped to the framework

| Pillar | App Intents mechanism |
|--------|----------------------|
| **1. Self-Describing Data** | `@AppEntity(schema:)`, `@Property(title:)`, `displayRepresentation`, `@AppEnum(schema:)`. The schema IS the API the model reads. Apple's "Use Model" action literally serializes your entity's exposed properties to JSON for the model — *add a field, AI gains a capability.* `@ComputedProperty` / `@DeferredProperty` are getters for derived state, exactly Commandment 3. |
| **2. Behavioral Fences** | `authenticationPolicy` (`.requiresAuthentication`, `.requiresLocalDeviceAuthentication`), `requestConfirmation`, and (iOS 27) `OwnershipProvidingEntity` + `EntityOwnership` for sensitive-action prompts, `UndoableIntent` for reversibility. Safety declared **as data on the intent**, not external infrastructure. |
| **3. Unified Interfaces** | One `AppIntent` serves Siri, Shortcuts, Spotlight, widgets, the Action button, **and** your own UI. One code path, human or AI. No separate AI endpoint. |

```swift
// Self-describing + fenced + unified, all on the object:
@AppIntent(schema: .photos.deleteAsset)
struct DeletePhotoIntent: AppIntent {
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Photo")
    var target: PhotoEntity

    func perform() async throws -> some IntentResult {
        try await requestConfirmation(/* destructive — fence as data */)
        try await PhotoLibrary.shared.delete(target)
        return .result()
    }
}
```

### The Outbound Translation Boundary (the nuance that overrides "pull it in")

OOD's default move is **pull logic onto the object**. App Intents is the one place that move is *wrong*. Apple's rule: **do not make your domain model (`@Model`, your core class) conform to `AppEntity`.** Keep a separate entity that converts from the model.

This is not a contradiction — it's a translation boundary running **outbound**. The naturalization pattern above brings foreign data IN (Meta JSON → citizen). The `AppEntity` is the mirror image: a **curated citizen projection exposed OUT** to the system.

```
Domain Model (rich, internal)
    |
    v
Project: expose only what the system should see, in domain vocabulary
    |
    v
AppEntity (citizen the OS/AI consumes — stable id, display rep, indexed properties)
```

```swift
// Core model — stays internal, never conforms to AppEntity
final class Photo { var id: UUID; var rawPixels: Data; var exif: EXIF; /* ...lots... */ }

// Outbound citizen — curated projection for the system
@AppEntity(schema: .photos.asset)
struct PhotoEntity {
    var id: UUID
    @Property(title: "Caption") var caption: String
    init(from photo: Photo) { self.id = photo.id; self.caption = photo.caption }
}
```

**Why separate:** coupling the model to `AppEntity` leaks internal structure into the system's contract, drags serialization/`Sendable` constraints onto your domain core, and forces every internal change through the OS-facing schema. The projection keeps the fence between "what we store" and "what the system may see."

**Rule:** Inbound foreign data → naturalize to a citizen. Outbound to the system → project a citizen. Both directions cross a translation boundary. Never expose the raw model on either side.

---

## Before Writing Code

1. **Does this logic describe what the object IS?** -> Put it ON the object
2. **Can AI understand capabilities from schema alone?** -> If no, logic is scattered
3. **Am I creating a file that "helps" domain objects?** -> STOP. Logic belongs on them.
4. **Is the first parameter a domain object?** -> That logic belongs ON it
5. **Would I need to import a utility to use this object?** -> Those should be getters/computed properties
6. **Is this foreign data entering the domain?** -> Naturalize it first. Then it's a citizen.
7. **Am I exposing this object to the OS/AI (App Intents, Siri, Spotlight)?** -> Project a separate citizen (`AppEntity`). Do NOT conform the domain model itself.

## The Litmus Test

Open the class file. Read only the definition.

> "Do I understand what this object can do?"

If you need other files to answer that, you failed. Pull it in.

## The OOD Compliance Test

Three questions:

1. **Self-Describing?** Does this object need external files to know its capabilities?
2. **Fenced?** Are safety constraints declared as data on the object, not in external infrastructure?
3. **Unified?** Does the same interface serve both human and AI interactions?

All three must be YES. Otherwise, pull the missing piece in.
