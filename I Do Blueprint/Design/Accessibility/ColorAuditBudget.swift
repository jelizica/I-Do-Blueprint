//
//  ColorAuditBudget.swift
//  I Do Blueprint
//
//  Budget color accessibility audits
//

import SwiftUI

/// Audits Budget-specific color combinations for WCAG compliance
enum ColorAuditBudget {
    /// Audit Budget color combinations
    static func audit() -> [AccessibilityTestResult] {
        var results: [AccessibilityTestResult] = []

        let lightBg = Color(nsColor: .windowBackgroundColor)
        let cardBg = AppColors.cardBackground

        // Budget Status Colors on Various Backgrounds
        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Income on Light Background",
            foreground: AppColors.Budget.income,
            background: lightBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Income on Card Background",
            foreground: AppColors.Budget.income,
            background: cardBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Expense on Light Background",
            foreground: AppColors.Budget.expense,
            background: lightBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Expense on Card Background",
            foreground: AppColors.Budget.expense,
            background: cardBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Pending on Light Background",
            foreground: AppColors.Budget.pending,
            background: lightBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Pending on Card Background",
            foreground: AppColors.Budget.pending,
            background: cardBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Allocated on Light Background",
            foreground: AppColors.Budget.allocated,
            background: lightBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Allocated on Card Background",
            foreground: AppColors.Budget.allocated,
            background: cardBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Over Budget on Light Background",
            foreground: AppColors.Budget.overBudget,
            background: lightBg,
            category: "Budget - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Budget: Under Budget on Light Background",
            foreground: AppColors.Budget.underBudget,
            background: lightBg,
            category: "Budget - Status"
        ))

        return results
    }
}
