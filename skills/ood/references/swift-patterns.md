# OOD Swift Patterns

Code examples demonstrating OOD principles in Swift.

---

## Self-Describing Data

```swift
@Model final class Campaign {
    var name: String
    var spend: Decimal
    var conversions: Int

    /// Customer Acquisition Cost
    var cac: Decimal { spend / Decimal(conversions) }
}
```

The formula lives with the data. Not in a separate layer.

## No Utils, Helpers, Services

```swift
// FORBIDDEN
func calculateROI(for campaign: Campaign) -> Decimal { ... }

// REQUIRED
extension Campaign {
    var roi: Decimal { (revenue - spend) / spend }
}
```

## Classes Over Plain Objects

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

## Getters for Derived State

```swift
var isActive: Bool { status == .active && !isExpired }
var daysRemaining: Int { Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0 }
```

## Collections on Parent Objects

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

## Translation Boundaries

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
