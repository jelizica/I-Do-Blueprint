---
title: Beads Issues - Active Work and Technical Debt
type: note
permalink: project-management/beads-issues-active-work-and-technical-debt
tags:
- beads
- issues
- technical-debt
- project-management
- workflow
---

# Beads Issues - Active Work and Technical Debt

## Overview

I Do Blueprint uses **beads** (MCP tool) for issue tracking and project management. As of 2025-12-29, there are 35 total issues with 13 open, 2 in progress, and 20 closed.

## Project Statistics

- **Total Issues:** 35
- **Open:** 13
- **In Progress:** 2
- **Blocked:** 4
- **Closed:** 20
- **Ready to Work:** 9
- **Average Lead Time:** 1.8 hours

**Recent Activity (Last 24 Hours):**
- Commits: 14
- Total Changes: 52
- Issues Created: 52 (including historical imports)
- Issues Closed: 0 (recently)

## In Progress Issues

### I Do Blueprint-aip [P2] [CLOSED]
**Title:** Complete Error Handling - Final 2 Files  
**Status:** Closed (recently completed on 2025-12-29)  
**Priority:** P2  
**Tags:** code-quality, error-handling, medium

**Description:**
Complete error handling standardization for the final 2 medium-priority stores.

**Files Remaining (before closure):**
1. DocumentUploadStore.swift (~3 catch blocks)
2. BudgetStoreV2+PaymentStatus.swift (~2 catch blocks)

**Pattern Applied:**
```swift
await handleError(error, operation: "operationName", context: [...]) { [weak self] in
    await self?.operation()
}
```

**Related Work:**
- I Do Blueprint-8tl - Completed VendorStoreV2, TaskStoreV2, OnboardingStoreV2
- I Do Blueprint-2qj - Standardized medium-priority stores
- I Do Blueprint-8pl - Standardized high-priority stores
- I Do Blueprint-ded - Original error handling epic

**Status:** ✅ COMPLETED - All stores now use standardized error handling

### I Do Blueprint-0wo [P2]
**Title:** Reduce MockBudgetRepository.swift Size  
**Status:** In Progress  
**Priority:** P2  
**Tags:** high, refactoring, testing

**Description:**
MockBudgetRepository is very large and needs refactoring and optimization for better test performance and maintainability.

**Context:**
- Budget domain is the most complex with 25+ model files
- Mock repository needs to support all budget operations
- Related to testing infrastructure improvements

**Next Steps:**
- Split into smaller focused mock classes
- Optimize test data builders
- Reduce duplication

## Blocked Issues (4)

All blocked by **I Do Blueprint-0t9** (Large Service Files Decomposition):

### 1. I Do Blueprint-0vc [P2]
**Title:** Split TimelineAPI.swift - 667 lines  
**Blocked By:** I Do Blueprint-0t9

### 2. I Do Blueprint-gsw [P2]
**Title:** Split DocumentsAPI.swift - 747 lines  
**Blocked By:** I Do Blueprint-0t9

### 3. I Do Blueprint-hjp [P2]
**Title:** Split VisualPlanningSearchService.swift - 604 lines  
**Blocked By:** I Do Blueprint-0t9

### 4. I Do Blueprint-yzn [P2]
**Title:** Split AlertPresenter.swift - 556 lines  
**Blocked By:** I Do Blueprint-0t9

## Open High-Priority Issues

### Testing & Quality (P2)

#### I Do Blueprint-s2q [P2]
**Title:** Add API Layer Integration Tests  
**Tags:** api, medium, testing  
**Status:** Open

**Description:**
Add integration tests for API layer components to ensure proper integration with Supabase backend.

**Priority:** Medium
**Complexity:** Medium
**Estimated Effort:** 2-3 sessions

#### I Do Blueprint-bji [P2]
**Title:** Add Domain Service Unit Tests  
**Tags:** domain-services, medium, testing  
**Status:** Open

**Description:**
Add comprehensive unit tests for domain services (BudgetAggregationService, CollaborationPermissionService, etc.)

**Priority:** Medium
**Complexity:** Medium
**Benefits:**
- Better test coverage
- Regression prevention
- Documentation through tests

### Code Quality (P2)

#### I Do Blueprint-11e [P2]
**Title:** Consolidate Import Services  
**Tags:** import, medium, refactoring  
**Status:** Open

**Description:**
Consolidate CSV/XLSX import services for better code reuse and maintainability.

**Context:**
- Multiple import services (GuestImport, VendorImport)
- Shared patterns for parsing and validation
- Opportunity for abstraction

#### I Do Blueprint-09l [P2]
**Title:** Cache Strategy Consolidation and Monitoring  
**Tags:** caching, medium, performance  
**Status:** Open

**Description:**
Consolidate cache strategies and add monitoring for cache hit rates and performance.

**Planned Features:**
- Centralized cache monitoring dashboard
- Automatic hit rate tracking
- Cache size limits with LRU eviction
- Memory pressure monitoring
- Redis integration potential

## Completed Epics

### I Do Blueprint-mu0 [P1] [CLOSED]
**Title:** View Complexity Hotspots - Critical Refactoring  
**Status:** Closed  
**Priority:** P1  
**Tags:** code-quality, critical, refactoring, views

**Description:**
Epic for reducing view complexity across the codebase.

**Completed Sub-Tasks:**
1. ✅ I Do Blueprint-6g9 - ExpenseCategoriesView (694 lines, nesting 8)
2. ✅ I Do Blueprint-5bx - GuestCSVImportView (633 lines, nesting 9)
3. ✅ I Do Blueprint-8v9 - MoneyReceivedView (592 lines, nesting 7)
4. ✅ I Do Blueprint-qw9 - DocumentsView (535 lines, nesting 9)
5. ✅ I Do Blueprint-idi - VisualPlanningMainView (complexity 61, nesting 9)
6. ✅ I Do Blueprint-7wd - NoteModal (590 lines, complexity 58)
7. ✅ I Do Blueprint-fhh - SettingsView (nesting level 10)
8. ✅ I Do Blueprint-563 - EditVendorSheetV2 (nesting level 13)

**Impact:**
- Significantly improved code maintainability
- Reduced cognitive complexity
- Better separation of concerns
- Easier to test and modify

### I Do Blueprint-ded [P2] [CLOSED]
**Title:** Standardize Error Handling Across Stores  
**Status:** Closed  
**Priority:** P2

**Completed Phases:**
1. ✅ High-priority stores (I Do Blueprint-8pl)
2. ✅ Medium-priority stores (I Do Blueprint-2qj)
3. ✅ Remaining 5 files (I Do Blueprint-8tl)
4. ✅ Final 2 files (I Do Blueprint-aip)

**Pattern Established:**
```swift
await handleError(error, operation: "operation", context: [...]) { [weak self] in
    await self?.retry()
}
```

## Open Low-Priority Issues (P3)

### I Do Blueprint-06m [P3]
**Title:** Reorganize Assets by Feature  
**Tags:** assets, low, organization

### I Do Blueprint-dqg [P3]
**Title:** Modernize Python Scripts  
**Tags:** low, scripts, tooling

### I Do Blueprint-d20 [P3]
**Title:** Optimize Debug Logging Verbosity  
**Tags:** logging, low, performance

### I Do Blueprint-vd9 [P3]
**Title:** Clean Up Preview Code TODOs  
**Tags:** cleanup, low, previews

## Recurring Themes

### Code Quality Focus
- ✅ View complexity reduction (completed)
- ✅ Error handling standardization (completed)
- 🔄 Large file decomposition (in progress)
- 🔄 Test coverage improvements (planned)

### Architecture Patterns
- V2 naming for new architecture
- Repository pattern everywhere
- Domain services for complex logic
- Cache strategy per domain
- Composition over delegation

### Performance Optimization
- Cache consolidation needed
- Monitoring improvements planned
- N+1 query prevention (ongoing)
- RLS policy optimization (completed Oct 2025)

### Testing Improvements
- Mock repository refactoring needed
- Integration tests planned
- Domain service tests planned
- Better test coverage overall

## Issue Management Best Practices

### Using Beads Commands
```bash
# Find work
bd ready                          # Show ready issues
bd list --status=open             # All open issues
bd blocked                        # Show blocked issues

# Work on issues
bd update <id> --status=in_progress
bd close <id>                     # Mark complete
bd close <id1> <id2> ...         # Close multiple
bd sync                           # Sync with git

# Create work
bd create --title="..." --type=task --priority=2
bd dep add <issue> <depends-on>  # Add dependency
```

### Priority Levels
- **P0-P1:** Critical/High - Do immediately
- **P2:** Medium - Normal priority
- **P3-P4:** Low/Backlog - When time permits

### Workflow
1. Check `bd ready` for available work
2. Use `bd update <id> --status=in_progress` to claim
3. Complete the work
4. Use `bd close <id>` to mark done
5. Run `bd sync` to push changes

## Technical Debt Tracking

### High Impact
1. ✅ Error handling standardization (DONE)
2. ✅ View complexity reduction (DONE)
3. 🔄 Large file decomposition (IN PROGRESS)
4. 📋 Test coverage improvements (PLANNED)

### Medium Impact
1. 📋 Cache monitoring and optimization
2. 📋 Import service consolidation
3. 📋 MockBudgetRepository size reduction

### Low Impact
1. 📋 Asset reorganization
2. 📋 Python script modernization
3. 📋 Debug logging optimization

## References
- Beads workflow: Session startup hook
- Total migrations: 300+
- Test files: 20+ test classes
- Mock repositories: 12 separate files
- Domain services: 6 actors
- V2 stores: 11 stores (some with composition)