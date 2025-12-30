//
//  ColorAuditGuest.swift
//  I Do Blueprint
//
//  Guest color accessibility audits
//

import SwiftUI

/// Audits Guest-specific color combinations for WCAG compliance
enum ColorAuditGuest {
    /// Audit Guest color combinations
    static func audit() -> [AccessibilityTestResult] {
        var results: [AccessibilityTestResult] = []

        let lightBg = Color(nsColor: .windowBackgroundColor)
        let cardBg = AppColors.cardBackground

        // Guest Status Colors
        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Confirmed on Light Background",
            foreground: AppColors.Guest.confirmed,
            background: lightBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Confirmed on Card Background",
            foreground: AppColors.Guest.confirmed,
            background: cardBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Pending on Light Background",
            foreground: AppColors.Guest.pending,
            background: lightBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Pending on Card Background",
            foreground: AppColors.Guest.pending,
            background: cardBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Declined on Light Background",
            foreground: AppColors.Guest.declined,
            background: lightBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Declined on Card Background",
            foreground: AppColors.Guest.declined,
            background: cardBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Invited on Light Background",
            foreground: AppColors.Guest.invited,
            background: lightBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Invited on Card Background",
            foreground: AppColors.Guest.invited,
            background: cardBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Plus One on Light Background",
            foreground: AppColors.Guest.plusOne,
            background: lightBg,
            category: "Guest - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Guest: Plus One on Card Background",
            foreground: AppColors.Guest.plusOne,
            background: cardBg,
            category: "Guest - Status"
        ))

        return results
    }
}
