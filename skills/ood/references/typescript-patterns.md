# OOD TypeScript Patterns

Code examples demonstrating OOD principles in TypeScript.

---

## Self-Describing Data

```typescript
class Campaign {
  readonly name: string;
  readonly spend: number;
  readonly conversions: number;

  /** Customer Acquisition Cost */
  get cac(): number { return this.spend / this.conversions; }
}
```

The formula lives with the data. Not in a separate layer.

## No Utils, Helpers, Services

```typescript
// FORBIDDEN
function calculateROI(campaign: Campaign): number { ... }

// REQUIRED
class Campaign {
  get roi(): number { return (this.revenue - this.spend) / this.spend; }
}
```

## Classes Over Plain Objects

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

## Getters for Derived State

```typescript
get isActive() { return this.status === 'active' && !this.isExpired }
get daysRemaining() { return differenceInDays(this.endDate, new Date()) }
```

## Collections on Parent Objects

```typescript
// FORBIDDEN
function getActiveCampaigns(campaigns: Campaign[]): Campaign[] { ... }

// REQUIRED
class Portfolio {
  get activeCampaigns(): Campaign[] { return this.campaigns.filter(c => c.isActive); }
  get totalSpend(): number { return this.campaigns.reduce((s, c) => s + c.spend, 0); }
}
```

## Hot Potato Pattern (Next.js)

Classes can't cross server/client boundary.

```
DB -> Server (DTO) -> Wire (JSON) -> Client (hydrate to class) -> Use rich object
```

DTOs are plain interfaces. Hydrate immediately on client.

## Translation Boundaries

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
