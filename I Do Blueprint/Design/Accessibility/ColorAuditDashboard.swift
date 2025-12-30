//
//  ColorAuditDashboard.swift
//  I Do Blueprint
//
//  Dashboard color accessibility audits
//

import SwiftUI

/// Audits Dashboard-specific color combinations for WCAG compliance
enum ColorAuditDashboard {
    /// Audit Dashboard color combinations
    static func audit() -> [AccessibilityTestResult] {
        var results: [AccessibilityTestResult] = []

        let darkBg = AppColors.Dashboard.mainBackground
        let creamBg = AppColors.Dashboard.budgetVisualizationCard

        // Quick Action Colors on Dark Background
        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Task Action on Dark",
            foreground: AppColors.Dashboard.taskAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Note Action on Dark",
            foreground: AppColors.Dashboard.noteAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Event Action on Dark",
            foreground: AppColors.Dashboard.eventAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Guest Action on Dark",
            foreground: AppColors.Dashboard.guestAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))

        // Card Background Colors with Text
        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Budget Card with Black Text",
            foreground: .black,
            background: AppColors.Dashboard.budgetCard,
            category: "Dashboard - Cards"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: RSVP Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.rsvpCard,
            category: "Dashboard - Cards"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Vendor Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.vendorCard,
            category: "Dashboard - Cards"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Guest Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.guestCard,
            category: "Dashboard - Cards"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Countdown Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.countdownCard,
            category: "Dashboard - Cards"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Budget Viz Card with Black Text",
            foreground: .black,
            background: creamBg,
            category: "Dashboard - Cards"
        ))

        results.append(AccessibilityTestHelper.testColorPair(
            name: "Dashboard: Task Progress Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.taskProgressCard,
            category: "Dashboard - Cards"
        ))

        return results
    }
}
