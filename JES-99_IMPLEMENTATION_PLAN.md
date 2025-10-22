# JES-99: TODO/FIXME Cleanup - Implementation Plan

**Issue**: [JES-99](https://linear.app/jessica-clark-256/issue/JES-99)  
**Status**: Split into 3 Sub-Issues  
**Created**: 2025-01-22  
**Priority**: MEDIUM

---

## Executive Summary

Comprehensive analysis reveals **12 remaining TODOs** (down from 31+ originally reported). Most items from the original issue have already been resolved. The remaining TODOs are primarily in Visual Planning features and represent enhancement opportunities rather than critical gaps.

**Decision**: Split into 3 focused issues for better manageability, testing, and prioritization.

---

## Analysis Results

### ✅ Already Resolved (19+ items)

The following items from the original issue are **NO LONGER PRESENT** in the codebase:

- **MoodBoardEditorSheet.swift** (7 TODOs) - File refactored/removed
- **SearchableVendorList.swift** (4 TODOs) - File refactored/removed
- **MoodBoardView.swift** (4 TODOs) - File refactored/removed
- **TimelineEditorSheet.swift** validation - Resolved
- **VendorListViewV2.swift** pagination - Resolved
- **BudgetCategoryRowView.swift** caching - Resolved
- **VendorCard.swift** placeholders - Resolved

### 📋 Remaining TODOs (12 items)

#### **Category 1: Seating Chart Editor Sheets** (3 TODOs)
**File**: `SeatingChartEditorView.swift`
- Line 74: Implement ObstacleEditorSheet
- Line 77: Implement AssignmentEditorSheet
- Line 80: Implement TableSelectorSheet

**Priority**: MEDIUM | **Effort**: 6-8 hours | **Value**: HIGH

#### **Category 2: Style & Color Enhancements** (3 TODOs)
**Files**: `StylePreferencesView.swift`, `StylePreferencesComponents.swift`, `ColorPaletteCreatorView.swift`
- Line 485: Implement color picker interface
- Line 123: Add color palette preview
- Line 234: Load colors from mood boards

**Priority**: MEDIUM | **Effort**: 5-7 hours | **Value**: MEDIUM

#### **Category 3: Search, Export & Polish** (6 TODOs)
**Files**: `VisualPlanningSearchView.swift`, `AdvancedExportTemplateService.swift`, `DocumentDetailView.swift`, `LiveGuestRepository.swift`
- Line 156: Implement SearchFiltersView
- Line 160: Implement SavedSearchesView
- Line 175: Implement StylePreferencesSearchResultCard
- Line 282: Implement MoodBoardDetailsView
- Line 140: Show alert for invalid URL
- Line 20: Document pagination blocker

**Priority**: LOW | **Effort**: 8-10 hours | **Value**: LOW-MEDIUM

---

## Created Sub-Issues

### Issue 1: [JES-103](https://linear.app/jessica-clark-256/issue/JES-103)
**Title**: 🎯 Implement Seating Chart Editor Sheets

**Scope**:
- ObstacleEditorSheet - Edit venue obstacles (stage, bar, DJ booth, etc.)
- AssignmentEditorSheet - Edit seating assignments (guest, table, seat number)
- TableSelectorSheet - Quick table selection when assigning guests

**Why This Matters**:
- Completes major seating chart feature
- High user value
- Infrastructure already in place (state variables, helper methods)
- Clear pattern to follow (TableEditorSheet)

**Implementation Highlights**:
- Follow existing TableEditorSheet pattern
- Use design system (AppColors, Typography, Spacing)
- Add accessibility labels
- Write unit and UI tests
- Verify Xcode builds successfully

**Estimated Effort**: 6-8 hours
- ObstacleEditorSheet: 2-3 hours
- TableSelectorSheet: 2-3 hours
- AssignmentEditorSheet: 2-3 hours
- Testing & Polish: 1-2 hours

---

### Issue 2: [JES-104](https://linear.app/jessica-clark-256/issue/JES-104)
**Title**: 🎨 Implement Style & Color Enhancements

**Scope**:
- Color Picker Interface - Allow users to select 2-4 primary colors
- Color Palette Preview - Show color swatches in style category cards
- Mood Board Color Import - Extract and import colors from existing mood boards

**Why This Matters**:
- Improves visual planning UX
- Enables color customization
- Creates cohesive wedding aesthetics
- Leverages existing mood board data

**Implementation Highlights**:
- Use SwiftUI ColorPicker (built-in)
- Add color harmony suggestions
- Implement color extraction algorithm
- Show hex values for all colors
- Follow design system

**Estimated Effort**: 5-7 hours
- Color Picker Interface: 2-3 hours
- Color Palette Preview: 1-2 hours
- Mood Board Import: 2-3 hours
- Testing & Polish: 1 hour

---

### Issue 3: [JES-105](https://linear.app/jessica-clark-256/issue/JES-105)
**Title**: 🔍 Implement Search, Export & Polish Features

**Scope**:
- SearchFiltersView - Filter by type, date, tags, colors
- SavedSearchesView - Manage saved search queries
- StylePreferencesSearchResultCard - Enhanced search result display
- MoodBoardDetailsView - Detailed export with element descriptions
- Document URL Error Alert - User-friendly error messages
- Guest Pagination Documentation - Document technical blocker

**Why This Matters**:
- Nice-to-have enhancements
- Improves search experience
- Better export quality
- Improved error handling

**Implementation Highlights**:
- Implement filter UI with multiple criteria
- Add persistence for saved searches (UserDefaults)
- Create detailed export views
- Add user-friendly error alerts
- Document technical blockers

**Estimated Effort**: 8-10 hours
- Search Filters: 2-3 hours
- Saved Searches: 2-3 hours
- Style Preferences Card: 1 hour
- Mood Board Details: 2 hours
- Error Handling: 1 hour
- Testing & Polish: 1-2 hours

---

## Implementation Strategy

### Recommended Order

1. **JES-103** (Seating Chart) - Start here
   - Highest value
   - Completes major feature
   - Clear requirements
   - Existing patterns to follow

2. **JES-104** (Style & Color) - Second priority
   - Medium value
   - Improves UX
   - Leverages SwiftUI ColorPicker
   - Enhances visual planning

3. **JES-105** (Search & Polish) - Last priority
   - Lowest priority
   - Nice-to-have features
   - Can defer if needed
   - Mostly polish and enhancements

### Success Criteria (Overall)

- [ ] All 12 TODOs resolved or documented
- [ ] 3 sub-issues created and documented
- [ ] Each sub-issue has complete implementation details
- [ ] Xcode project builds successfully after each phase
- [ ] All tests pass
- [ ] Code follows best practices
- [ ] Documentation updated
- [ ] No new warnings or errors

### Quality Standards

**Code Quality**:
- Follow MVVM pattern
- Use `@MainActor` for UI classes
- Use `AppLogger` for logging
- Handle errors gracefully
- Add MARK comments
- Use descriptive names
- Add DocStrings
- No force unwrapping
- No magic numbers

**Design System**:
- Use AppColors for colors
- Use Typography for text styles
- Use Spacing constants
- Follow existing patterns
- Maintain consistency

**Accessibility**:
- Add accessibility labels
- Add accessibility hints
- Test with VoiceOver
- Ensure keyboard navigation
- Meet WCAG AA standards

**Testing**:
- Write unit tests
- Write UI tests
- Manual testing
- VoiceOver testing
- Performance testing

---

## Timeline Estimate

### Option A: Sequential Implementation
- **Week 1**: JES-103 (Seating Chart) - 6-8 hours
- **Week 2**: JES-104 (Style & Color) - 5-7 hours
- **Week 3**: JES-105 (Search & Polish) - 8-10 hours
- **Total**: 3 weeks (19-25 hours)

### Option B: Parallel Implementation (if multiple developers)
- **Sprint 1**: All 3 issues in parallel
- **Total**: 1 sprint (19-25 hours total, ~1 week with 3 developers)

---

## Risk Assessment

### Low Risk ✅
- Color picker implementation (standard SwiftUI)
- Error alert additions (simple UI)
- Color palette preview (visual only)
- Documentation updates

### Medium Risk ⚠️
- Seating chart sheets (complex state management)
- Search filters (multiple filter types)
- Saved searches (persistence required)
- Color extraction (algorithm complexity)

### High Risk ❌
- None identified

### Mitigation Strategies
- Follow existing patterns (TableEditorSheet, etc.)
- Incremental implementation with testing
- Use mock data for development
- Thorough code review
- Test with real data before production

---

## Dependencies

### Technical Dependencies ✅
- SwiftUI ColorPicker (built-in)
- Existing seating chart models
- Existing style preferences models
- Supabase for persistence
- Design system components

### Design Dependencies ✅
- Design system defined
- Color palette established
- Typography standards set
- Spacing constants defined
- Accessibility guidelines documented

### Product Dependencies ✅
- No product decisions needed
- All features are enhancements
- Requirements are clear
- User stories understood

---

## Documentation

### Created Documents
1. **JES-99_IMPLEMENTATION_PLAN.md** (this file)
   - Comprehensive analysis
   - Implementation strategy
   - Sub-issue breakdown

2. **Linear Issue JES-103**
   - Seating Chart Editor Sheets
   - Complete implementation details
   - Code examples and patterns

3. **Linear Issue JES-104**
   - Style & Color Enhancements
   - UI mockups and interfaces
   - Color extraction algorithm

4. **Linear Issue JES-105**
   - Search, Export & Polish
   - Filter specifications
   - Error handling improvements

### Reference Documents
- `best_practices.md` - Project coding standards
- `I Do Blueprint/Design/DesignSystem.swift` - Design system
- `I Do Blueprint/Design/ACCESSIBILITY_QUICK_REFERENCE.md` - Accessibility guidelines

---

## Verification Checklist

### Before Starting Each Issue
- [ ] Read complete issue description
- [ ] Understand technical context
- [ ] Review existing patterns
- [ ] Check dependencies
- [ ] Set up development branch

### During Implementation
- [ ] Follow implementation steps
- [ ] Use design system
- [ ] Add accessibility labels
- [ ] Write tests as you go
- [ ] Commit frequently
- [ ] Test incrementally

### After Completing Each Issue
- [ ] All TODOs removed
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Manual testing complete
- [ ] VoiceOver testing complete
- [ ] Xcode builds successfully
- [ ] No warnings or errors
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] Linear issue updated

---

## Communication Plan

### Progress Updates
- Comment on Linear issue after each major milestone
- Report blockers immediately
- Share screenshots/videos of completed features
- Request feedback early and often

### Code Review
- Create PR after completing each issue
- Link PR to Linear issue
- Request review from team
- Address feedback promptly

### Testing
- Test on real device/simulator
- Test with VoiceOver
- Test edge cases
- Test error scenarios
- Test performance

---

## Conclusion

This TODO cleanup has been successfully broken down into 3 manageable, well-documented issues. Each issue:

✅ Has complete implementation details  
✅ Can be picked up by any developer or AI agent  
✅ Has clear success criteria  
✅ Follows project best practices  
✅ Includes testing requirements  
✅ Has realistic time estimates  

**Total Effort**: 19-25 hours across 3 sprints  
**Priority Order**: JES-103 → JES-104 → JES-105  
**Risk Level**: Low to Medium  
**Blocker**: None - all dependencies met  

**Ready to implement!** 🚀

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-22  
**Status**: Complete - Ready for Implementation  
**Next Action**: Begin JES-103 (Seating Chart Editor Sheets)
