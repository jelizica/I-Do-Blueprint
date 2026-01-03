---
title: I Do Blueprint - Project Overview
type: note
permalink: projects/i-do-blueprint/i-do-blueprint-project-overview
tags:
- overview
- status
- architecture
- beads-issues
---

# I Do Blueprint - macOS Wedding Planning Application

## Project Status (as of 2025-12-29)

**Platform:** macOS 13.0+  
**Language:** Swift 5.9+ with strict concurrency  
**Backend:** Supabase (PostgreSQL with Row Level Security)  
**Architecture:** MVVM with Repository Pattern, Domain Services, Dependency Injection

### Active Development Focus

Based on beads issue tracking, the project is currently focused on:

1. **Error Handling Standardization** (P2) - Nearly complete
   - Issue: I Do Blueprint-aip (in_progress)
   - Only 2 files remaining: OnboardingStoreV2.swift and one other
   - Completed: High-priority and medium-priority stores standardized
   - Pattern: Using `handleError` extension for consistent error handling

2. **Code Quality - View Complexity** (P1) - Epic completed
   - Issue: I Do Blueprint-mu0 (closed)
   - Successfully refactored critical view files
   - Reduced nesting levels and line counts across multiple views

3. **Large Service Files Decomposition** (P2) - In progress
   - Epic: I Do Blueprint-0t9 (open)
   - Blocking 4 other tasks: TimelineAPI, DocumentsAPI, VisualPlanningSearchService, AlertPresenter
   - MockBudgetRepository reduction in progress (I Do Blueprint-0wo)

### Recent Accomplishments

**Last 24 hours:** 14 commits, 52 total changes
- Completed error handling standardization for medium-priority stores
- Completed refactoring of critical view complexity hotspots
- Merged wedding ceremony/reception categories in budget system

### Testing & Quality Metrics

- **Total Issues:** 35 (13 open, 2 in progress, 4 blocked, 20 closed)
- **Ready to Work:** 9 issues
- **Average Lead Time:** 1.8 hours

### Known Architectural Patterns

1. **V2 Naming Convention** - New architecture stores use `V2` suffix
2. **Store Composition** - BudgetStoreV2 owns 6 specialized sub-stores
3. **Repository Pattern** - All data access through protocol-based repositories
4. **Domain Services** - Complex business logic separated into actor-based services
5. **Cache Invalidation Strategy** - Per-domain cache strategies for maintainable caching