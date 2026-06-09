---
name: swiftui27
description: "SwiftUI iOS/macOS 27 delta reference (WWDC 2026). SDK-verified new APIs layered on top of Axiom's iOS 26 SwiftUI skills — navigation transitions, drag/reorder overhaul, copy-cut-paste, toolbar overflow, tab bar minimize, document model, Liquid Glass background extension. Invoke for SwiftUI work targeting iOS 27."
metadata:
  author: Cal
  version: 1.0.0
  source: iPhoneOS27.0.sdk SwiftUI.swiftinterface (Xcode-beta 27.0)
---

# SwiftUI — iOS / macOS 27 Delta (WWDC 2026)

**Scope:** this is a **27-delta corrective**, not a SwiftUI tutorial. Axiom's `axiom-ios-ui` / `axiom-swiftui-26-ref` cover the iOS 26 baseline (Liquid Glass `glassEffect`, `@Animatable`, etc.) — use those for fundamentals. This skill is *only* what's new in 27, verified symbol-by-symbol against `iPhoneOS27.0.sdk`'s `SwiftUI.swiftinterface`.

**Reality check on the press:** WWDC coverage hyped "hinge-state / foldable adaptive layout APIs." **There is no `hinge`/`fold`/`isFolded` symbol in SwiftUI or UIKit in the 27.0 SDK** (only CoreData and RoomPlan contain the substring "fold"). Treat foldable adaptivity as the existing size-class / `ViewThatFits` / `onGeometryChange` toolkit until a named API appears. Don't write code against an imagined `hingeState` environment value. 📰 = press-reported, ✅ = SDK-verified.

---

## 1. Navigation transitions ✅

iOS 26 had `.zoom`. 27 adds type-erasure and a cross-fade, so you can store/compose transitions:

```swift
// New: AnyNavigationTransition wraps any transition; .crossFade is new.
.navigationTransition(.crossFade)                       // CrossFadeNavigationTransition
.navigationTransition(.zoom(sourceID: item.id, in: ns)) // still here from 26

// Type-erase to pick at runtime:
let t: AnyNavigationTransition = useZoom
    ? AnyNavigationTransition(.zoom(sourceID: item.id, in: ns))
    : AnyNavigationTransition(.crossFade)
detailView.navigationTransition(t)
```

`matchedTransitionSource(id:in:)` gained overloads for **toolbar content** (`ToolbarContent` / `CustomizableToolbarContent`) — you can now originate a zoom from a toolbar item. Note the SDK constraints: matched-transition source only supports `RoundedRectangle` clip shapes and `Color` backgrounds (both are `@available(*, unavailable)` otherwise — the compiler will tell you).

---

## 2. Drag & reorder overhaul ✅

The biggest single area of new surface in 27. A declarative reordering system replaces hand-rolled `onMove` for many cases.

```swift
// Mark a ForEach's dynamic content reorderable:
ForEach(items) { item in RowView(item) }
    .reorderable()                              // simplest form
    .reorderable(collectionID: listID)          // when multiple collections interleave

// Own the reorder semantics with a typed difference:
List { ForEach(items) { RowView($0) } }
    .reorderContainer(for: Item.self, in: ListID.self) { difference in
        // difference: ReorderDifference<Item.ID, ListID>
        model.apply(difference)
    }
```

Drag/drop also gained:
- `draggable(containerItemID:containerNamespace:)` — drag a whole container by id.
- `onDragSessionUpdated { (session: DragSession) in … }` — observe an in-flight drag.
- `reorderDestination(for:in:)` / `reorderContainer(for:itemID:in:isEnabled:move:)` overloads for KeyPath-identified items and single-collection cases (`ReorderableSingleCollectionIdentifier`).

Prefer `reorderable()` / `reorderContainer` over manual `onMove` index juggling on iOS 27.

---

## 3. First-class copy / cut / paste ✅

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

---

## 4. Toolbar: overflow + visibility priority ✅

```swift
.toolbar {
    ToolbarItem { SaveButton() }
        .visibilityPriority(.high)        // kept when space is tight
    ToolbarItem { InfoButton() }
        .visibilityPriority(.low)         // first to collapse into overflow
}
```

`ToolbarItemVisibilityPriority` is `Comparable` with `.automatic` / `.low` / `.high`, plus `init(lowerThan:)` / `init(higherThan:)` for custom ordering. Items that don't fit collapse into a new `ToolbarOverflowMenu` (also constructible directly via `toolbarOverflowMenu { … }`). This is how the Liquid Glass toolbar degrades gracefully on narrow widths.

---

## 5. Tab bar minimize + Tabs picker ✅

```swift
TabView { … }
    .tabBarMinimizeBehavior(.onScrollDown)   // .automatic / .onScrollDown / .onScrollUp / .never

// Render a Picker as the iOS 26+ floating tab strip:
Picker("View", selection: $mode) { … }
    .pickerStyle(.tabs)                      // TabsPickerStyle
```

`tabBarMinimizeBehavior` makes the floating (Liquid Glass) tab bar shrink to reclaim space while scrolling — pair with content that benefits from vertical room.

---

## 6. Liquid Glass: background extension ✅

The 27 glass addition (the `glassEffect` / `GlassEffectContainer` core shipped in 26 — see `cal:design`):

```swift
imageHeader
    .backgroundExtensionEffect()           // content bleeds under sidebars/insets behind glass
    .backgroundExtensionEffect(isEnabled: scrolledUnderNav)
```

Use it for hero imagery and full-bleed backdrops that should appear *under* translucent chrome rather than being clipped to the safe area. The broader 27 glass guidance (refinements Apple says to adopt, the user transparency setting) lives in `cal:design`.

---

## 7. Document model + background scenes ✅

- New document plumbing: `WritableDocument`, `DocumentReader` / `DocumentWriter`, `FileWrapperDocumentReader/Writer`, `DocumentCreationContext`, `DocumentReadConfiguration` / `DocumentWriteConfiguration`, `NewDocumentButtonDataSource`, and a `fileExporter(isPresented:document:contentType:defaultFilename:onCompletion:onCancellation:)` overload. Relevant if you ship a `DocumentGroup` app.
- `BackgroundTask.processingTask(_:)` joins `BackgroundTask.appRefresh(_:)` as a `backgroundTask(_:action:)` scene modifier identifier — long background work modeled at the scene level (mirrors App Intents' `LongRunningIntent`, see `os27`).

---

## 8. Performance (📰, no API)

Apple states iOS 27 SwiftUI is more responsive "without code changes" via faster state initialization and layout. There's no opt-in symbol — just build against the 27 SDK. No action required beyond testing.

---

## OOD / Cal notes

- The reorder/drag system is state-difference driven (`ReorderDifference`) — apply the difference to the object that owns the collection (a parent entity's computed/owned array), not a free `onMove` closure scattered in the view. Keeps Pillar-1 logic on the model.
- `Transferable` copy/cut/paste is the SwiftUI side of the same outbound-citizen idea in `cal/OOD.md`: expose a `Transferable` projection, not the raw model.

## Sourcing

Every ✅ verified in `iPhoneOS27.0.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface` (Xcode-beta 27.0). Method and traps: see `os27` skill → "Sourcing." Re-grep a symbol's `@available` before relying on it; betas shift.
