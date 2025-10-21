# Manual Accessibility Testing Guide
## JES-54: Color Accessibility Audit

**Purpose:** Validate automated test results through manual testing with assistive technologies and accessibility tools.

---

## Prerequisites

### Required Tools
- ✅ macOS with VoiceOver (built-in)
- ✅ Accessibility Inspector (Xcode → Open Developer Tool → Accessibility Inspector)
- ✅ Color blindness simulator (online or app)
- ✅ High contrast mode (System Settings → Accessibility → Display)

### Optional Tools
- Color Oracle (free color blindness simulator)
- Sim Daltonism (macOS color blindness simulator)
- Contrast Analyzer by TPGi

---

## Test 1: VoiceOver Testing

### Setup
1. Enable VoiceOver: `Cmd + F5` or System Settings → Accessibility → VoiceOver
2. Learn basic commands:
   - `VO + Right Arrow` - Next item
   - `VO + Left Arrow` - Previous item
   - `VO + Space` - Activate item
   - `VO + A` - Read all
   - `VO` = `Control + Option`

### Test Scenarios

#### Dashboard Quick Actions
**Location:** Dashboard view → Quick actions bar

**Test Steps:**
1. Navigate to quick actions bar with VoiceOver
2. Tab through each action button
3. Verify each button is announced correctly:
   - "Add Task" button
   - "Add Note" button
   - "Add Event" button
   - "Add Guest" button

**Expected Results:**
- [ ] All buttons are discoverable
- [ ] Button labels are clear and descriptive
- [ ] Color is not the only indicator (icons present)
- [ ] Focus indicator is visible

**Notes:**
```
Button: [Name]
Color: [Hex]
Contrast: [Ratio]
Status: [Pass/Fail]
Issues: [Any problems encountered]
```

#### Dashboard Cards
**Location:** Dashboard view → Bento grid cards

**Test Steps:**
1. Navigate through each card with VoiceOver
2. Verify card titles and content are announced
3. Check that status information is conveyed

**Cards to Test:**
- [ ] Budget card (yellow background)
- [ ] RSVP card (orange background)
- [ ] Vendor card (dark gray background)
- [ ] Guest card (medium gray background)
- [ ] Countdown card (purple background)
- [ ] Budget visualization card (cream background)
- [ ] Task progress card (green background)

**Expected Results:**
- [ ] Card purpose is clear from announcement
- [ ] Text is readable with VoiceOver
- [ ] Interactive elements are accessible
- [ ] Status information is conveyed

#### Budget Status Indicators
**Location:** Budget view → Transaction list

**Test Steps:**
1. Navigate to budget transactions
2. Tab through items with different statuses
3. Verify status is announced (not just color)

**Statuses to Test:**
- [ ] Income (green)
- [ ] Expense (red)
- [ ] Pending (orange)
- [ ] Allocated (blue)

**Expected Results:**
- [ ] Status is announced verbally
- [ ] Color is supplemented with text/icons
- [ ] Amounts are read correctly
- [ ] Categories are clear

#### Guest RSVP Status
**Location:** Guest list view

**Test Steps:**
1. Navigate to guest list
2. Tab through guests with different statuses
3. Verify RSVP status is announced

**Statuses to Test:**
- [ ] Confirmed (green)
- [ ] Pending (orange)
- [ ] Declined (red)
- [ ] Invited (gray)
- [ ] Plus One (purple)

**Expected Results:**
- [ ] Status is announced verbally
- [ ] Guest name is clear
- [ ] Status is not color-only
- [ ] Interactive elements work

#### Vendor Status
**Location:** Vendor list view

**Test Steps:**
1. Navigate to vendor list
2. Tab through vendors with different statuses
3. Verify status is announced

**Statuses to Test:**
- [ ] Booked (green)
- [ ] Pending (orange)
- [ ] Contacted (blue)
- [ ] Not Contacted (gray)
- [ ] Contract (green)

**Expected Results:**
- [ ] Status is announced verbally
- [ ] Vendor name is clear
- [ ] Status is not color-only
- [ ] Actions are accessible

---

## Test 2: High Contrast Mode Testing

### Setup
1. Open System Settings → Accessibility → Display
2. Enable "Increase contrast"
3. Optionally enable "Reduce transparency"

### Test Scenarios

#### Visual Inspection
**Test Steps:**
1. Navigate through all main views
2. Check that all text is readable
3. Verify borders and separators are visible
4. Ensure interactive elements are distinguishable

**Views to Test:**
- [ ] Dashboard
- [ ] Budget view
- [ ] Guest list
- [ ] Vendor list
- [ ] Task list
- [ ] Timeline view

**Expected Results:**
- [ ] All text remains readable
- [ ] Borders are visible
- [ ] Interactive elements are clear
- [ ] No information is lost
- [ ] Colors adapt appropriately

#### Color Combinations
**Test Steps:**
1. Check each color combination from audit
2. Verify they still work in high contrast mode
3. Note any issues or improvements

**Specific Checks:**
- [ ] Dashboard quick actions on dark background
- [ ] Dashboard cards with various backgrounds
- [ ] Status indicators (all colors)
- [ ] Text on colored backgrounds
- [ ] Buttons and interactive elements

**Expected Results:**
- [ ] Contrast is maintained or improved
- [ ] No text becomes unreadable
- [ ] System respects high contrast settings
- [ ] App adapts gracefully

---

## Test 3: Color Blindness Simulation

### Setup
1. Use online simulator: https://www.color-blindness.com/coblis-color-blindness-simulator/
2. Or download Color Oracle (free macOS app)
3. Or use Sim Daltonism (Mac App Store)

### Test Scenarios

#### Protanopia (Red-Blind) Testing
**Affected Colors:**
- Red (expense, declined, error)
- Orange (pending, warning)
- Green (income, confirmed, success)

**Test Steps:**
1. Enable protanopia simulation
2. Navigate through app
3. Check if status is distinguishable without red

**Views to Test:**
- [ ] Budget view (income vs expense)
- [ ] Guest list (confirmed vs declined)
- [ ] Vendor list (booked vs pending)
- [ ] Dashboard cards (RSVP, task progress)

**Expected Results:**
- [ ] Status is distinguishable by more than color
- [ ] Icons or text labels provide clarity
- [ ] No critical information is color-only
- [ ] User can complete tasks

**Notes:**
```
View: [Name]
Issue: [Description]
Severity: [Low/Medium/High]
Recommendation: [Fix suggestion]
```

#### Deuteranopia (Green-Blind) Testing
**Affected Colors:**
- Green (income, confirmed, success)
- Red (expense, declined, error)
- Orange (pending, warning)

**Test Steps:**
1. Enable deuteranopia simulation
2. Navigate through app
3. Check if status is distinguishable without green

**Views to Test:**
- [ ] Budget view (income vs expense)
- [ ] Guest list (confirmed vs declined)
- [ ] Vendor list (booked vs pending)
- [ ] Dashboard cards (task progress, budget viz)

**Expected Results:**
- [ ] Status is distinguishable by more than color
- [ ] Icons or text labels provide clarity
- [ ] No critical information is color-only
- [ ] User can complete tasks

#### Tritanopia (Blue-Blind) Testing
**Affected Colors:**
- Blue (allocated, contacted, info)
- Purple (plus one, countdown, note action)
- Yellow (guest action, budget card)

**Test Steps:**
1. Enable tritanopia simulation
2. Navigate through app
3. Check if status is distinguishable without blue

**Views to Test:**
- [ ] Dashboard quick actions
- [ ] Budget view (allocated status)
- [ ] Guest list (plus one indicator)
- [ ] Vendor list (contacted status)

**Expected Results:**
- [ ] Status is distinguishable by more than color
- [ ] Icons or text labels provide clarity
- [ ] No critical information is color-only
- [ ] User can complete tasks

#### Achromatopsia (Complete Color Blindness) Testing
**Test Steps:**
1. Enable grayscale simulation
2. Navigate through entire app
3. Verify all information is accessible

**Expected Results:**
- [ ] All information is conveyed without color
- [ ] Text labels are present
- [ ] Icons supplement color
- [ ] Patterns or shapes differentiate items
- [ ] User can complete all tasks

---

## Test 4: Light vs Dark Mode Testing

### Setup
1. Test in light mode (default)
2. Switch to dark mode: System Settings → Appearance → Dark
3. Compare results

### Test Scenarios

#### Color Adaptation
**Test Steps:**
1. View each color in light mode
2. Switch to dark mode
3. Verify colors adapt appropriately

**Colors to Test:**
- [ ] Dashboard backgrounds
- [ ] Status indicators
- [ ] Text colors
- [ ] Card backgrounds
- [ ] Interactive elements

**Expected Results:**
- [ ] Colors adapt to mode
- [ ] Contrast is maintained
- [ ] Text remains readable
- [ ] No jarring transitions
- [ ] Semantic meaning preserved

#### Contrast Verification
**Test Steps:**
1. Check contrast ratios in both modes
2. Verify WCAG AA compliance in both
3. Note any mode-specific issues

**Expected Results:**
- [ ] Both modes meet WCAG AA
- [ ] System colors adapt correctly
- [ ] Custom colors work in both modes
- [ ] No mode-specific failures

---

## Test 5: Display Variation Testing

### Setup
Test on different displays if available:
- Built-in MacBook display
- External monitor
- Different brightness levels
- Different color profiles

### Test Scenarios

#### Brightness Testing
**Test Steps:**
1. Set display to minimum brightness
2. Check if colors are distinguishable
3. Set display to maximum brightness
4. Check if colors are still comfortable

**Expected Results:**
- [ ] Colors work at all brightness levels
- [ ] Text remains readable
- [ ] No glare or eye strain
- [ ] Contrast is maintained

#### Color Profile Testing
**Test Steps:**
1. Try different color profiles (if available)
2. Check if colors remain distinguishable
3. Verify contrast is maintained

**Expected Results:**
- [ ] Colors work across profiles
- [ ] Semantic meaning preserved
- [ ] No critical failures

---

## Test 6: Real-World Usage Testing

### Setup
Recruit testers with:
- Visual impairments
- Color blindness
- Low vision
- Screen reader users

### Test Scenarios

#### Task Completion
**Test Steps:**
1. Ask users to complete common tasks
2. Observe any difficulties
3. Gather feedback

**Tasks:**
- [ ] Add a budget item
- [ ] Check RSVP status
- [ ] Find a vendor
- [ ] View task progress
- [ ] Navigate dashboard

**Expected Results:**
- [ ] Users can complete tasks
- [ ] No confusion about status
- [ ] Colors don't hinder usage
- [ ] Alternative indicators work

#### Feedback Collection
**Questions to Ask:**
- Can you distinguish between different statuses?
- Is any information unclear or confusing?
- Do colors help or hinder your experience?
- What improvements would you suggest?
- Are there any accessibility barriers?

---

## Results Documentation

### Test Result Template
```markdown
## Test: [Test Name]
**Date:** [Date]
**Tester:** [Name]
**Environment:** [macOS version, display, etc.]

### Results
- **Pass/Fail:** [Status]
- **Issues Found:** [Number]
- **Severity:** [Low/Medium/High]

### Issues
1. [Issue description]
   - Location: [Where]
   - Impact: [Who/what affected]
   - Recommendation: [Fix suggestion]

### Screenshots
[Attach relevant screenshots]

### Notes
[Additional observations]
```

### Summary Report Template
```markdown
## Manual Testing Summary
**Date:** [Date]
**Tests Completed:** [Number]
**Issues Found:** [Number]

### Pass/Fail by Category
- VoiceOver: [Pass/Fail]
- High Contrast: [Pass/Fail]
- Color Blindness: [Pass/Fail]
- Light/Dark Mode: [Pass/Fail]
- Display Variation: [Pass/Fail]
- Real-World Usage: [Pass/Fail]

### Critical Issues
[List any critical issues]

### Recommendations
[List recommendations]

### Next Steps
[What needs to be done]
```

---

## Success Criteria

### Must Pass
- [ ] All interactive elements accessible with VoiceOver
- [ ] All text readable in high contrast mode
- [ ] Status distinguishable without color
- [ ] Works in both light and dark mode
- [ ] No critical accessibility barriers

### Should Pass
- [ ] Comfortable to use at all brightness levels
- [ ] Works well with color blindness
- [ ] Positive feedback from users with disabilities
- [ ] No confusion about status or actions

### Nice to Have
- [ ] Exceeds WCAG AA standards
- [ ] Delightful experience for all users
- [ ] Innovative accessibility features
- [ ] Industry-leading accessibility

---

## Timeline

**Week 1:** VoiceOver and High Contrast testing  
**Week 2:** Color blindness simulation testing  
**Week 3:** Real-world user testing  
**Week 4:** Documentation and remediation

---

## Resources

### Apple Documentation
- [VoiceOver User Guide](https://support.apple.com/guide/voiceover/welcome/mac)
- [Accessibility Inspector Guide](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXTestingApps.html)

### Testing Tools
- [Color Oracle](https://colororacle.org/) - Free color blindness simulator
- [Sim Daltonism](https://michelf.ca/projects/sim-daltonism/) - macOS color blindness simulator
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Guidelines
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Apple HIG - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

---

**Last Updated:** October 17, 2025  
**Next Review:** After manual testing completion
