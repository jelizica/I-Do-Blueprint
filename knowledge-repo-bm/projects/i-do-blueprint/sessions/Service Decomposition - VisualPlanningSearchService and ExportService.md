---
title: Service Decomposition - VisualPlanningSearchService and ExportService
type: note
permalink: projects/i-do-blueprint/sessions/service-decomposition-visual-planning-search-service-and-export-service
tags:
- refactoring
- services
- domain-services
- export
- search
- visual-planning
---

# Service Decomposition Session - December 29, 2025

## Overview
Completed decomposition of two large service files following the Domain Services pattern established in the codebase. Both services were split into focused, single-responsibility components while maintaining backward compatibility.

## VisualPlanningSearchService.swift (604 lines → 8 files)

### Files Created
1. **MoodBoardSearchService.swift** - Domain-specific search for mood boards
2. **ColorPaletteSearchService.swift** - Domain-specific search for color palettes
3. **SeatingChartSearchService.swift** - Domain-specific search for seating charts
4. **StylePreferencesSearchService.swift** - Domain-specific search for style preferences
5. **SearchResultTransformer.swift** - Relevance scoring and sorting
6. **ColorComparisonHelper.swift** - HSB-based color similarity
7. **SearchSuggestionService.swift** - Smart search suggestions
8. **SavedSearchManager.swift** - Saved search persistence with UserDefaults
9. **SearchModels.swift** - Data models (SearchResults, SearchFilters, QuickFilter, SavedSearch)

### Architecture
- Main service orchestrates domain-specific services
- Parallel search execution using async/await
- Each domain service is an actor for thread safety (later changed to @MainActor for ImageRenderer compatibility)
- Saved searches managed separately with ObservableObject pattern

### Key Improvements
- Reduced main file from 604 lines to ~150 lines
- Better testability with isolated services
- Clearer separation of concerns
- Reusable search components

## ExportService.swift (475 lines → 6 files)

### Files Created
1. **MoodBoardExportRenderer.swift** - Renders mood boards to NSImage
2. **ColorPaletteExportRenderer.swift** - Renders color palettes to NSImage
3. **SeatingChartExportRenderer.swift** - Renders seating charts to NSImage
4. **PDFExportService.swift** - PDF generation for all content types
5. **ImageExportService.swift** - PNG/JPEG generation for all content types
6. **FileExportHelper.swift** - File saving and sharing utilities

### Shared Models Extended
- Added `ExportQuality` enum to `ExportTemplate.swift` (low/medium/high/ultra DPI)
- Extended `ExportError` with additional cases: `renderingFailed`, `fileCreationFailed`, `invalidData`

### Architecture
- Main service coordinates format selection
- PDFExportService handles all PDF operations
- ImageExportService handles all image operations
- Renderer services convert content to NSImage
- FileExportHelper provides system integration

### Key Improvements
- Reduced main file from 475 lines to ~100 lines
- Format-specific services for better organization
- Reusable renderer components
- Cleaner separation between rendering and file generation

## Technical Challenges Resolved

### 1. Actor Isolation with ImageRenderer
**Problem**: ImageRenderer requires @MainActor but services were initially defined as actors
**Solution**: Changed renderer services from `actor` to `@MainActor class`

### 2. Duplicate Type Definitions
**Problem**: ExportFormat and ExportError already existed in other files
**Solution**: 
- Removed duplicate ExportModels.swift file
- Extended existing ExportError enum with new cases
- Added ExportQuality to ExportTemplate.swift

### 3. View Compatibility
**Problem**: ExportInterfaceView expected nested types (ExportService.ExportFormat)
**Solution**: Updated view to use top-level types directly

## Testing
- All changes verified with Xcode build
- No breaking changes to existing API
- Backward compatibility maintained

## Beads Progress
- Completed issues: I Do Blueprint-hjp (VisualPlanningSearchService), I Do Blueprint-5g5 (ExportService)
- Closed epic: I Do Blueprint-0t9 (Large Service Files Decomposition)
- Overall completion: 31/39 issues (79.5%)
- Average lead time: 2.5 hours

## Next Steps
- Continue with remaining ready issues
- Consider adding unit tests for new services
- Document export quality recommendations for different use cases
