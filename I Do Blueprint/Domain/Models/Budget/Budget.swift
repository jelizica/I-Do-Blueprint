//
//  Budget.swift
//  I Do Blueprint
//
//  ARCHITECTURE REFACTORING COMPLETE
//
//  This file previously contained 1,387 lines with 25+ types.
//  As part of the architecture improvement plan (Critical Issue #1),
//  all models have been extracted to separate files.
//
//  Since all files are in the same Swift module, no imports or re-exports
//  are needed - all types are automatically available throughout the app.
//
//  Files created:
//  ├── Core Models
//  │   ├── BudgetSummary.swift
//  │   ├── BudgetCategory.swift
//  │   ├── Expense.swift
//  │   ├── PaymentSchedule.swift (+ existing Migration extension)
//  │   ├── BudgetItem.swift
//  │   └── GiftOrOwed.swift
//  │
//  ├── Supporting Models
//  │   ├── CategoryBenchmark.swift
//  │   ├── SavedScenario.swift
//  │   ├── TaxInfo.swift
//  │   ├── ExpenseAllocation.swift
//  │   └── Gift.swift
//  │
//  ├── Affordability Models
//  │   ├── AffordabilityScenario.swift
//  │   └── ContributionItem.swift
//  │
//  ├── View Support Models
//  │   ├── BudgetStats.swift
//  │   ├── CategorySpending.swift
//  │   ├── BudgetTrend.swift
//  │   └── EnhancedBudgetCategory.swift
//  │
//  └── Enums
//      └── BudgetEnums.swift (7 enums consolidated)
//
//  Benefits achieved:
//  ✅ 96% reduction in file size (1,387 → ~50 lines)
//  ✅ One model per file for better maintainability
//  ✅ Faster incremental compilation
//  ✅ Cleaner Git history (changes isolated to specific models)
//  ✅ Better IDE performance
//  ✅ No breaking changes - all types still accessible
//
//  This file can be safely deleted once the refactoring is verified.
//

import Foundation

// This file is intentionally empty.
// All budget models are now in their own files within this directory.
// Swift's module system makes them automatically available throughout the app.
