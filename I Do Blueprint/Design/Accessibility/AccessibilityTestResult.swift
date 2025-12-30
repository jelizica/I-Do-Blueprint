//
//  AccessibilityTestResult.swift
//  I Do Blueprint
//
//  Test result structures for accessibility audits
//

import SwiftUI

/// Result of an accessibility test for a color combination
struct AccessibilityTestResult {
    let name: String
    let foreground: Color
    let background: Color
    let contrastRatio: Double
    let meetsAA: Bool
    let meetsAAA: Bool
    let meetsLargeTextAA: Bool
    let category: String

    var status: String {
        if meetsAAA {
            return "✅ AAA"
        } else if meetsAA {
            return "✅ AA"
        } else if meetsLargeTextAA {
            return "⚠️ Large Text Only"
        } else {
            return "❌ FAIL"
        }
    }

    var formattedRatio: String {
        return String(format: "%.2f:1", contrastRatio)
    }
}

/// Helper for creating test results
enum AccessibilityTestHelper {
    /// Test a single color pair for accessibility compliance
    static func testColorPair(
        name: String,
        foreground: Color,
        background: Color,
        category: String
    ) -> AccessibilityTestResult {
        let fgNS = NSColor(foreground)
        let bgNS = NSColor(background)

        let ratio = AppColors.contrastRatio(between: fgNS, and: bgNS)
        let meetsAA = ratio >= 4.5
        let meetsAAA = ratio >= 7.0
        let meetsLargeTextAA = ratio >= 3.0

        return AccessibilityTestResult(
            name: name,
            foreground: foreground,
            background: background,
            contrastRatio: ratio,
            meetsAA: meetsAA,
            meetsAAA: meetsAAA,
            meetsLargeTextAA: meetsLargeTextAA,
            category: category
        )
    }
}
