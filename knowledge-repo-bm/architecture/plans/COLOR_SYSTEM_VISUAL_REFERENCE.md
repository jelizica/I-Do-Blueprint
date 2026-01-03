# Color System Visual Reference
**Date:** 2026-01-02
**Theme:** Blush Romance
**Purpose:** Quick visual reference for developers

---

## 🎨 Color Scales

### BlushPink (Primary)

```
shade50  #f9f5f7  ░░░░░░░░░░  Almost white with pink tint
shade100 #f6e9ee  ░░░░░░░░░░  Very light pink
shade200 #f1c6d7  ▒▒▒▒▒▒▒▒▒▒  Light pink for backgrounds
shade300 #ef99bb  ▒▒▒▒▒▒▒▒▒▒  Soft pink for borders
shade400 #ef619a  ▓▓▓▓▓▓▓▓▓▓  Medium-light pink
shade500 #ef2a78  ▓▓▓▓▓▓▓▓▓▓  Base color (vibrant) ⭐
shade600 #d5105e  ████████████  Darker pink for hover
shade700 #ab114e  ████████████  Rich pink for active (WCAG AA: 7.18:1) ✅
shade800 #7a103a  ████████████  Deep burgundy (WCAG AAA: 10.6:1) ✅
shade900 #580e2b  ████████████  Very dark burgundy
shade950 #340a1a  ████████████  Darkest (near black)
```

**Use For:** Primary CTAs, romantic features, celebration moments

---

### SageGreen (Secondary)

```
shade50  #f7f8f7  ░░░░░░░░░░  Almost white with green tint
shade100 #eff1ee  ░░░░░░░░░░  Very light sage
shade200 #d9e0d7  ▒▒▒▒▒▒▒▒▒▒  Light sage for backgrounds
shade300 #c1cebb  ▒▒▒▒▒▒▒▒▒▒  Soft sage for borders
shade400 #a2b899  ▓▓▓▓▓▓▓▓▓▓  Medium-light sage
shade500 #83a276  ▓▓▓▓▓▓▓▓▓▓  Base color ⭐
shade600 #6a895d  ████████████  Darker sage for hover
shade700 #576f4d  ████████████  Rich sage for active (WCAG AA: 5.54:1) ✅
shade800 #405139  ████████████  Deep forest green (WCAG AAA: 8.55:1) ✅
shade900 #303b2b  ████████████  Very dark green
shade950 #1d231a  ████████████  Darkest (near black)
```

**Use For:** Secondary actions, nature-related features, calming UI

---

### Terracotta (Accent Warm)

```
shade50  #f9f7f6  ░░░░░░░░░░  Almost white with warm tint
shade100 #f5edea  ░░░░░░░░░░  Very light terracotta
shade200 #edd3ca  ▒▒▒▒▒▒▒▒▒▒  Light terracotta for backgrounds
shade300 #e7b3a2  ▒▒▒▒▒▒▒▒▒▒  Soft terracotta for borders
shade400 #e18b6f  ▓▓▓▓▓▓▓▓▓▓  Medium-light terracotta
shade500 #db643d  ▓▓▓▓▓▓▓▓▓▓  Base color ⭐
shade600 #c24b24  ████████████  Darker terracotta for hover
shade700 #9c3f21  ████████████  Rich terracotta for active (WCAG AA: 6.67:1) ✅
shade800 #702f1a  ████████████  Deep rust (WCAG AAA: 9.95:1) ✅
shade900 #512415  ████████████  Very dark rust
shade950 #2f160e  ████████████  Darkest (near black)
```

**Use For:** Alerts, important CTAs, warm accents, autumn themes

---

### SoftLavender (Accent Elegant)

```
shade50  #f7f5f9  ░░░░░░░░░░  Almost white with lavender tint
shade100 #f0e9f7  ░░░░░░░░░░  Very light lavender
shade200 #dcc5f2  ▒▒▒▒▒▒▒▒▒▒  Light lavender for backgrounds
shade300 #c597f2  ▒▒▒▒▒▒▒▒▒▒  Soft lavender for borders
shade400 #aa5df3  ▓▓▓▓▓▓▓▓▓▓  Medium-light lavender
shade500 #8f24f5  ▓▓▓▓▓▓▓▓▓▓  Base color (vibrant) ⭐
shade600 #750adb  ████████████  Darker lavender for hover
shade700 #600db0  ████████████  Rich lavender for active (WCAG AA: 9.62:1) ✅
shade800 #460c7d  ████████████  Deep purple (WCAG AAA: 13.0:1) ✅
shade900 #340c5a  ████████████  Very dark purple
shade950 #1f0835  ████████████  Darkest (near black)
```

**Use For:** Premium features, creative tools, elegant accents

---

### WarmGray (Neutrals)

```
shade50  #f7f7f7  ░░░░░░░░░░  Off-white (warm undertone)
shade100 #f0f0ef  ░░░░░░░░░░  Very light gray
shade200 #dddbda  ▒▒▒▒▒▒▒▒▒▒  Light gray for backgrounds
shade300 #c7c4c2  ▒▒▒▒▒▒▒▒▒▒  Soft gray for borders
shade400 #ada8a4  ▓▓▓▓▓▓▓▓▓▓  Medium-light gray
shade500 #928b86  ▓▓▓▓▓▓▓▓▓▓  Base color ⭐
shade600 #79726d  ████████████  Darker gray for hover (WCAG AA: 4.72:1) ✅
shade700 #635e5a  ████████████  Rich gray for active (WCAG AA: 7.86:1) ✅
shade800 #484442  ████████████  Charcoal (WCAG AAA: 9.62:1) ✅
shade900 #353331  ████████████  Very dark charcoal
shade950 #201e1d  ████████████  Near black
```

**Use For:** Text, borders, backgrounds, neutral UI elements

---

## 🎯 Semantic Color Mappings

### Primary Actions

```swift
SemanticColors.primaryAction        = BlushPink.base       (#ef2a78)
SemanticColors.primaryActionHover   = BlushPink.hover      (#d5105e)
SemanticColors.primaryActionActive  = BlushPink.active     (#ab114e)
SemanticColors.primaryActionDisabled = BlushPink.disabled  (#ef99bb)
```

**Visual:**
```
Normal:   ▓▓▓▓▓▓▓▓▓▓  #ef2a78 (vibrant pink)
Hover:    ████████████  #d5105e (darker pink)
Active:   ████████████  #ab114e (rich pink)
Disabled: ▒▒▒▒▒▒▒▒▒▒  #ef99bb (soft pink)
```

---

### Secondary Actions

```swift
SemanticColors.secondaryAction      = SageGreen.base       (#83a276)
SemanticColors.secondaryActionHover = SageGreen.hover      (#6a895d)
SemanticColors.secondaryActionActive = SageGreen.active    (#576f4d)
```

**Visual:**
```
Normal:   ▓▓▓▓▓▓▓▓▓▓  #83a276 (soft sage)
Hover:    ████████████  #6a895d (darker sage)
Active:   ████████████  #576f4d (rich sage)
```

---

### Status Indicators (Color Blind Safe)

```swift
SemanticColors.statusSuccess  = SageGreen.shade700    (#576f4d) ✅
SemanticColors.statusPending  = SoftLavender.shade600 (#750adb) ⏳
SemanticColors.statusWarning  = Terracotta.shade700   (#9c3f21) ⚠️
SemanticColors.statusInfo     = BlushPink.shade600    (#d5105e) ℹ️
```

**Visual:**
```
Success:  ████████████  #576f4d (rich sage)     + ✅ icon
Pending:  ████████████  #750adb (dark lavender) + ⏳ icon
Warning:  ████████████  #9c3f21 (rich terracotta) + ⚠️ icon
Info:     ████████████  #d5105e (darker pink)   + ℹ️ icon
```

**CRITICAL:** Always pair status colors with icons for color blind accessibility!

---

### Text Colors

```swift
SemanticColors.textPrimary    = WarmGray.shade800  (#484442) WCAG AAA ✅
SemanticColors.textSecondary  = WarmGray.shade600  (#79726d) WCAG AA ✅
SemanticColors.textTertiary   = WarmGray.shade500  (#928b86)
SemanticColors.textDisabled   = WarmGray.shade400  (#ada8a4)
```

**Visual:**
```
Primary:   ████████████  #484442 (charcoal)      - Main body text
Secondary: ████████████  #79726d (dark gray)     - Supporting text
Tertiary:  ▓▓▓▓▓▓▓▓▓▓  #928b86 (medium gray)   - Subtle labels
Disabled:  ▒▒▒▒▒▒▒▒▒▒  #ada8a4 (light gray)    - Disabled text
```

---

### Backgrounds

```swift
SemanticColors.backgroundPrimary        = WarmGray.shade50        (#f7f7f7)
SemanticColors.backgroundSecondary      = WarmGray.shade100       (#f0f0ef)
SemanticColors.backgroundTintBlush      = BlushPink.shade50       (#f9f5f7)
SemanticColors.backgroundTintSage       = SageGreen.shade50       (#f7f8f7)
SemanticColors.backgroundTintTerracotta = Terracotta.shade50      (#f9f7f6)
SemanticColors.backgroundTintLavender   = SoftLavender.shade50    (#f7f5f9)
```

**Visual:**
```
Primary:    ░░░░░░░░░░  #f7f7f7 (off-white)
Secondary:  ░░░░░░░░░░  #f0f0ef (very light gray)
Tint Blush: ░░░░░░░░░░  #f9f5f7 (pink tint)
Tint Sage:  ░░░░░░░░░░  #f7f8f7 (green tint)
Tint Terra: ░░░░░░░░░░  #f9f7f6 (warm tint)
Tint Lav:   ░░░░░░░░░░  #f7f5f9 (lavender tint)
```

---

## 🚀 Quick Actions

```swift
QuickActions.task  = Terracotta.shade600   (#c24b24) 🔥 Warm, energetic
QuickActions.note  = SoftLavender.shade600 (#750adb) 💜 Creative, thoughtful
QuickActions.event = SageGreen.shade600    (#6a895d) 🌿 Calm, organized
QuickActions.guest = BlushPink.shade600    (#d5105e) 💗 Personal, warm
```

**Visual:**
```
Task:  ████████████  #c24b24 (terracotta)
Note:  ████████████  #750adb (lavender)
Event: ████████████  #6a895d (sage)
Guest: ████████████  #d5105e (blush)
```

---

## 💰 Budget Category Colors

```swift
BudgetCategoryColors.venue       = BlushPink.shade700     (#ab114e) 💒 Romance
BudgetCategoryColors.catering    = SageGreen.shade700     (#576f4d) 🍽️ Fresh, natural
BudgetCategoryColors.photography = SoftLavender.shade700  (#600db0) 📸 Creative
BudgetCategoryColors.florals     = SageGreen.shade500     (#83a276) 🌸 Nature
BudgetCategoryColors.music       = SoftLavender.shade500  (#8f24f5) 🎵 Entertainment
BudgetCategoryColors.attire      = BlushPink.shade500     (#ef2a78) 👗 Personal
BudgetCategoryColors.decor       = Terracotta.shade500    (#db643d) 🎨 Warmth
BudgetCategoryColors.other       = WarmGray.shade500      (#928b86) 📦 Neutral
```

**Visual:**
```
Venue:       ████████████  #ab114e (rich pink)
Catering:    ████████████  #576f4d (rich sage)
Photography: ████████████  #600db0 (rich lavender)
Florals:     ▓▓▓▓▓▓▓▓▓▓  #83a276 (soft sage)
Music:       ▓▓▓▓▓▓▓▓▓▓  #8f24f5 (vibrant lavender)
Attire:      ▓▓▓▓▓▓▓▓▓▓  #ef2a78 (vibrant pink)
Decor:       ▓▓▓▓▓▓▓▓▓▓  #db643d (terracotta)
Other:       ▓▓▓▓▓▓▓▓▓▓  #928b86 (medium gray)
```

---

## 🎭 Visual Planning

```swift
VisualPlanning.lavender  = SoftLavender.shade200  (#dcc5f2) Soft pastel
VisualPlanning.peach     = Terracotta.shade200    (#edd3ca) Soft pastel
VisualPlanning.mint      = SageGreen.shade200     (#d9e0d7) Soft pastel
VisualPlanning.rose      = BlushPink.shade200     (#f1c6d7) Soft pastel
VisualPlanning.teal      = #99F6E4               Complementary
VisualPlanning.vipBorder = Terracotta.shade600    (#c24b24) Warm accent
```

**Visual:**
```
Lavender: ▒▒▒▒▒▒▒▒▒▒  #dcc5f2 (light lavender)
Peach:    ▒▒▒▒▒▒▒▒▒▒  #edd3ca (light terracotta)
Mint:     ▒▒▒▒▒▒▒▒▒▒  #d9e0d7 (light sage)
Rose:     ▒▒▒▒▒▒▒▒▒▒  #f1c6d7 (light pink)
Teal:     ▒▒▒▒▒▒▒▒▒▒  #99F6E4 (bright teal)
VIP:      ████████████  #c24b24 (terracotta border)
```

---

## 🔍 Opacity Scale

```swift
Opacity.verySubtle  = 0.05   // Barely visible tints
Opacity.subtle      = 0.1    // Hover backgrounds
Opacity.light       = 0.15   // Status backgrounds
Opacity.medium      = 0.5    // Borders, dividers
Opacity.strong      = 0.95   // Tertiary text
```

**Visual Examples:**

```
verySubtle (0.05):  ░░░░░░░░░░  Barely visible
subtle (0.1):       ░░░░░░░░░░  Hover backgrounds
light (0.15):       ▒▒▒▒▒▒▒▒▒▒  Status backgrounds
medium (0.5):       ▓▓▓▓▓▓��▓▓▓  Borders, dividers
strong (0.95):      ████████████  Tertiary text
```

---

## 📏 Usage Rules

### Text on Light Backgrounds

```
✅ WCAG AAA (7:1+):
   - BlushPink.shade700   (7.18:1)
   - BlushPink.shade800   (10.6:1)
   - SageGreen.shade800   (8.55:1)
   - Terracotta.shade800  (9.95:1)
   - SoftLavender.shade700 (9.62:1)
   - SoftLavender.shade800 (13.0:1)
   - WarmGray.shade800    (9.62:1)

✅ WCAG AA (4.5:1+):
   - SageGreen.shade700   (5.54:1)
   - Terracotta.shade700  (6.67:1)
   - WarmGray.shade600    (4.72:1)

❌ Avoid for body text:
   - Any shade500 or lighter
   - Any shade600 (except for large text)
```

### Button States

```
Normal:   shade600 (base)
Hover:    shade700 (hover)
Active:   shade800 (active)
Disabled: shade300 (disabled)
```

### Backgrounds

```
Subtle:   shade50  (almost white)
Light:    shade100 (very light)
Borders:  shade200 (light)
```

---

## 🎨 Code Examples

### Primary Button

```swift
Button("Save Changes") {
    // action
}
.foregroundColor(SemanticColors.textOnPrimary)
.background(SemanticColors.primaryAction)
.onHover { hovering in
    hovering ? SemanticColors.primaryActionHover : SemanticColors.primaryAction
}
```

**Visual:**
```
Normal:   ▓▓▓▓▓▓▓▓▓▓  #ef2a78 (vibrant pink)
Hover:    ████████████  #d5105e (darker pink)
```

---

### Status Indicator (Color Blind Safe)

```swift
HStack(spacing: 4) {
    Image(systemName: "checkmark.circle.fill")
        .foregroundColor(SemanticColors.statusSuccess)
    Text("Confirmed")
        .foregroundColor(SemanticColors.statusSuccess)
}
```

**Visual:**
```
✅ ████████████  #576f4d (rich sage) + icon
```

---

### Quick Action Button

```swift
QuickActionButton(
    title: "Create Task",
    icon: "plus",
    backgroundColor: QuickActions.task
) {
    showingTaskModal = true
}
```

**Visual:**
```
████████████  #c24b24 (terracotta)
```

---

### Tinted Background

```swift
VStack {
    // content
}
.background(SemanticColors.backgroundTintBlush)
```

**Visual:**
```
░░░░░░░░░░  #f9f5f7 (pink tint)
```

---

### Opacity Usage

```swift
.background(AppColors.primary.opacity(Opacity.light))
.shadow(color: .black.opacity(Opacity.verySubtle), radius: 8)
.foregroundColor(AppColors.textTertiary.opacity(Opacity.medium))
```

**Visual:**
```
Light (0.15):      ▒▒▒▒▒▒▒▒▒▒  Background
VerySubtle (0.05): ░░░░░░░░░░  Shadow
Medium (0.5):      ▓▓▓▓▓▓▓▓▓▓  Text
```

---

## 🚨 Common Mistakes

### ❌ DON'T: Use raw shade values

```swift
// ❌ WRONG
.foregroundColor(BlushPink.shade600)
.background(BlushPink.shade600.opacity(0.15))
```

### ✅ DO: Use semantic colors

```swift
// ✅ CORRECT
.foregroundColor(SemanticColors.primaryAction)
.background(SemanticColors.backgroundTintBlush)
```

---

### ❌ DON'T: Hardcode opacity

```swift
// ❌ WRONG
.opacity(0.15)
.opacity(0.1)
.opacity(0.5)
```

### ✅ DO: Use Opacity enum

```swift
// ✅ CORRECT
.opacity(Opacity.light)
.opacity(Opacity.subtle)
.opacity(Opacity.medium)
```

---

### ❌ DON'T: Color-only status

```swift
// ❌ WRONG (Color blind unsafe)
Text("Confirmed")
    .foregroundColor(SemanticColors.statusSuccess)
```

### ✅ DO: Color + Icon

```swift
// ✅ CORRECT (Color blind safe)
HStack {
    Image(systemName: "checkmark.circle.fill")
    Text("Confirmed")
        .foregroundColor(SemanticColors.statusSuccess)
}
```

---

## 📚 Quick Reference

### Most Common Colors

```swift
// Primary Actions
SemanticColors.primaryAction        // #ef2a78 (vibrant pink)
SemanticColors.primaryActionHover   // #d5105e (darker pink)

// Status
SemanticColors.statusSuccess        // #576f4d (rich sage) + ✅
SemanticColors.statusWarning        // #9c3f21 (rich terracotta) + ⚠️
SemanticColors.statusPending        // #750adb (dark lavender) + ⏳

// Text
SemanticColors.textPrimary          // #484442 (charcoal)
SemanticColors.textSecondary        // #79726d (dark gray)

// Backgrounds
SemanticColors.backgroundPrimary    // #f7f7f7 (off-white)
SemanticColors.backgroundTintBlush  // #f9f5f7 (pink tint)

// Quick Actions
QuickActions.task                   // #c24b24 (terracotta)
QuickActions.note                   // #750adb (lavender)
QuickActions.event                  // #6a895d (sage)
QuickActions.guest                  // #d5105e (blush)

// Opacity
Opacity.verySubtle                  // 0.05
Opacity.subtle                      // 0.1
Opacity.light                       // 0.15
Opacity.medium                      // 0.5
```

---

**Last Updated:** 2026-01-02
**For More Info:** See `docs/COLOR_MIGRATION_QUICK_START.md`
