//
//  ColorAuditSemantic.swift
//  I Do Blueprint
//
//  Semantic color accessibility audits
//

import SwiftUI

/// Audits Semantic color combinations for WCAG compliance
enum ColorAuditSemantic {
    /// Audit Semantic color combinations
    static func audit() -> [AccessibilityTestResult] {
        var results: [AccessibilityTestResult] = []

        let lightBg = Color(nsColor: .windowBackgroundColor)
        let cardBg = AppColors.cardBackground

        // Semantic Status Colors
        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Success on Light Background",
            foreground: AppColors.success,
            background: lightBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Success on Card Background",
            foreground: AppColors.success,
            background: cardBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Warning on Light Background",
            foreground: AppColors.warning,
            background: lightBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Warning on Card Background",
            foreground: AppColors.warning,
            background: cardBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Error on Light Background",
            foreground: AppColors.error,
            background: lightBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Error on Card Background",
            foreground: AppColors.error,
            background: cardBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Info on Light Background",
            foreground: AppColors.info,
            background: lightBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Info on Card Background",
            foreground: AppColors.info,
            background: cardBg,
            category: "Semantic - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Primary Text on Light Background",
            foreground: AppColors.textPrimary,
            background: lightBg,
            category: "Semantic - Text"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Secondary Text on Light Background",
            foreground: AppColors.textSecondary,
            background: lightBg,
            category: "Semantic - Text"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Semantic: Tertiary Text on Light Background",
            foreground: AppColors.textTertiary,
            background: lightBg,
            category: "Semantic - Text"
        ))

        return results
    }
}
