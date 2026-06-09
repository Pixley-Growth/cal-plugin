---
name: os27
description: "iOS/macOS/iPadOS 27 framework reference (WWDC 2026). Corrects stale model knowledge about App Intents, App Schemas, Foundation Models, and Siri AI. Invoke when building or reviewing iOS 27 / WWDC 2026 features, or when a model assumes iOS 26 / SiriKit is current."
metadata:
  author: Cal
  version: 1.0.0
  source_event: WWDC 2026 (June 8, 2026)
---

# iOS / macOS / iPadOS 27 — Framework Reference (WWDC 2026)

**Why this exists:** Most models' training predates WWDC 2026 (June 8, 2026). They assume iOS 26 is current, SiriKit is alive, and Foundation Models is on-device-only and text-only. All three are now wrong. This skill overrides those assumptions. The Axiom skills are excellent but their iOS-version content stops at WWDC 2025 (iOS 26) — when a question is about 27, prefer this skill over Axiom for the deltas below, and use Axiom for everything that carried over unchanged.

**Confidence legend** — every claim is tagged:
- ✅ **VERIFIED** — present in live Apple developer docs (sosumi.ai mirror, June 2026) **and** absent from the on-device iOS 26 baseline. The version-binning rule below makes this trustworthy.
- 📰 **REPORTED** — sourced from press coverage of the keynote, not yet confirmed against Apple docs. Treat as directionally true, verify exact API shape before shipping.

When unsure, say so and check current Apple docs. Do **not** assert iOS 27 details from training — training doesn't have them.

### Sourcing — the SDK is ground truth

The authoritative source for what's-in-27 is the **27.0 SDK's Swift interface files**, which carry exact `@available` annotations per symbol. On this machine:

```
/Applications/Xcode-beta.app   → Xcode 27.0, iPhoneOS27.0.sdk   ← use this
/Applications/Xcode.app        → Xcode 26.5 (xcode-select default)
```

Verify any symbol's introduction version directly:

```bash
SDK=/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk
IFACE="$SDK/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftmodule/arm64e-apple-ios.swiftinterface"
grep -nE "(protocol|struct|enum) SyncableEntity\b" "$IFACE"   # then read the @available above it
```

**Two traps learned the hard way:**

1. **The for-LLM guides are stale.** `…/IDEIntelligenceChat.framework/.../AdditionalDocumentation/AppIntents-Updates.md` in Xcode-beta 27.0 is **byte-identical to the 26.5 copy** and still cites WWDC 2025. Apple refreshes these late in the beta cycle. Use the `.swiftinterface`, not these guides.
2. **Point releases break naive year-binning.** iOS **26.4** shipped real APIs (`CancellableIntent`, `IntentValueRepresentation`). A "present in 27, absent from 26.0" heuristic mislabels them as 27. Only the per-symbol `@available` is reliable. Every ✅ in this skill was checked against the 27.0 `.swiftinterface`.

**sosumi.ai** (live `developer.apple.com` mirror) is a fine *second* source for prose/concepts, but its page-summarizer can mis-bin versions — never let it override the SDK.

---

## 1. Platform reality (read this first)

- 📰 **SiriKit is formally deprecated.** WWDC 2026 opened with the notice; ~2–3 year migration window. App Intents is now the **only** supported Siri integration surface.
- 📰 **Siri is rebuilt on Google Gemini models**, with private inference running on Apple-controlled Private Cloud Compute. The new Siri routes **exclusively through App Intents** — an app with no App Intents is invisible to it.
- 📰 **Most powerful on-device model tier requires iPhone 17 Pro / iPhone Air.** Older Apple-Intelligence devices still run the base on-device model.
- 📰 Shortcuts gained natural-language workflow creation. Foldable-iPhone groundwork (app resizability) landed in iOS 27.

**Cal takeaway:** for any iOS 27 app that wants to be reachable by Siri/Apple Intelligence, App Intents + App Schemas is no longer optional polish — it's the integration. Design it in, don't bolt it on.

---

## 2. App Schemas — the schema-domain system ✅

Instead of hand-rolling intents, you **conform your intents/entities/enums to system-defined schemas** so the system knows exactly what each one does. WWDC 2026 session 240, "Build intelligent Siri experiences with App Schemas."

**What's actually 27 here:** the schema mechanism itself is not new — assistant schemas shipped earlier (the older `BooksIntents`/`MailIntents`-style modules, ~iOS 18.4). What 27 changes is that schemas became the **center of gravity**: the catalog expanded, and (📰) with SiriKit deprecated and Siri routing exclusively through App Intents, conforming to these schemas is now how you're reachable by Siri at all. Treat the domain catalog below as current-as-of-WWDC26 but re-confirm exact schema identifiers in Xcode 27.

### The three schema macros

```swift
@AppIntent(schema: .photos.openAsset)
struct OpenPlantPhotoIntent: OpenIntent {
    var target: PlantPhotoEntity
    func perform() async throws -> some IntentResult { /* ... */ }
}

@AppEntity(schema: .photos.asset)
struct PlantPhotoEntity { /* ... */ }

@AppEnum(schema: .photos.assetType)
enum PhotoAssetType: String, Sendable { /* ... */ }
```

The schema *is* the contract. `.mail.createDraft` tells the system "this intent creates an email draft" — no extra wiring, no separate AI endpoint.

### Domain catalog (23 domains)

**Primary (13):** Audio · Calendar · Camera · Clock · Files · Mail · Maps · Messages · Notes · Phone · Photos · Reminders · System and in-app search

**Single-purpose (2):** Assistant · Visual intelligence

**Shortcuts-specific (8):** Books · Browser · Journaling · Presentation · Reader · Spreadsheet · Whiteboard · Word processor

### Conformance groups — all-or-nothing

Some domains require you to implement **every** schema in the group if you adopt any one of them. Confirmed group-conformance domains: **Mail, Clock, Messages.** Xcode validates completeness at build time. Type `<domain>_` (e.g. `messages_`) in the editor for template generation.

Example — the **Messages** domain (`.messages.*`):
- Intents: `draftMessage`, `sendMessage`, `editSentMessage`, `unsendMessage`, `setMessageReadStatus`
- Entities: `conversation`, `message`, `messagePerson`, `customAttachment`
- Enums: `conversationAttribute`, `messageAttribute`, `messageType`, `messageEffect`, `customReaction`

### Discovery & context APIs ✅

- **Spotlight semantic index** — conform entities to `IndexedEntity` (the only requirement), then `try await CSSearchableIndex(name:).indexAppEntities(_:)`. Implement `IndexedEntityQuery` for reindex requests (`reindexEntities(for:indexDescription:)`, `reindexAllEntities(_:)`).
- **Onscreen context** — tell Siri/Apple Intelligence what's on screen:
  - SwiftUI: `.appEntityIdentifier(_:)`, `.appEntityUIElements(_:)`, `.userActivity(_:element:_:)`
  - UIKit/AppKit: `appEntityIdentifier` / `appEntityUIElementProvider` properties; `NSUserActivity.appEntityIdentifier`
  - Protocols: `AppEntityAnnotatable`, `AppEntityUIElement`, `IntentValueRepresentation`
  - Table/collection views: `UITableViewAppIntentsDataSource` / `NSTableViewAppIntentsDataSource` / `…CollectionView…` make rows discoverable.
- **Donations** — `AppIntent.donate()`, `IntentDonationManager`, `PredictableIntent`, `RelevantIntentManager` (Watch Smart Stacks), `RelevantEntities.updateEntities(_:for:)`.

---

## 3. App Intents — new in 27

Every row below was confirmed `@available(iOS 27.0)` in `iPhoneOS27.0.sdk`'s `AppIntents.swiftinterface`. ✅ = SDK-verified.

| API | What it does | |
|-----|--------------|---|
| `SyncableEntity` | Stable cross-device entity identifiers | ✅ |
| `OwnershipProvidingEntity` + `EntityOwnership` | Declares an entity needs a **confirmation prompt** for sensitive actions (a Pillar-2 fence) | ✅ |
| `LongRunningIntent` + `performBackgroundTask(options:operation:)` + `LongRunningTaskOptions` | Extended background runtime | ✅ |
| `RunSystemShortcutIntent` | Run shortcuts / system actions from widgets | ✅ |
| `EntityCollection` | Efficient references to large entity sets | ✅ |
| `IndexedEntityQuery` | Spotlight retrieval / reindex by identifier | ✅ |
| `AppUnionValue` + `AppUnionValueCasesProviding` | Union-type parameters (evolution of 26's `@UnionValue`) | ✅ |
| `RelevantEntities` | Donate media-entity suggestions | ✅ |
| `IntentExecutionTargets` + `allowedExecutionTargets` | Constrain where an intent may run | ✅ |
| `IntentResponseStream` | Streamed intent responses | ✅ |

**NOT new in 27 — verified earlier release** (do not present these as 27 — `@available` proves otherwise):
- **iOS 26.0:** `supportedModes` + `IntentModes` (foreground/background control, replaced `openAppWhenRun`), `UndoableIntent`, `@ComputedProperty` / `@DeferredProperty`, `IndexedEntity`, `SnippetIntent`, `IntentValueQuery` (Visual Intelligence), `@UnionValue`, `AppIntentsPackage`, the Multiple Choice API (`requestChoice`).
- **iOS 26.4 (point release):** `CancellableIntent`, `IntentCancellationReason`, `IntentValueRepresentation`. ← these are the easiest to misattribute to 27; they are not.

---

## 4. Foundation Models — new in 27

All type names below confirmed `@available(iOS 27.0)` in `iPhoneOS27.0.sdk`'s `FoundationModels.swiftinterface`. ✅ = SDK-verified. The headline: Foundation Models is no longer an on-device-only, text-only, Apple-only box.

- ✅ **Pluggable providers** — `LanguageModel` protocol lets third parties expose a common inference surface. `LanguageModelExecutor` (`init(configuration:)`, prewarming, `LanguageModelExecutorGenerationChannel`) backs custom implementations. 📰 The practical promise (swap on-device ↔ PCC ↔ Gemini ↔ Claude via SPM with no session-code change) is press-reported; the protocol that enables it is in the SDK.
- ✅ **Multimodal (image input)** — `Attachment`, `ImageAttachmentContent`, `Transcript.ImageAttachment`, `Transcript.AttachmentSegment`. Accepts UIImage/NSImage/CGImage/CoreImage/CVPixelBuffer/file URLs.
- ✅ **Private Cloud Compute** — `PrivateCloudComputeLanguageModel`: server-side inference with quota management, availability + language checks.
- ✅ **Dynamic Profiles** — `LanguageModelSession.DynamicProfile`: runtime-adjustable behavior via `historyTransform`, `inputFilter`, and lifecycle hooks `onActivate` / `onDeactivate` / `onPrompt`. Plus `SessionProperty` for stateful config.
- ✅ **Reasoning controls** — `ContextOptions.ReasoningLevel` (`light` / `moderate` / `deep` / custom); `Transcript.Reasoning` entries.
- ✅ **Failure handling** — `TranscriptErrorHandlingPolicy` (`preserveTranscript` / `revertTranscript`).
- 📰 **Beyond Swift/Apple** — a Python SDK shipped, the utilities package was open-sourced, and the framework now runs on Linux. (Not visible in the iOS SDK — press-reported.)

**Still true from 26 (don't forget):** the base on-device model is small (3B, ~4096-token context), so `.exceededContextWindowSize` / `.guardrailViolation` handling, `@Generable` + constrained decoding, prewarming, and `includeSchemaInPrompt: false` all still matter. Use Axiom `axiom-foundation-models-ref` for those fundamentals.

---

## 5. The 27 framework landscape — App Intents & Foundation Models are the spine

The strongest signal of 27's direction is structural: Apple shipped a swarm of **cross-import overlay** frameworks (the `_X_Y` naming — they activate automatically when you `import` both modules) that wire App Intents and Foundation Models into the rest of the OS.

**App Intents wired into system frameworks** (import both → gain entities/conformances): `_AppIntents_HealthKit` (e.g. `WorkoutIntensityLevel`), `_Contacts_AppIntents`, `_FinanceKit_AppIntents`, `_MediaPlayer_AppIntents` (`MPAppEntityIdentifier`), `_NowPlaying_AppIntents`, `_UserNotifications_AppIntents`, `_SharedWithYou_AppIntents`.

**Foundation Models wired into:** `_FoundationModels_UIKit`, `_Vision_FoundationModels`, `_CoreSpotlight_FoundationModels`.

**SwiftUI wired into sensors:** `_CoreLocation_SwiftUI`, `_CoreMotion_SwiftUI` (bind location/motion into views).

**New standalone frameworks worth knowing:** `CoreAI`, `MediaIntelligence`, `MusicUnderstanding`, `SuggestedActions`, `SiriInferenceLearning`, `NowPlaying` (now its own framework), `MediaDevice`, `AVSystemRouting`, `AudioAccessoryKit`, `USDKit` + `ComputeGraph` (RealityKit), `ScreenCaptureKit` (now on iOS), `IdentityDocumentServices`, `EnhancedLinkSecurity`, `TrustInsights`.

**Takeaway:** "add App Intents to be reachable by Siri" now compounds — conforming to a system framework's intents (HealthKit workouts, MediaPlayer playback, notifications) plugs you into that domain's system surfaces for free.

---

## 6. App Intents × system frameworks ✅

The overlays are thin (entities, identifiers, conformances) — the pattern is that first-party domains now define their own App Intents vocabulary you adopt rather than invent:

```swift
import AppIntents
import HealthKit            // activates _AppIntents_HealthKit overlay

// System-defined entity/enum vocabulary (e.g. WorkoutIntensityLevel) is now available
// to your intents — conform to the relevant schema rather than modeling it yourself.
@AppIntent(schema: .health /* domain schema */)
struct LogWorkoutIntent: AppIntent { /* ... */ }
```

When targeting a domain (Health, Media, Contacts, Notifications), **check for an `_X_AppIntents` overlay first** — adopting the system's entities makes you interoperable with Siri/Shortcuts/Spotlight in that domain without bespoke modeling. (Verify exact members in the 27 SDK; overlays are sparse and evolving.)

---

## 7. On-device intelligence beyond the base LLM ✅

Foundation Models is the general LLM; 27 also ships **task-specific on-device intelligence** frameworks. These are not the LLM — they're dedicated analyzers.

**MediaIntelligence** — on-device face grouping + video understanding:
```swift
import MediaIntelligence

// Video: highlights & key frames
let analyzer = VideoAnalyzer()
let (highlights, keyframes) = try await analyzer.analyze(
    videoAsset,
    for: HighlightAnalysisRequest(), KeyFrameAnalysisRequest()
)   // returns a tuple of Result<…> per request

// Faces: group across a photo library
let faces = FaceGroupAnalyzer()
for try await (assetID, found) in try await faces.identifyFaces(in: imageAssets) { … }
// Persistent store: MIDataStore (fetchFaces(for:), fetchAssetIDs(for:), insertOrUpdateAssets…)
```

**Vision as Foundation Models tools** — `_Vision_FoundationModels` ships `OCRTool` and `BarcodeReaderTool` conforming to FM's `Tool` protocol, so the LLM can read text/barcodes from images during a session:
```swift
let session = LanguageModelSession(tools: [OCRTool(), BarcodeReaderTool()])
```

**CoreSpotlight + Foundation Models** — `_CoreSpotlight_FoundationModels` adds a semantic search pipeline (`ContentDomain`, `GuidanceProfile`, `ContactResolver`, `ScoredSearchableItem`) layering FM reasoning over the Spotlight semantic index.

**SuggestedActions** — `SuggestedActionsView` / `SuggestedActionsMessage` surface system-suggested actions (messaging-style) in your UI.

**CoreAI** — present in the SDK but exposes no Swift public interface (C/ObjC underpinning); not a direct API surface yet.

**Rule:** match the tool to the task — base LLM (`FoundationModels`) for language; `MediaIntelligence` for faces/video; Vision tools for OCR/barcode. Don't ask the 3B LLM to do vision work a dedicated analyzer does better.

---

## 8. Why Cal cares: App Intents *is* OOD, enforced by the OS

The 27 schema system is the strongest external validation of Cal's OOD doctrine to date. Mapping to the Three Pillars (see `cal/OOD.md` → "App Intents as OOD"):

- **Pillar 1 (Self-Describing Data):** `@AppEntity(schema:)` + `@Property(title:)` + `displayRepresentation`. The schema IS the API the model reads. "Add a field, AI gains a capability" — Apple's "Use Model" action literally serializes your entity's exposed properties to JSON for the model.
- **Pillar 2 (Behavioral Fences):** now first-class in 27 — `OwnershipProvidingEntity`/`EntityOwnership` (confirmation for sensitive actions), `UndoableIntent`, `authenticationPolicy`, `requestConfirmation`. Fences declared *as data on the object*, not external infra.
- **Pillar 3 (Unified Interfaces):** one `AppIntent` serves Siri, Shortcuts, Spotlight, widgets, and your own UI. One code path, human or AI.

**The one nuance that overrides naive OOD:** Apple says **don't** make your `@Model` conform to `AppEntity` — keep a separate entity that converts from the model. In OOD terms that's a **translation boundary running outbound**: the `AppEntity` is a curated *citizen projection* exposed to the system, the mirror image of naturalizing foreign data inbound. Here, "pull logic onto the object" is the wrong move; project a clean citizen instead.

---

## Sources

- Apple Developer docs (via sosumi.ai mirror, June 2026): App Schema Domains; Messages domain; Making actions & content discoverable by Apple Intelligence; Apple Intelligence and Siri AI; Providing contextual cues; Donating your app's data and actions; Making app entities available in Spotlight; App Intents framework Updates; Foundation Models framework.
- WWDC 2026 session 240, "Build intelligent Siri experiences with App Schemas."
- Press coverage (📰 items): MacRumors, Macworld, MacObserver WWDC 2026 recaps (June 8–9, 2026).

**Verify before shipping anything tagged 📰, and re-check `developer.apple.com` for exact API signatures — beta APIs move during the seed cycle.**
