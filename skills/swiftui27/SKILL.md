---
name: swiftui27
description: "SwiftUI iOS/macOS 27 delta reference (WWDC 2026) — Apple-authored references vendored from Xcode 27's exported agent skills, plus Cal SDK-verified extras. Use for any SwiftUI work targeting SDK 27. Use when a SwiftUI view using @State fails to compile with \"used before being initialized\", \"invalid redeclaration of synthesized property\", or \"extraneous argument label\" errors after an SDK update (@State became a macro in SDK 27 — the obvious fix of reordering init assignments is WRONG; consult references/state-macro.md first); when @ViewBuilder/@ContentBuilder code hits ambiguous overloads in overlay/background or type-check regressions; when adding drag-to-reorder to any container via reorderable()/reorderContainer; when working with AsyncImage caching or AsyncImage(request:); when adding swipe actions to rows outside List via swipeActionsContainer(); when controlling toolbar overflow (visibilityPriority, ToolbarOverflowMenu, toolbarMinimizeBehavior); when presenting alert/confirmationDialog from an optional item binding; when building or migrating document-based apps (ReadableDocument/WritableDocument, DocumentGroup); when using navigation transitions (.crossFade, AnyNavigationTransition), copy/cut/paste modifiers (copyable/cuttable/pasteDestination), tab bar minimize, or Liquid Glass background extension; or when resolving SDK 27.0 deprecation warnings."
metadata:
  author: Cal + Apple
  version: 2.0.0
  source: "Apple: Xcode 27 `xcrun agent skills export` (swiftui-whats-new-27, vendored 2026-06-10). Cal: iPhoneOS27.0.sdk SwiftUI.swiftinterface (Xcode-beta 27.0)."
---

# SwiftUI — iOS / macOS 27 Delta (WWDC 2026)

**Scope:** this is a **27-delta corrective**, not a SwiftUI tutorial. Axiom's `axiom-ios-ui` / `axiom-swiftui-26-ref` cover the iOS 26 baseline (Liquid Glass `glassEffect`, `@Animatable`, etc.) — use those for fundamentals. This skill is only what's new in 27.

**Authority:** everything under `references/` was written and published by Apple (exported from Xcode 27 via `xcrun agent skills export`). It is authoritative and unconditionally supersedes prior training *and* this file's inline notes on any conflict. Do not invent APIs or parameters not documented there. Before writing or modifying code that uses any new or changed SDK 27 SwiftUI API, read the relevant reference — several APIs have closely-named overloads with different closure signatures; picking from training memory fails to compile or misbehaves at runtime.

**Reality check on the press:** WWDC coverage hyped "hinge-state / foldable adaptive layout APIs." **There is no `hinge`/`fold`/`isFolded` symbol in SwiftUI or UIKit in the 27.0 SDK.** Treat foldable adaptivity as the existing size-class / `ViewThatFits` / `onGeometryChange` toolkit until a named API appears. 📰 = press-reported, 🍎 = Apple-authored reference, ✅ = Cal SDK-verified.

---

## Apple references (read before using these APIs) 🍎

- `references/state-macro.md` — **`@State` migrated from property wrapper to macro.** Views that compiled before may fail with "variable used before being initialized" (init assigns `@State` before other stored properties), "invalid redeclaration of synthesized property" (composed property wrappers), or "extraneous argument label" (memberwise-init delegation in extensions). **For any compile error in a view using `@State` after an SDK update, read this first.** The fix is NOT reordering init assignments — that compiles but produces wrong runtime behavior (the initial-value expression wins; the init assignment is ignored).
- `references/content-builder.md` — result builders unified under `@ContentBuilder`. Source-incompatible spots: ambiguous `ShapeStyle` overloads in `overlay`/`background`, ambiguous type references when a module shadows SwiftUI types, `TupleContent` vs `TupleView` mismatches, and a type-check performance regression in Swift Charts with deeply branching content.
- `references/reorderable.md` — drag-to-reorder for any container (List, stacks, grids, custom layouts) via `.reorderable()` on `ForEach` + `.reorderContainer(for:)`: implementing the `ReorderDifference` apply, sections and multiple collections, drag-and-drop integration (`dragContainer`/`dropDestination`, `draggable(containerItemID:)`), and combining items by dropping one onto another. iOS/macOS/watchOS/visionOS 27; tvOS unavailable. Prefer this over manual `onMove` index juggling on 27.
- `references/toolbar.md` — toolbar in constrained space: `visibilityPriority` (which items stay visible vs. overflow), `ToolbarOverflowMenu` (always-overflow items), `.topBarPinnedTrailing` (pinned item), `toolbarMinimizeBehavior` (minimize on scroll), `contentMarginsRemoved`, `ToolbarPlacement.statusBar`, and `ForEach`/`EmptyView` in toolbar builders. Availability varies per API — see the reference's table.
- `references/swipe-actions.md` — swipe actions on rows in any scrollable container (ScrollView + LazyVStack/LazyVGrid/stack), not just `List`: mark the container `swipeActionsContainer()`, keep `swipeActions(edge:allowsFullSwipe:content:)` on each row; plus the new `onPresentationChanged` overload. tvOS unavailable.
- `references/item-binding.md` — `confirmationDialog` and `alert` overloads taking `item: Binding<T?>` (the `sheet(item:)` shape): presents while non-nil, passes the unwrapped value to `actions`/`message`.
- `references/async-image.md` — `AsyncImage` now applies standard HTTP caching by default; `AsyncImage(request:)` takes a `URLRequest` for per-request cache policy; `asyncImageURLSession(_:)` supplies a custom session.
- `references/document-based-apps.md` — new `ReadableDocument`/`WritableDocument` document model (iOS/macOS/visionOS 27): read-only viewers (`DocumentGroup(viewer:makeReadableDocument:)`), direct file-URL access, background read/write via `DocumentReader`/`DocumentWriter`, `FileWrapperDocument{Reader,Writer}`, incremental package writes, `Subprogress`, undo. **When the deployment target is 27+, do not recommend `FileDocument`/`ReferenceFileDocument` for new code.**
- `references/deprecations.md` — APIs hard-deprecated in SDK 27.0 (e.g. `statusBarHidden` on visionOS: no effect, remove the call).

---

## Cal SDK-verified extras (not covered by Apple's references) ✅

### 1. Navigation transitions

iOS 26 had `.zoom`. 27 adds type-erasure and a cross-fade, so you can store/compose transitions:

```swift
.navigationTransition(.crossFade)                       // CrossFadeNavigationTransition
.navigationTransition(.zoom(sourceID: item.id, in: ns)) // still here from 26

// Type-erase to pick at runtime:
let t: AnyNavigationTransition = useZoom
    ? AnyNavigationTransition(.zoom(sourceID: item.id, in: ns))
    : AnyNavigationTransition(.crossFade)
detailView.navigationTransition(t)
```

`matchedTransitionSource(id:in:)` gained overloads for **toolbar content** — you can originate a zoom from a toolbar item. SDK constraints: matched-transition source only supports `RoundedRectangle` clip shapes and `Color` backgrounds (others are `@available(*, unavailable)`).

### 2. First-class copy / cut / paste

`Transferable`-based clipboard verbs as view modifiers (no responder-chain plumbing):

```swift
view
    .copyable([selectedItem])                          // T: Transferable
    .cuttable(for: Item.self) { removeAndReturn() }     // returns [T] to place on pasteboard
    .pasteDestination(for: Item.self) { items in
        model.insert(items)
    } validator: { $0.filter(\.isValid) }
// Command-driven variants: .onCopyCommand / .onCutCommand (NSItemProvider-based)
```

### 3. Drag session observation

Beyond Apple's reorder/drop coverage: `onDragSessionUpdated { (session: DragSession) in … }` observes an in-flight drag.

### 4. Tab bar minimize + Tabs picker

```swift
TabView { … }
    .tabBarMinimizeBehavior(.onScrollDown)   // .automatic / .onScrollDown / .onScrollUp / .never

// Render a Picker as the iOS 26+ floating tab strip:
Picker("View", selection: $mode) { … }
    .pickerStyle(.tabs)                      // TabsPickerStyle
```

`tabBarMinimizeBehavior` makes the floating (Liquid Glass) tab bar shrink while scrolling. (Toolbar/nav-bar minimize is `toolbarMinimizeBehavior` — see `references/toolbar.md`.)

### 5. Liquid Glass: background extension

The 27 glass addition (the `glassEffect` / `GlassEffectContainer` core shipped in 26 — see `cal:design`):

```swift
imageHeader
    .backgroundExtensionEffect()           // content bleeds under sidebars/insets behind glass
    .backgroundExtensionEffect(isEnabled: scrolledUnderNav)
```

Use for hero imagery and full-bleed backdrops that should appear *under* translucent chrome rather than clipped to the safe area. Broader 27 glass guidance lives in `cal:design`.

### 6. Background scenes

`BackgroundTask.processingTask(_:)` joins `BackgroundTask.appRefresh(_:)` as a `backgroundTask(_:action:)` scene-modifier identifier — long background work modeled at the scene level (mirrors App Intents' `LongRunningIntent`, see `os27`).

### 7. Performance (📰, no API)

Apple states iOS 27 SwiftUI is more responsive "without code changes" via faster state initialization and layout. No opt-in symbol — just build against the 27 SDK and test.

---

## OOD / Cal notes

- The reorder system is state-difference driven (`ReorderDifference`) — apply the difference to the object that owns the collection (a parent entity's computed/owned array), not a free `onMove` closure scattered in the view. Keeps Pillar-1 logic on the model.
- `Transferable` copy/cut/paste is the SwiftUI side of the outbound-citizen idea in `cal/OOD.md`: expose a `Transferable` projection, not the raw model.
- `ReadableDocument`/`WritableDocument` puts read/write logic ON the document type — the document model is the citizen; keep parsing out of views.

## Sourcing

- `references/*.md`: Apple-authored, exported from Xcode 27 via `xcrun agent skills export` (skill `swiftui-whats-new-27`), vendored 2026-06-10. Two example-code fixes deviate from upstream (caught by Codex on PR #16): `document-based-apps.md` used a nonexistent `fileWrapper:` init label for `NotebookSnapshot.previousFileWrapper`, and `item-binding.md`'s pre-27 fallback never set its `isPresented` flag (now derived from the item binding). Re-export on new Xcode 27 betas and re-check whether upstream fixed these.
- ✅ items: verified in `iPhoneOS27.0.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface` (Xcode-beta 27.0). Method and traps: see `os27` skill → "Sourcing." Re-grep a symbol's `@available` before relying on it; betas shift.
