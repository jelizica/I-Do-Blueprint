# Design System & Accessibility Documentation

This directory contains the design system, color palette, and comprehensive accessibility audit documentation for I Do Blueprint.

---

## 📁 Core Design Files

### Design System
- **`DesignSystem.swift`** - Complete design system with colors, typography, spacing, and components
- **`ColorPalette.swift`** - Seating chart and visual planning color definitions
- **`Typography.swift`** - Typography system and text styles

---

## 🎨 Accessibility Audit (JES-54)

### Quick Start

**Run the audit:**
```bash
cd "I Do Blueprint/Design"
swift GenerateAccessibilityReport.swift
```

**Run tests:**
```bash
xcodebuild test -scheme "I Do Blueprint" \
  -destination 'platform=macOS' \
  -only-testing:I_Do_BlueprintTests/ColorAccessibilityTests
```

---

## 📚 Documentation Files

### 1. Executive Summary
**File:** `ACCESSIBILITY_AUDIT_SUMMARY.md`  
**Purpose:** High-level overview of audit results and recommendations  
**Audience:** Project managers, stakeholders, executives

**Contents:**
- Overall compliance metrics (80% WCAG AA, 46.7% WCAG AAA)
- Results by category
- Key findings and insights
- Next steps and timeline
- Success metrics

**Read this first for a quick overview!**

---

### 2. Full Audit Report
**File:** `ACCESSIBILITY_AUDIT_REPORT.md`  
**Purpose:** Complete test results with detailed contrast ratios  
**Audience:** Developers, designers, QA team

**Contents:**
- All 30 color combination test results
- Contrast ratios for each combination
- Pass/fail status (AA and AAA)
- Detailed remediation recommendations
- Testing methodology

**Use this for detailed technical information.**

---

### 3. Remediation Plan
**File:** `ACCESSIBILITY_REMEDIATION_PLAN.md`  
**Purpose:** Step-by-step guide to fix failing color combinations  
**Audience:** Developers, designers

**Contents:**
- Detailed fix recommendations for 6 colors
- Multiple solution options per issue
- Code examples and implementation guidance
- Priority and timeline
- Testing checklist

**Use this to implement fixes.**

---

### 4. Manual Testing Guide
**File:** `MANUAL_TESTING_GUIDE.md`  
**Purpose:** Procedures for VoiceOver and manual accessibility testing  
**Audience:** QA team, accessibility testers

**Contents:**
- VoiceOver testing procedures
- High contrast mode testing
- Color blindness simulation testing
- Light/dark mode testing
- Real-world usage testing
- Test result templates

**Use this for Phase 2 manual testing.**

---

### 5. Quick Reference Guide
**File:** `ACCESSIBILITY_QUICK_REFERENCE.md`  
**Purpose:** Developer quick reference for accessible color usage  
**Audience:** Developers

**Contents:**
- List of WCAG AA compliant colors
- List of large text only colors
- Text size requirements
- Usage examples (correct and incorrect)
- Best practices
- Common mistakes
- Pre-commit checklist

**Keep this handy while coding!**

---

## 🧪 Test Files

### Automated Test Suite
**File:** `AccessibilityAudit.swift`  
**Purpose:** Core audit logic and test result generation  
**Features:**
- Tests all color combinations
- Calculates WCAG 2.1 contrast ratios
- Generates detailed reports
- Provides remediation recommendations

### XCTest Suite
**File:** `../I Do BlueprintTests/Accessibility/ColorAccessibilityTests.swift`  
**Purpose:** Automated tests that can run in Xcode and CI/CD  
**Features:**
- 60+ test cases
- Tests all feature areas (Dashboard, Budget, Guest, Vendor, Semantic)
- Can be integrated into CI/CD pipeline
- Performance benchmarks

### Standalone Script
**File:** `GenerateAccessibilityReport.swift`  
**Purpose:** Command-line tool to generate audit reports  
**Usage:**
```bash
swift GenerateAccessibilityReport.swift
```
**Output:**
- Console summary
- `ACCESSIBILITY_AUDIT_REPORT.md` file

---

## 📊 Audit Results Summary

### Overall Compliance
- **Total Tests:** 30 color combinations
- **WCAG AA Passed:** 24 (80.0%)
- **WCAG AAA Passed:** 14 (46.7%)
- **Large Text Only:** 6 (20.0%)
- **Complete Failures:** 0 (0%)

### By Category
| Category | AA Pass Rate | Status |
|----------|--------------|--------|
| Budget | 100% (4/4) | ✅ Perfect |
| Semantic | 100% (5/5) | ✅ Perfect |
| Vendor | 80% (4/5) | ✅ Good |
| Guest | 60% (3/5) | ⚠️ Minor fixes |
| Dashboard | 64% (7/11) | ⚠️ Needs attention |

### Colors Requiring Attention (6 total)
1. Dashboard.eventAction - 3.58:1 (needs 4.5:1)
2. Dashboard.rsvpCard - 3.86:1 (needs 4.5:1)
3. Dashboard.countdownCard - 3.64:1 (needs 4.5:1)
4. Guest.invited - 3.45:1 (needs 4.5:1)
5. Guest.plusOne - 3.94:1 (needs 4.5:1)
6. Vendor.notContacted - 3.45:1 (needs 4.5:1)

---

## 🎯 Which Document Should I Read?

### I'm a developer implementing a feature
→ Start with **`ACCESSIBILITY_QUICK_REFERENCE.md`**  
→ Reference **`DesignSystem.swift`** for color definitions

### I'm fixing the failing colors
→ Read **`ACCESSIBILITY_REMEDIATION_PLAN.md`**  
→ Reference **`ACCESSIBILITY_AUDIT_REPORT.md`** for details

### I'm conducting manual testing
→ Follow **`MANUAL_TESTING_GUIDE.md`**  
→ Reference **`ACCESSIBILITY_AUDIT_REPORT.md`** for baseline

### I'm a project manager checking status
→ Read **`ACCESSIBILITY_AUDIT_SUMMARY.md`**  
→ Check Linear issue JES-54 for updates

### I'm a designer choosing colors
→ Read **`ACCESSIBILITY_QUICK_REFERENCE.md`**  
→ Use **`GenerateAccessibilityReport.swift`** to test new colors

### I'm setting up CI/CD
→ Use **`ColorAccessibilityTests.swift`** in test pipeline  
→ Reference **`ACCESSIBILITY_AUDIT_SUMMARY.md`** for context

---

## 🚀 Quick Actions

### Test a New Color
```swift
// In your code or playground
let foreground = NSColor(yourColor)
let background = NSColor.windowBackgroundColor

let ratio = AppColors.contrastRatio(between: foreground, and: background)
print("Contrast ratio: \(ratio):1")

let meetsAA = AppColors.meetsContrastRequirements(
    foreground: foreground,
    background: background
)
print("Meets WCAG AA: \(meetsAA)")
```

### Run Full Audit
```bash
cd "I Do Blueprint/Design"
swift GenerateAccessibilityReport.swift
```

### Run Automated Tests
```bash
xcodebuild test -scheme "I Do Blueprint" \
  -destination 'platform=macOS' \
  -only-testing:I_Do_BlueprintTests/ColorAccessibilityTests
```

### Check Specific Color
```swift
// Example: Check Dashboard event action
let eventAction = NSColor(AppColors.Dashboard.eventAction)
let darkBg = NSColor(AppColors.Dashboard.mainBackground)
let ratio = AppColors.contrastRatio(between: eventAction, and: darkBg)
print("Event Action contrast: \(ratio):1")
```

---

## 📋 Project Status

### Phase 1: Automated Testing ✅ Complete
- [x] Create automated test suite
- [x] Test all color combinations
- [x] Generate comprehensive report
- [x] Document remediation plan
- [x] Create developer guidelines

### Phase 2: Manual Verification ⏳ Next
- [ ] VoiceOver testing
- [ ] High contrast mode testing
- [ ] Color blindness simulation
- [ ] Light/dark mode verification
- [ ] Real-world usage testing

### Phase 3: Remediation ⏳ Pending
- [ ] Implement 6 color adjustments
- [ ] Re-run automated tests
- [ ] Visual regression testing
- [ ] Update documentation

### Phase 4: Validation ⏳ Pending
- [ ] Final accessibility audit
- [ ] User acceptance testing
- [ ] Team training
- [ ] Close issue

---

## 🔗 Related Resources

### Internal
- **Linear Issue:** JES-54
- **Design System:** `DesignSystem.swift`
- **Test Suite:** `../I Do BlueprintTests/Accessibility/`

### External
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Apple Accessibility Guidelines](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Color Blindness Simulator](https://www.color-blindness.com/coblis-color-blindness-simulator/)

---

## 📞 Need Help?

### Questions about audit results?
→ Check **`ACCESSIBILITY_AUDIT_REPORT.md`**

### Questions about fixing colors?
→ Check **`ACCESSIBILITY_REMEDIATION_PLAN.md`**

### Questions about testing?
→ Check **`MANUAL_TESTING_GUIDE.md`**

### Questions about using colors?
→ Check **`ACCESSIBILITY_QUICK_REFERENCE.md`**

### Still have questions?
→ Review Linear issue JES-54 comments  
→ Consult with accessibility team

---

## 🎉 Success Metrics

### Current Status
- ✅ 80% WCAG AA compliance
- ✅ 46.7% WCAG AAA compliance
- ✅ 0% complete failures
- ✅ Comprehensive documentation
- ✅ Automated testing infrastructure

### Target Goals
- 🎯 95%+ WCAG AA compliance
- 🎯 50%+ WCAG AAA compliance
- 🎯 0% complete failures
- 🎯 Automated CI/CD integration
- 🎯 Industry-leading accessibility

---

**Last Updated:** October 17, 2025  
**Issue:** JES-54  
**Status:** Phase 1 Complete  
**Next Review:** After Phase 2 completion
