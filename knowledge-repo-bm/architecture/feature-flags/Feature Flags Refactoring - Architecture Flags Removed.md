---
title: Feature Flags Refactoring - Architecture Flags Removed
type: note
permalink: architecture/feature-flags/feature-flags-refactoring-architecture-flags-removed
tags:
- feature-flags
- refactoring
- architecture
- completed
---

# Feature Flags Refactoring - Architecture Flags Removed

**Date**: 2025-01-XX
**Status**: Completed
**Related Issue**: I Do Blueprint-w06

## Summary

Removed architecture-related feature flags (BudgetStoreV2, GuestStoreV2, VendorStoreV2) from the feature flag system. The app now automatically uses the most up-to-date architecture (V2 stores with repository pattern). Only actual feature flags remain, and they all default to enabled (true).

## Changes Made

### 1. FeatureFlags.swift
- **Removed**: Architecture flags (`useBudgetStoreV2`, `useGuestStoreV2`, `useVendorStoreV2`)
- **Kept**: Completed feature flags (Timeline Milestones, Advanced Budget Export, Visual Planning Paste, Image Picker, Template Application, Expense Details, Budget Analytics Actions)
- **Default Behavior**: All features now default to `true` (enabled)
- **Updated Documentation**: Changed usage examples to reflect new behavior

### 2. FeatureFlagsSettingsView.swift
- **Removed**: "Store Architecture" section with V2 toggles
- **Updated**: Header text to clarify all features are enabled by default
- **Updated**: Reset confirmation message to indicate features reset to enabled state

## Rationale

### Why Remove Architecture Flags?
1. **Architecture is not a feature**: The V2 architecture (repository pattern, domain services, cache strategies) is the current standard, not an optional feature
2. **No rollback needed**: V2 architecture is stable and production-ready
3. **Reduces complexity**: Fewer flags to manage and test
4. **Clearer intent**: Feature flags should control user-facing features, not internal architecture

### Why Auto-Enable Features?
1. **Completed features**: All flagged features are complete and tested
2. **Better UX**: Users get all features by default
3. **Testing flexibility**: Can still disable for debugging/testing
4. **Production ready**: 100% rollout percentage indicates production readiness

## Feature Flag Philosophy

### What Should Be a Feature Flag?
✅ **YES** - User-facing features that:
- Are newly completed and need gradual rollout
- May need to be disabled for specific users/testing
- Have potential performance/stability concerns
- Require A/B testing or experimentation

❌ **NO** - Internal architecture decisions:
- Store implementations (V2 vs V3)
- Repository patterns
- Cache strategies
- Service layer refactorings

### Feature Flag Lifecycle
1. **Development**: Feature flag added, defaults to `false` in DEBUG, `0%` rollout in production
2. **Testing**: Enabled in DEBUG for testing
3. **Gradual Rollout**: Increase rollout percentage (10% → 25% → 50% → 100%)
4. **Stable**: Set to 100% rollout, defaults to `true`
5. **Cleanup** (optional): Remove flag after 1-2 releases if no issues

## Current Feature Flags

All flags default to **enabled (true)**:

| Flag | Description | Status |
|------|-------------|--------|
| `enableTimelineMilestones` | View all milestones feature | ✅ Completed |
| `enableAdvancedBudgetExport` | PDF/CSV export with detailed reports | ✅ Completed |
| `enableVisualPlanningPaste` | Copy/paste elements in mood boards | ✅ Completed |
| `enableImagePicker` | Add images to mood boards | ✅ Completed |
| `enableTemplateApplication` | Apply mood board templates | ✅ Completed |
| `enableExpenseDetails` | View detailed expense information | ✅ Completed |
| `enableBudgetAnalyticsActions` | Insight actions in budget analytics | ✅ Completed |

## Testing

### Manual Testing
1. Open Settings → Developer → Feature Flags
2. Verify "Store Architecture" section is removed
3. Verify all features show as enabled by default
4. Toggle a feature off → verify it disables
5. Reset all flags → verify all return to enabled

### Automated Testing
- No test changes needed (architecture flags were not tested)
- Feature flag tests continue to work as before

## Migration Notes

### For Developers
- Remove any code checking `FeatureFlags.useBudgetStoreV2` (none found)
- Always use V2 stores (BudgetStoreV2, GuestStoreV2, VendorStoreV2)
- No migration needed for existing code

### For Users
- No user-facing changes
- All features remain enabled
- Settings UI simplified (no architecture section)

## Future Considerations

### When to Add New Feature Flags
Only add flags for:
1. **New user-facing features** that need gradual rollout
2. **Experimental features** that may be reverted
3. **Performance-sensitive features** that may need disabling

### When to Remove Feature Flags
Remove flags when:
1. Feature has been stable at 100% rollout for 2+ releases
2. No rollback concerns remain
3. Flag adds unnecessary complexity

## Related Documentation
- `FeatureFlags.swift` - Feature flag implementation
- `PerformanceFeatureFlags.swift` - Performance-specific flags (separate system)
- `best_practices.md` - Feature flag best practices
- `AGENTS.md` - Repository guidelines

## Lessons Learned

1. **Architecture ≠ Features**: Internal architecture decisions should not be feature-flagged
2. **Default to Enabled**: Completed features should default to enabled for better UX
3. **Clear Separation**: Keep performance flags separate from feature flags
4. **Lifecycle Management**: Have a clear process for flag creation, rollout, and removal
