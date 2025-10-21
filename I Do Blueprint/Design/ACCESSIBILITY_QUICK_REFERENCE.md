# Accessibility Quick Reference Guide
## Color Usage & Best Practices

**For:** Developers working on I Do Blueprint  
**Purpose:** Quick reference for accessible color usage

---

## ✅ WCAG AA Compliant Colors (Use Freely)

### Dashboard Colors
```swift
// ✅ These pass WCAG AA for all text sizes
AppColors.Dashboard.taskAction        // Orange - 4.51:1 on dark
AppColors.Dashboard.noteAction        // Purple - 4.78:1 on dark
AppColors.Dashboard.guestAction       // Yellow - 14.08:1 on dark (AAA!)
AppColors.Dashboard.budgetCard        // Yellow bg - 16.99:1 with black text (AAA!)
AppColors.Dashboard.vendorCard        // Dark gray - 14.35:1 with white text (AAA!)
AppColors.Dashboard.guestCard         // Gray - 8.86:1 with white text (AAA!)
AppColors.Dashboard.taskProgressCard  // Green - 4.86:1 with white text
AppColors.Dashboard.budgetVisualizationCard // Cream - 19.20:1 with black text (AAA!)
```

### Budget Colors
```swift
// ✅ All budget colors pass WCAG AA (100% compliant!)
AppColors.Budget.income        // Green - 8.25:1 (AAA!)
AppColors.Budget.expense       // Red - 4.86:1
AppColors.Budget.pending       // Orange - 7.47:1 (AAA!)
AppColors.Budget.allocated     // Blue - 4.53:1
AppColors.Budget.overBudget    // Red - 4.86:1
AppColors.Budget.underBudget   // Green - 8.25:1 (AAA!)
```

### Guest Colors
```swift
// ✅ These pass WCAG AA for all text sizes
AppColors.Guest.confirmed      // Green - 8.25:1 (AAA!)
AppColors.Guest.pending        // Orange - 7.47:1 (AAA!)
AppColors.Guest.declined       // Red - 4.86:1
```

### Vendor Colors
```swift
// ✅ These pass WCAG AA for all text sizes
AppColors.Vendor.booked        // Green - 8.25:1 (AAA!)
AppColors.Vendor.pending       // Orange - 7.47:1 (AAA!)
AppColors.Vendor.contacted     // Blue - 4.53:1
AppColors.Vendor.contract      // Green - 6.57:1
```

### Semantic Colors
```swift
// ✅ All semantic colors pass WCAG AA (100% compliant!)
AppColors.success              // Green - 8.25:1 (AAA!)
AppColors.warning              // Orange - 7.47:1 (AAA!)
AppColors.error                // Red - 4.86:1
AppColors.info                 // Blue - 5.16:1
AppColors.textPrimary          // Label - 16.67:1 (AAA!)
AppColors.textSecondary        // Secondary - 16.67:1 (AAA!)
AppColors.textTertiary         // Tertiary - Passes AA
```

---

## ⚠️ Large Text Only Colors (Use with Caution)

These colors only meet WCAG AA for **large text** (18pt+ or 14pt+ bold):

### Dashboard Colors
```swift
// ⚠️ Use only with large text (18pt+ or 14pt+ bold)
AppColors.Dashboard.eventAction       // Green - 3.58:1
AppColors.Dashboard.rsvpCard          // Orange - 3.86:1
AppColors.Dashboard.countdownCard     // Purple - 3.64:1
```

### Guest Colors
```swift
// ⚠️ Use only with large text (18pt+ or 14pt+ bold)
AppColors.Guest.invited               // Gray - 3.45:1
AppColors.Guest.plusOne               // Purple - 3.94:1
```

### Vendor Colors
```swift
// ⚠️ Use only with large text (18pt+ or 14pt+ bold)
AppColors.Vendor.notContacted         // Gray - 3.45:1
```

---

## 📏 Text Size Requirements

### Normal Text (Requires 4.5:1 contrast)
```swift
Typography.bodyRegular        // 15pt - Use with AA colors only
Typography.bodySmall          // 13pt - Use with AA colors only
Typography.caption            // 12pt - Use with AA colors only
```

### Large Text (Requires 3.0:1 contrast)
```swift
Typography.title1             // 28pt bold - Can use large text colors
Typography.title2             // 22pt semibold - Can use large text colors
Typography.heading            // 17pt semibold - Can use large text colors
Typography.numberLarge        // 28pt bold - Can use large text colors
```

### Minimum Sizes for Large Text Colors
```swift
// For colors with 3.0:1 - 4.5:1 contrast
let minimumRegularSize: CGFloat = 18  // 18pt regular
let minimumBoldSize: CGFloat = 14     // 14pt bold
```

---

## 🎨 Usage Examples

### ✅ Correct Usage

```swift
// Using AA-compliant color with any text size
Text("Budget Total")
    .font(Typography.bodyRegular)
    .foregroundColor(AppColors.Budget.income)  // ✅ 8.25:1 ratio

// Using large text color with appropriate size
Text("Event")
    .font(Typography.title2)  // 22pt semibold
    .foregroundColor(AppColors.Dashboard.eventAction)  // ✅ Large text

// Using large text color with bold text
Text("RSVP")
    .font(.system(size: 16, weight: .bold))  // 16pt bold (>14pt)
    .foregroundColor(AppColors.Dashboard.rsvpCard)  // ✅ Large text

// Always pair color with icon for accessibility
HStack {
    Image(systemName: "checkmark.circle.fill")
    Text("Confirmed")
        .foregroundColor(AppColors.Guest.confirmed)
}
```

### ❌ Incorrect Usage

```swift
// Using large text color with small text
Text("Event")
    .font(Typography.bodySmall)  // 13pt - too small!
    .foregroundColor(AppColors.Dashboard.eventAction)  // ❌ Fails AA

// Using large text color without sufficient size
Text("Plus One")
    .font(.system(size: 14, weight: .regular))  // 14pt regular - too small!
    .foregroundColor(AppColors.Guest.plusOne)  // ❌ Needs 18pt or 14pt bold

// Color as only indicator (no icon or text)
Circle()
    .fill(AppColors.Guest.confirmed)  // ❌ Color-only indicator
```

---

## 🔍 Testing Your Colors

### Before Adding New Colors

```swift
// Test contrast ratio
let foreground = NSColor(yourColor)
let background = NSColor.windowBackgroundColor

let ratio = AppColors.contrastRatio(between: foreground, and: background)
print("Contrast ratio: \(ratio):1")

// Check WCAG AA compliance
let meetsAA = AppColors.meetsContrastRequirements(
    foreground: foreground,
    background: background
)
print("Meets WCAG AA: \(meetsAA)")

// Check WCAG AAA compliance
let meetsAAA = AppColors.meetsEnhancedContrastRequirements(
    foreground: foreground,
    background: background
)
print("Meets WCAG AAA: \(meetsAAA)")
```

### Running the Audit

```bash
# Run automated accessibility audit
cd "I Do Blueprint/Design"
swift GenerateAccessibilityReport.swift

# Run XCTests
xcodebuild test -scheme "I Do Blueprint" \
  -destination 'platform=macOS' \
  -only-testing:I_Do_BlueprintTests/ColorAccessibilityTests
```

---

## 🎯 Best Practices

### 1. Always Use Semantic Colors First
```swift
// ✅ Good - semantic color
Text("Success!")
    .foregroundColor(AppColors.success)

// ❌ Avoid - hardcoded color
Text("Success!")
    .foregroundColor(.green)
```

### 2. Pair Color with Other Indicators
```swift
// ✅ Good - color + icon + text
HStack {
    Image(systemName: "checkmark.circle.fill")
    Text("Confirmed")
}
.foregroundColor(AppColors.Guest.confirmed)

// ❌ Avoid - color only
Circle()
    .fill(AppColors.Guest.confirmed)
```

### 3. Use Appropriate Text Sizes
```swift
// ✅ Good - large text with large text color
Text("Event")
    .font(Typography.title2)
    .foregroundColor(AppColors.Dashboard.eventAction)

// ❌ Avoid - small text with large text color
Text("Event")
    .font(Typography.caption)
    .foregroundColor(AppColors.Dashboard.eventAction)
```

### 4. Test in Both Light and Dark Mode
```swift
// ✅ Good - uses adaptive color
.foregroundColor(AppColors.textPrimary)

// ⚠️ Caution - test in both modes
.foregroundColor(AppColors.Dashboard.eventAction)
```

### 5. Add Accessibility Labels
```swift
// ✅ Good - descriptive label
Text("Confirmed")
    .foregroundColor(AppColors.Guest.confirmed)
    .accessibilityLabel("RSVP Status: Confirmed")

// ❌ Avoid - no context
Text("Confirmed")
    .foregroundColor(AppColors.Guest.confirmed)
```

---

## 🚨 Common Mistakes

### Mistake 1: Using Color as Only Indicator
```swift
// ❌ Bad
if guest.rsvpStatus == .confirmed {
    Circle().fill(Color.green)
}

// ✅ Good
if guest.rsvpStatus == .confirmed {
    Label("Confirmed", systemImage: "checkmark.circle.fill")
        .foregroundColor(AppColors.Guest.confirmed)
}
```

### Mistake 2: Ignoring Text Size Requirements
```swift
// ❌ Bad
Text("Not Contacted")
    .font(.caption)  // Too small!
    .foregroundColor(AppColors.Vendor.notContacted)

// ✅ Good
Text("Not Contacted")
    .font(.title3)  // Large enough
    .foregroundColor(AppColors.Vendor.notContacted)
```

### Mistake 3: Not Testing Contrast
```swift
// ❌ Bad - no testing
let customColor = Color(red: 0.5, green: 0.5, blue: 0.5)
Text("Hello").foregroundColor(customColor)

// ✅ Good - test first
let customColor = Color(red: 0.5, green: 0.5, blue: 0.5)
let meetsAA = AppColors.meetsContrastRequirements(
    foreground: NSColor(customColor),
    background: .windowBackgroundColor
)
if meetsAA {
    Text("Hello").foregroundColor(customColor)
}
```

### Mistake 4: Hardcoding Colors
```swift
// ❌ Bad
.foregroundColor(Color(red: 0.29, green: 0.49, blue: 0.35))

// ✅ Good
.foregroundColor(AppColors.Dashboard.eventAction)
```

---

## 📋 Pre-Commit Checklist

Before committing code with new colors:

- [ ] Used semantic colors from `AppColors`
- [ ] Tested contrast ratio (4.5:1 for normal text, 3.0:1 for large)
- [ ] Paired color with icon or text label
- [ ] Used appropriate text size for color
- [ ] Added accessibility labels
- [ ] Tested in light and dark mode
- [ ] Tested with VoiceOver (if interactive)
- [ ] Ran automated accessibility tests
- [ ] Documented any exceptions

---

## 🔗 Quick Links

- **Full Audit Report:** `ACCESSIBILITY_AUDIT_REPORT.md`
- **Remediation Plan:** `ACCESSIBILITY_REMEDIATION_PLAN.md`
- **Manual Testing Guide:** `MANUAL_TESTING_GUIDE.md`
- **Test Suite:** `I Do BlueprintTests/Accessibility/ColorAccessibilityTests.swift`
- **Audit Script:** `I Do Blueprint/Design/GenerateAccessibilityReport.swift`

---

## 📞 Need Help?

- Review the full audit report for detailed contrast ratios
- Check the remediation plan for color adjustment recommendations
- Run the automated tests to verify your changes
- Consult WCAG 2.1 guidelines for specific requirements

---

**Last Updated:** October 17, 2025  
**Version:** 1.0  
**Maintained by:** Accessibility Team
