//
//  EnhancedBudgetCategory.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Enhanced category with projected spending calculations
//

import Foundation

struct EnhancedBudgetCategory {
    let category: BudgetCategory
    let projectedSpending: Double // All expenses (including pending)
    let actualSpending: Double // Only paid expenses

    // Computed properties for UI display
    var projectedPercentageSpent: Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return (projectedSpending / category.allocatedAmount) * 100
    }

    var actualPercentageSpent: Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return (actualSpending / category.allocatedAmount) * 100
    }

    var projectedRemainingAmount: Double {
        category.allocatedAmount - projectedSpending
    }

    var actualRemainingAmount: Double {
        category.allocatedAmount - actualSpending
    }

    var isProjectedOverBudget: Bool {
        projectedSpending > category.allocatedAmount
    }

    var isActualOverBudget: Bool {
        actualSpending > category.allocatedAmount
    }

    var pendingAmount: Double {
        projectedSpending - actualSpending
    }

    var isOverBudget: Bool {
        projectedSpending > category.allocatedAmount
    }
}
