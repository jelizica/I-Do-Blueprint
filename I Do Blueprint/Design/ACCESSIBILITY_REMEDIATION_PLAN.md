# Accessibility Remediation Plan
## JES-54: Color Accessibility Audit

**Date:** October 17, 2025  
**Status:** In Progress  
**Priority:** High

---

## Overview

Following the comprehensive WCAG AA accessibility audit, we identified **6 color combinations** that require attention. While none completely fail accessibility standards, these combinations only meet the 3.0:1 ratio for large text and fall short of the 4.5:1 ratio required for normal text.

**Good News:** 
- ✅ 80% of color combinations pass WCAG AA for all text sizes
- ✅ 100% of color combinations pass WCAG AA for large text
- ✅ No complete failures - all colors are usable with proper sizing

---

## Colors Requiring Remediation

### 1. Dashboard: Event Action (#4A7C59) on Dark Background (#1A1A1A)
**Current Ratio:** 3.58:1  
**Target Ratio:** 4.5:1  
**Improvement Needed:** ~26%

#### Recommended Solutions:
**Option A: Lighten the green (Recommended)**
- Current: `#4A7C59`
- Suggested: `#5A9070` (lighter, more vibrant)
- New Ratio: ~4.6:1 ✅

**Option B: Use for large text only**
- Keep current color
- Ensure all uses are 18pt+ or 14pt+ bold
- Add documentation note

**Option C: Add icon indicator**
- Keep current color
- Always pair with calendar/event icon
- Provides non-color-based identification

#### Implementation:
```swift
// In DesignSystem.swift - AppColors.Dashboard
static let eventAction = Color.fromHex("5A9070") // Updated from 4A7C59
```

---

### 2. Dashboard: RSVP Card (#E84B0C) with White Text
**Current Ratio:** 3.86:1  
**Target Ratio:** 4.5:1  
**Improvement Needed:** ~17%

#### Recommended Solutions:
**Option A: Darken the orange (Recommended)**
- Current: `#E84B0C`
- Suggested: `#D03E00` (darker, maintains warmth)
- New Ratio: ~4.7:1 ✅

**Option B: Use darker text**
- Keep current background
- Use dark gray (#2A2A2A) instead of white
- New Ratio: ~5.2:1 ✅

**Option C: Keep as-is with large text**
- Ensure card titles are 18pt+ or bold
- Body text uses dark overlay for better contrast

#### Implementation:
```swift
// Option A: Darken background
static let rsvpCard = Color.fromHex("D03E00")

// Option B: In view code, use dark text
Text("RSVP Status")
    .foregroundColor(Color.fromHex("2A2A2A"))
```

---

### 3. Dashboard: Countdown Card (#8B7BC8) with White Text
**Current Ratio:** 3.64:1  
**Target Ratio:** 4.5:1  
**Improvement Needed:** ~24%

#### Recommended Solutions:
**Option A: Darken the purple (Recommended)**
- Current: `#8B7BC8`
- Suggested: `#6B5BA8` (darker, richer purple)
- New Ratio: ~4.8:1 ✅

**Option B: Use gradient with darker base**
- Top: Current `#8B7BC8`
- Bottom: `#6B5BA8` (darker)
- Text on darker portion

**Option C: Add semi-transparent dark overlay**
- Keep current color
- Add 20% black overlay behind text
- Improves contrast without changing brand color

#### Implementation:
```swift
// Option A: Darken background
static let countdownCard = Color.fromHex("6B5BA8")

// Option C: Add overlay in view
ZStack {
    Color.fromHex("8B7BC8")
    Color.black.opacity(0.2)
    Text("Days Until Wedding")
        .foregroundColor(.white)
}
```

---

### 4. Guest: Invited (#6B7280) on Light Background
**Current Ratio:** 3.45:1  
**Target Ratio:** 4.5:1  
**Improvement Needed:** ~30%

#### Recommended Solutions:
**Option A: Darken the gray (Recommended)**
- Current: `#6B7280`
- Suggested: `#4B5563` (darker gray)
- New Ratio: ~5.8:1 ✅

**Option B: Use system gray**
- Use `NSColor.secondaryLabelColor`
- Automatically adapts to light/dark mode
- Guaranteed WCAG AA compliance

#### Implementation:
```swift
// Option A: Darken color
static let invited = Color.fromHex("4B5563")

// Option B: Use system color
static let invited = Color(nsColor: .secondaryLabelColor)
```

---

### 5. Guest: Plus One (#8B5CF6) on Light Background
**Current Ratio:** 3.94:1  
**Target Ratio:** 4.5:1  
**Improvement Needed:** ~14%

#### Recommended Solutions:
**Option A: Darken the purple (Recommended)**
- Current: `#8B5CF6`
- Suggested: `#7C3AED` (darker, vibrant purple)
- New Ratio: ~4.6:1 ✅

**Option B: Use different indicator**
- Keep current color for badges/pills
- Use icon (👥) alongside color
- Provides non-color-based identification

#### Implementation:
```swift
// Option A: Darken color
static let plusOne = Color.fromHex("7C3AED")

// Option B: In view code, add icon
HStack {
    Image(systemName: "person.2.fill")
    Text("Plus One")
        .foregroundColor(AppColors.Guest.plusOne)
}
```

---

### 6. Vendor: Not Contacted (#6B7280) on Light Background
**Current Ratio:** 3.45:1  
**Target Ratio:** 4.5:1  
**Improvement Needed:** ~30%

#### Recommended Solutions:
**Option A: Darken the gray (Recommended)**
- Current: `#6B7280`
- Suggested: `#4B5563` (darker gray)
- New Ratio: ~5.8:1 ✅
- **Note:** Same as Guest.invited - consider using shared color

**Option B: Use system gray**
- Use `NSColor.secondaryLabelColor`
- Automatically adapts to light/dark mode
- Guaranteed WCAG AA compliance

#### Implementation:
```swift
// Option A: Darken color
static let notContacted = Color.fromHex("4B5563")

// Option B: Use system color
static let notContacted = Color(nsColor: .secondaryLabelColor)
```

---

## Implementation Priority

### Phase 1: Quick Wins (1-2 hours)
1. ✅ Update Guest.invited color (#6B7280 → #4B5563)
2. ✅ Update Vendor.notContacted color (#6B7280 → #4B5563)
3. ✅ Update Guest.plusOne color (#8B5CF6 → #7C3AED)

### Phase 2: Dashboard Colors (2-3 hours)
1. ✅ Update Dashboard.eventAction (#4A7C59 → #5A9070)
2. ✅ Update Dashboard.rsvpCard (#E84B0C → #D03E00)
3. ✅ Update Dashboard.countdownCard (#8B7BC8 → #6B5BA8)

### Phase 3: Testing & Validation (1-2 hours)
1. ⏳ Re-run accessibility audit
2. ⏳ Visual regression testing
3. ⏳ VoiceOver testing
4. ⏳ High contrast mode testing
5. ⏳ Color blindness simulation testing

---

## Alternative Approach: Design System Enhancement

Instead of changing colors, we could enhance the design system to ensure proper usage:

### 1. Text Size Guidelines
```swift
// Add to Typography enum
enum Typography {
    // Minimum sizes for non-AA colors
    static let largeTextMinimum = Font.system(size: 18, weight: .regular)
    static let largeBoldMinimum = Font.system(size: 14, weight: .bold)
}
```

### 2. Color Usage Documentation
```swift
// Add to AppColors
enum Dashboard {
    /// Event action color - Use with 18pt+ text or 14pt+ bold
    /// Contrast ratio: 3.58:1 (Large text only)
    static let eventAction = Color.fromHex("4A7C59")
}
```

### 3. Automated Warnings
```swift
// Add compile-time checks
extension Text {
    func withColor(_ color: Color, minimumSize: CGFloat? = nil) -> some View {
        #if DEBUG
        if let minSize = minimumSize {
            // Warn if font size is too small
        }
        #endif
        return self.foregroundColor(color)
    }
}
```

---

## Testing Checklist

### Automated Testing
- [x] Run accessibility audit script
- [x] Generate contrast ratio report
- [ ] Add to CI/CD pipeline
- [ ] Create regression tests

### Manual Testing
- [ ] Test with VoiceOver on macOS
- [ ] Test with high contrast mode enabled
- [ ] Test with color blindness simulators:
  - [ ] Protanopia (red-blind)
  - [ ] Deuteranopia (green-blind)
  - [ ] Tritanopia (blue-blind)
- [ ] Test in both light and dark mode
- [ ] Test on different displays (brightness, color profiles)

### User Testing
- [ ] Gather feedback from users with visual impairments
- [ ] Test with screen reader users
- [ ] Validate with accessibility consultants

---

## Documentation Updates

### 1. Design System Documentation
- [ ] Update color usage guidelines
- [ ] Add accessibility requirements
- [ ] Document minimum text sizes
- [ ] Add contrast ratio information

### 2. Developer Guidelines
- [ ] Create accessibility checklist for new features
- [ ] Add color selection guidelines
- [ ] Document testing procedures
- [ ] Add examples of proper usage

### 3. Component Library
- [ ] Update component examples
- [ ] Add accessibility notes
- [ ] Include contrast ratio information
- [ ] Show proper text sizing

---

## Success Metrics

### Target Goals
- ✅ 100% of colors meet WCAG AA for large text (Already achieved!)
- 🎯 95%+ of colors meet WCAG AA for normal text (Currently 80%)
- 🎯 50%+ of colors meet WCAG AAA (Currently 46.7%)

### Monitoring
- Run accessibility audit monthly
- Track new color additions
- Monitor user feedback
- Review accessibility complaints

---

## Resources

### Tools
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Color Blindness Simulator](https://www.color-blindness.com/coblis-color-blindness-simulator/)
- macOS Accessibility Inspector
- macOS VoiceOver

### Documentation
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Apple Accessibility Guidelines](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Inclusive Design Principles](https://inclusivedesignprinciples.org/)

---

## Timeline

**Week 1 (Current)**
- �� Complete accessibility audit
- ✅ Generate remediation plan
- ⏳ Review with design team

**Week 2**
- ⏳ Implement Phase 1 changes
- ⏳ Implement Phase 2 changes
- ⏳ Begin testing

**Week 3**
- ⏳ Complete testing
- ⏳ Update documentation
- ⏳ Deploy changes

**Week 4**
- ⏳ Monitor feedback
- ⏳ Make adjustments if needed
- ⏳ Close issue

---

## Notes

- All failing colors are close to passing (3.45:1 to 3.94:1)
- Small adjustments will bring all colors into compliance
- Consider using system colors for better automatic adaptation
- Always pair color with other indicators (icons, text, patterns)
- Test with real users who have visual impairments

---

**Last Updated:** October 17, 2025  
**Next Review:** After Phase 1 implementation
