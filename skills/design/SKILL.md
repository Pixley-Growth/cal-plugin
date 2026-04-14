---
name: design
description: "Apple Liquid Glass (iOS 26) design system reference. Invoke when building UI, reviewing visual design, or implementing glass effects, typography, spacing, animations, or accessibility."
---

# Design System: Apple Liquid Glass (iOS 26)

Research compiled from WWDC 2025, Apple Human Interface Guidelines, and developer community analysis.

---

## 1. Core Visual Principles

### Three Pillars (Apple HIG)

1. **Hierarchy** - "Establish a clear visual hierarchy where controls and interface elements elevate and distinguish the content beneath them."
   - Importance communicated through transparency, refraction, and visual weight
   - Content remains primary; navigation floats above

2. **Harmony** - "Align with the concentric design of the hardware and software to create harmony between interface elements, system experiences, and devices."
   - Corners share the same center (concentric)
   - Elements relate to device hardware curves

3. **Consistency** - "Adopt platform conventions to maintain a consistent design that continuously adapts across window sizes and displays."
   - Dynamic adaptation to context, lighting, content

### Layer Architecture

| Layer | Purpose | Treatment |
|-------|---------|-----------|
| Background | Content (wallpapers, media) | No glass |
| Glass | Panels, modals, cards | Semi-transparent, blur |
| Solid | Critical text, icons, CTAs | Always readable |
| Dynamic | Floating overlays | Context-responsive |

---

## 2. Glass Morphism Implementation

### Render Pipeline (How Apple Does It)

1. **Downsample & Blur** - Gaussian blur at lower resolution (GPU efficient)
2. **Saturate** - Pump saturation 10-20% in HSL/OKLCH color space
3. **Vibrancy** - Adaptive contrast: text samples background luminance and locally adjusts

### CSS Implementation

```css
/* Light Mode Glass */
.glass {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 22%;  /* Squircle approximation */
  box-shadow:
    0 8px 32px rgba(31, 38, 135, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.5),
    inset 0 4px 20px rgba(255, 255, 255, 0.3);
}

/* Dark Mode Glass */
.glass-dark {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.1);
}
```

### Blur Values Reference

| Context | Blur | Saturation | Background Alpha |
|---------|------|------------|------------------|
| Default Glass | 15-20px | 180% | 0.15-0.20 |
| Subtle/Clear | 4-8px | 120% | 0.10-0.15 |
| Heavy Glass | 32px | 150% | 0.25-0.40 |
| Text Backing | 2-4px | 100% | 0.70-0.90 |

### Noise Texture (Optional)

Add 2-3% opacity monochromatic noise layer for tactile feel (dithering effect).

### Critical Pitfalls

1. **Never use `opacity` property** - breaks backdrop-filter. Use `rgba()` values.
2. **Always include `-webkit-backdrop-filter`** - Safari compatibility.
3. **Add text shadows or backing** - glass can obscure text.

---

## 3. Opacity Guidelines

| Opacity | Use Case |
|---------|----------|
| 100% | Primary text, main CTAs, logos |
| 70% | Secondary text, navigation tabs, secondary buttons |
| 40% | Decorative dividers, outlines, icons |
| 20% | Subtle tints, background overlays, atmospheric effects |
| 4-8% | Glass base transparency plate |

### Glass Variants (SwiftUI Reference)

- `.regular` - Medium transparency, full adaptivity (default)
- `.clear` - High transparency for media-rich backgrounds
- `.identity` - No effect (conditional disable)

---

## 4. Typography (SF Pro)

### Font Families

| Variant | Use Case | Weights |
|---------|----------|---------|
| SF Pro Display | Headlines 20pt+ | Ultralight to Black (9 weights) |
| SF Pro Text | Body 19pt and below | Ultralight to Black (9 weights) |
| SF Pro Rounded | Friendly contexts | Ultralight to Black (no italics) |

### iOS Text Styles

| Style | Size | Weight | Use Case |
|-------|------|--------|----------|
| Large Title | 34pt | Medium | Screen headers (before scroll) |
| Title 1 | 28pt | Regular | Section headers |
| Title 2 | 22pt | Regular | Card titles |
| Title 3 | 20pt | Regular | Subsections |
| Headline | 17pt | Semibold | Emphasizing body text |
| Body | 17pt | Regular | Default content |
| Callout | 16pt | Regular | Secondary content |
| Subhead | 15pt | Regular | Supporting labels |
| Footnote | 13pt | Regular | Tertiary/caption text |
| Caption 1 | 12pt | Regular | Timestamps, metadata |
| Caption 2 | 11pt | Regular | Fine print |
| Tab Bar | 10pt | Medium | Tab labels (iPhone) |

### Letter Spacing

SF Pro has built-in optical sizing. General guidance:
- **Headlines**: Slightly tighter (-0.5 to -1.0)
- **Body**: Default (0)
- **Small text**: Slightly looser (+0.2 to +0.5)

### Line Height

- Body text: ~130% of font size (22pt line-height for 17pt text)
- Headlines: ~115% of font size
- Add 2pt for loose, subtract 2pt for tight

---

## 5. Spacing & Layout

### Grid System

- **Base unit**: 8px
- **Touch targets**: 44pt minimum (Apple standard)
- **Padding minimums**: 16px for interactive elements

### Common Spacing Values

| Token | Value | Use |
|-------|-------|-----|
| xs | 4px | Tight inline spacing |
| sm | 8px | Icon-text gaps |
| md | 16px | Card padding |
| lg | 24px | Section spacing |
| xl | 32px | Major section breaks |
| 2xl | 48px | Page margins |

### iOS 26 Floating Elements

Tab bars and toolbars float with inset from edges. Typical implementation:
- Capsule shape
- Inset from screen edges (~16-20px)
- Scroll-responsive: shrink/expand on scroll

### Concentric Corners

When nesting rounded elements, inner corners should be concentric (share same center as outer corners). Formula: `innerRadius = outerRadius - padding`

---

## 6. Squircle Corners (Continuous Curvature)

### Why Not `border-radius`?

Regular border-radius creates circular arcs with abrupt curvature changes (curvature jumps from 0 to 1/r). Apple's squircle has **continuous curvature** for smoother visual transitions.

### The Math

Apple uses a **quintic superellipse** (n=5), not a true squircle (n=4):

```
|x|^n + |y|^n = r^n, where n = 5
```

However, actual iOS implementation uses **3 cubic Bezier curves** per corner for efficiency.

### Bezier Control Points

Key constants (normalized to corner radius `r`):

| Constant | Value | Purpose |
|----------|-------|---------|
| Edge point | 1.528665r | Where curve meets straight edge |
| Control 1 | 1.08849296r | First bezier handle |
| Control 2 | 0.86840694r | Second bezier handle |
| Near-corner | 0.07491139r | Point closest to corner |

Formula for corner radius: `r = (p * l) / 200` where p = percentage, l = side length

### CSS Approximation

```css
/* Quick approximation - not perfect but acceptable */
.squircle {
  border-radius: 22%;  /* Scales with element size */
}

/* Better approximation for fixed sizes */
.squircle-fixed {
  border-radius: 37.5% / 37.5%;
}
```

### True Squircle (SVG Clip Path)

For pixel-perfect implementation, use SVG path or canvas with the Bezier constants above.

### iOS API

```swift
// iOS 13+: Use continuous corner curve
layer.cornerCurve = .continuous
layer.cornerRadius = 16

// iOS 26+: Concentric automatic nesting
ConcentricRectangle()  // New SwiftUI shape
.rect(cornerRadius: .containerConcentric)
```

---

## 7. Motion & Animation

### Core Principles

- **Physics-based**: Spring animations, not linear easing
- **Responsive**: React to gesture velocity
- **Interruptible**: Can be interrupted mid-animation
- **Subtle scale**: 0.98 on press for tactile feedback

### Spring Animation Values

```typescript
// Framer Motion / React Native
const spring = {
  type: "spring",
  stiffness: 400,
  damping: 30,
  mass: 1
};

// Bouncy variant
const bouncy = {
  type: "spring",
  stiffness: 300,
  damping: 20
};

// SwiftUI equivalent
withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { }
```

### Liquid Glass Behaviors

| Behavior | Description |
|----------|-------------|
| Lensing | Background bends through glass in real-time |
| Specular highlights | Move with device motion |
| Materialization | Elements appear by modulating light bending |
| Morphing | Dynamic transformation between states |
| Flexing | Gel-like response to touch |

### Scroll Behaviors

- **Tab bars**: Shrink to active-only on scroll down, expand on scroll up
- **Toolbars**: Compact mode when scrolling, full mode when idle
- **Focus shift**: Glass recedes when window loses focus

### Implementation

```typescript
// Tap feedback
const tapScale = {
  whileTap: { scale: 0.98 },
  transition: { type: "spring", stiffness: 400, damping: 30 }
};

// Hover glow (desktop)
const hoverGlow = {
  whileHover: {
    boxShadow: "0 0 20px rgba(100, 200, 255, 0.3)"
  }
};
```

---

## 8. Color System

### Adaptive Philosophy

- Sample wallpaper/background for contextual adaptation
- Maintain 4.5:1 contrast ratio (WCAG) minimum
- Use semantic colors, not hard-coded values

### Vibrancy

Not simple transparency - vibrancy samples background luminance:
- **Dark backgrounds**: Standard light pixels
- **Light backgrounds**: Locally darkens/tints glass behind text

### Tinting

```swift
// SwiftUI
.glassEffect(.regular.tint(.blue))
.glassEffect(.regular.tint(.purple.opacity(0.6)))
```

### Recommended Palette Approach

- Use system semantic colors when possible
- Cyan/teal accent (iOS 26 signature)
- Alpha transparency over solid colors
- Vibrant but not neon

### Dark Mode Adaptation

Materials auto-adjust tint and vibrancy. Glass base becomes darker with adjusted opacity.

---

## 9. Accessibility

### Required Adaptations

- **Reduce Transparency**: Makes translucent elements more opaque
- **Increase Contrast**: Reinforces edges, enhances text/icon visibility
- **Reduce Motion**: Disables spring physics, uses simple transitions

### Contrast Requirements

| Content Type | Minimum Ratio |
|--------------|---------------|
| Normal text | 4.5:1 |
| Large text (18pt+ or 14pt bold) | 3:1 |
| UI components | 3:1 |

### SwiftUI Automatic Handling

Glass effects respect `accessibilityReduceTransparency` and `accessibilityReduceMotion` environment values automatically.

---

## 10. App Icons (iOS 26)

### Canvas & Dimensions

- **Master size**: 1024 x 1024 px PNG
- **Fully opaque**: No transparency
- **No fake borders/bevels**: System adds highlights automatically

### Multi-Layer Structure

Icons combine:
1. **Background layer**: Base color/gradient
2. **Mid-ground layer**: Depth elements
3. **Foreground layer**: Primary symbol

### Clear Mode

New "Clear" theme uses transparent glass-like icons with dynamic reflections.

### Grid Alignment

Icons locked to invisible grid. Use Apple Design Resources templates for proper alignment.

---

## 11. Quick Reference

### The Liquid Glass Test

Before shipping UI, verify:

1. Would this look native on iOS 26?
2. Is glass effect subtle, not overwhelming?
3. Do corners feel smooth (continuous curvature)?
4. Does motion feel physical (spring-based)?
5. Is text readable on all backgrounds (4.5:1 contrast)?
6. Do nested corners align concentrically?

### Don'ts

- Don't apply glass to content (lists, media, text blocks)
- Don't use opacity property on glass elements
- Don't fake bevels or borders manually
- Don't use linear easing for transitions
- Don't ignore accessibility settings

---

## Sources

- [Apple Newsroom: Delightful and Elegant New Software Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [Apple Human Interface Guidelines: Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Apple Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Apple Developer Documentation: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [WWDC25: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [The Engineering Behind Apple's Liquid Glass UI](https://medium.com/@manavkaushal756/engineering-behind-apple-liquid-glass-ui-fb51b1d599ad)
- [My Quest for the Apple Icon Shape](https://liamrosenfeld.com/posts/apple_icon_quest/)
- [Desperately Seeking Squircles (Figma)](https://www.figma.com/blog/desperately-seeking-squircles/)
- [iOS Font Size Guidelines](https://www.learnui.design/blog/ios-font-size-guidelines.html)
- [GitHub: LiquidGlassReference](https://github.com/conorluddy/LiquidGlassReference)
- [GitHub: LiquidGlassCheatsheet](https://github.com/GonzaloFuentes28/LiquidGlassCheatsheet)
- [Liquid Glass: Redefining Design through Hierarchy, Harmony and Consistency](https://www.createwithswift.com/liquid-glass-redefining-design-through-hierarchy-harmony-and-consistency/)
