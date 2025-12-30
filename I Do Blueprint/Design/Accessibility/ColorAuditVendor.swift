//
//  ColorAuditVendor.swift
//  I Do Blueprint
//
//  Vendor color accessibility audits
//

import SwiftUI

/// Audits Vendor-specific color combinations for WCAG compliance
enum ColorAuditVendor {
    /// Audit Vendor color combinations
    static func audit() -> [AccessibilityTestResult] {
        var results: [AccessibilityTestResult] = []

        let lightBg = Color(nsColor: .windowBackgroundColor)
        let cardBg = AppColors.cardBackground

        // Vendor Status Colors
        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Booked on Light Background",
            foreground: AppColors.Vendor.booked,
            background: lightBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Booked on Card Background",
            foreground: AppColors.Vendor.booked,
            background: cardBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Pending on Light Background",
            foreground: AppColors.Vendor.pending,
            background: lightBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Pending on Card Background",
            foreground: AppColors.Vendor.pending,
            background: cardBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Contacted on Light Background",
            foreground: AppColors.Vendor.contacted,
            background: lightBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Contacted on Card Background",
            foreground: AppColors.Vendor.contacted,
            background: cardBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Not Contacted on Light Background",
            foreground: AppColors.Vendor.notContacted,
            background: lightBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Not Contacted on Card Background",
            foreground: AppColors.Vendor.notContacted,
            background: cardBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Contract on Light Background",
            foreground: AppColors.Vendor.contract,
            background: lightBg,
            category: "Vendor - Status"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Vendor: Contract on Card Background",
            foreground: AppColors.Vendor.contract,
            background: cardBg,
            category: "Vendor - Status"
        ))

        return results
    }
}
