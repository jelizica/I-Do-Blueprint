//
//  AccessibilityAudit.swift
//  I Do Blueprint
//
//  WCAG AA Accessibility Audit for Color System
//  Created for JES-54
//

import SwiftUI
import AppKit

/// Comprehensive accessibility audit for all color combinations in the app
/// Tests WCAG AA compliance (4.5:1 for normal text, 3:1 for large text)
struct AccessibilityAudit {
    
    // MARK: - Test Results
    
    struct TestResult {
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
    
    // MARK: - Audit Methods
    
    /// Run complete accessibility audit for all color combinations
    static func runCompleteAudit() -> [TestResult] {
        var results: [TestResult] = []
        
        // Dashboard Colors
        results.append(contentsOf: auditDashboardColors())
        
        // Budget Colors
        results.append(contentsOf: auditBudgetColors())
        
        // Guest Colors
        results.append(contentsOf: auditGuestColors())
        
        // Vendor Colors
        results.append(contentsOf: auditVendorColors())
        
        // Semantic Colors
        results.append(contentsOf: auditSemanticColors())
        
        return results
    }
    
    /// Audit Dashboard color combinations
    static func auditDashboardColors() -> [TestResult] {
        var results: [TestResult] = []
        
        let darkBg = AppColors.Dashboard.mainBackground
        let creamBg = AppColors.Dashboard.budgetVisualizationCard
        
        // Quick Action Colors on Dark Background
        results.append(testColorPair(
            name: "Dashboard: Task Action on Dark",
            foreground: AppColors.Dashboard.taskAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Note Action on Dark",
            foreground: AppColors.Dashboard.noteAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Event Action on Dark",
            foreground: AppColors.Dashboard.eventAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Guest Action on Dark",
            foreground: AppColors.Dashboard.guestAction,
            background: darkBg,
            category: "Dashboard - Quick Actions"
        ))
        
        // Card Background Colors with Text
        results.append(testColorPair(
            name: "Dashboard: Budget Card with Black Text",
            foreground: .black,
            background: AppColors.Dashboard.budgetCard,
            category: "Dashboard - Cards"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: RSVP Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.rsvpCard,
            category: "Dashboard - Cards"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Vendor Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.vendorCard,
            category: "Dashboard - Cards"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Guest Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.guestCard,
            category: "Dashboard - Cards"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Countdown Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.countdownCard,
            category: "Dashboard - Cards"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Budget Viz Card with Black Text",
            foreground: .black,
            background: creamBg,
            category: "Dashboard - Cards"
        ))
        
        results.append(testColorPair(
            name: "Dashboard: Task Progress Card with White Text",
            foreground: .white,
            background: AppColors.Dashboard.taskProgressCard,
            category: "Dashboard - Cards"
        ))
        
        return results
    }
    
    /// Audit Budget color combinations
    static func auditBudgetColors() -> [TestResult] {
        var results: [TestResult] = []
        
        let lightBg = Color(nsColor: .windowBackgroundColor)
        let darkBg = Color(nsColor: .controlBackgroundColor)
        let cardBg = AppColors.cardBackground
        
        // Budget Status Colors on Various Backgrounds
        results.append(testColorPair(
            name: "Budget: Income on Light Background",
            foreground: AppColors.Budget.income,
            background: lightBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Income on Card Background",
            foreground: AppColors.Budget.income,
            background: cardBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Expense on Light Background",
            foreground: AppColors.Budget.expense,
            background: lightBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Expense on Card Background",
            foreground: AppColors.Budget.expense,
            background: cardBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Pending on Light Background",
            foreground: AppColors.Budget.pending,
            background: lightBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Pending on Card Background",
            foreground: AppColors.Budget.pending,
            background: cardBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Allocated on Light Background",
            foreground: AppColors.Budget.allocated,
            background: lightBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Allocated on Card Background",
            foreground: AppColors.Budget.allocated,
            background: cardBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Over Budget on Light Background",
            foreground: AppColors.Budget.overBudget,
            background: lightBg,
            category: "Budget - Status"
        ))
        
        results.append(testColorPair(
            name: "Budget: Under Budget on Light Background",
            foreground: AppColors.Budget.underBudget,
            background: lightBg,
            category: "Budget - Status"
        ))
        
        return results
    }
    
    /// Audit Guest color combinations
    static func auditGuestColors() -> [TestResult] {
        var results: [TestResult] = []
        
        let lightBg = Color(nsColor: .windowBackgroundColor)
        let cardBg = AppColors.cardBackground
        
        // Guest Status Colors
        results.append(testColorPair(
            name: "Guest: Confirmed on Light Background",
            foreground: AppColors.Guest.confirmed,
            background: lightBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Confirmed on Card Background",
            foreground: AppColors.Guest.confirmed,
            background: cardBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Pending on Light Background",
            foreground: AppColors.Guest.pending,
            background: lightBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Pending on Card Background",
            foreground: AppColors.Guest.pending,
            background: cardBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Declined on Light Background",
            foreground: AppColors.Guest.declined,
            background: lightBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Declined on Card Background",
            foreground: AppColors.Guest.declined,
            background: cardBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Invited on Light Background",
            foreground: AppColors.Guest.invited,
            background: lightBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Invited on Card Background",
            foreground: AppColors.Guest.invited,
            background: cardBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Plus One on Light Background",
            foreground: AppColors.Guest.plusOne,
            background: lightBg,
            category: "Guest - Status"
        ))
        
        results.append(testColorPair(
            name: "Guest: Plus One on Card Background",
            foreground: AppColors.Guest.plusOne,
            background: cardBg,
            category: "Guest - Status"
        ))
        
        return results
    }
    
    /// Audit Vendor color combinations
    static func auditVendorColors() -> [TestResult] {
        var results: [TestResult] = []
        
        let lightBg = Color(nsColor: .windowBackgroundColor)
        let cardBg = AppColors.cardBackground
        
        // Vendor Status Colors
        results.append(testColorPair(
            name: "Vendor: Booked on Light Background",
            foreground: AppColors.Vendor.booked,
            background: lightBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Booked on Card Background",
            foreground: AppColors.Vendor.booked,
            background: cardBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Pending on Light Background",
            foreground: AppColors.Vendor.pending,
            background: lightBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Pending on Card Background",
            foreground: AppColors.Vendor.pending,
            background: cardBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Contacted on Light Background",
            foreground: AppColors.Vendor.contacted,
            background: lightBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Contacted on Card Background",
            foreground: AppColors.Vendor.contacted,
            background: cardBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Not Contacted on Light Background",
            foreground: AppColors.Vendor.notContacted,
            background: lightBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Not Contacted on Card Background",
            foreground: AppColors.Vendor.notContacted,
            background: cardBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Contract on Light Background",
            foreground: AppColors.Vendor.contract,
            background: lightBg,
            category: "Vendor - Status"
        ))
        
        results.append(testColorPair(
            name: "Vendor: Contract on Card Background",
            foreground: AppColors.Vendor.contract,
            background: cardBg,
            category: "Vendor - Status"
        ))
        
        return results
    }
    
    /// Audit Semantic color combinations
    static func auditSemanticColors() -> [TestResult] {
        var results: [TestResult] = []
        
        let lightBg = Color(nsColor: .windowBackgroundColor)
        let cardBg = AppColors.cardBackground
        
        // Semantic Status Colors
        results.append(testColorPair(
            name: "Semantic: Success on Light Background",
            foreground: AppColors.success,
            background: lightBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Success on Card Background",
            foreground: AppColors.success,
            background: cardBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Warning on Light Background",
            foreground: AppColors.warning,
            background: lightBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Warning on Card Background",
            foreground: AppColors.warning,
            background: cardBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Error on Light Background",
            foreground: AppColors.error,
            background: lightBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Error on Card Background",
            foreground: AppColors.error,
            background: cardBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Info on Light Background",
            foreground: AppColors.info,
            background: lightBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Info on Card Background",
            foreground: AppColors.info,
            background: cardBg,
            category: "Semantic - Status"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Primary Text on Light Background",
            foreground: AppColors.textPrimary,
            background: lightBg,
            category: "Semantic - Text"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Secondary Text on Light Background",
            foreground: AppColors.textSecondary,
            background: lightBg,
            category: "Semantic - Text"
        ))
        
        results.append(testColorPair(
            name: "Semantic: Tertiary Text on Light Background",
            foreground: AppColors.textTertiary,
            background: lightBg,
            category: "Semantic - Text"
        ))
        
        return results
    }
    
    // MARK: - Helper Methods
    
    /// Test a single color pair for accessibility compliance
    private static func testColorPair(
        name: String,
        foreground: Color,
        background: Color,
        category: String
    ) -> TestResult {
        let fgNS = NSColor(foreground)
        let bgNS = NSColor(background)
        
        let ratio = AppColors.contrastRatio(between: fgNS, and: bgNS)
        let meetsAA = ratio >= 4.5
        let meetsAAA = ratio >= 7.0
        let meetsLargeTextAA = ratio >= 3.0
        
        return TestResult(
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
    
    // MARK: - Report Generation
    
    /// Generate a comprehensive markdown report of audit results
    static func generateMarkdownReport() -> String {
        let results = runCompleteAudit()
        
        var report = """
        # Color Accessibility Audit Report
        ## WCAG AA Compliance Testing
        
        **Generated:** \(Date().formatted(date: .long, time: .shortened))
        **Issue:** JES-54
        **Standard:** WCAG 2.1 Level AA
        
        ---
        
        ## Executive Summary
        
        """
        
        let totalTests = results.count
        let passedAA = results.filter { $0.meetsAA }.count
        let passedAAA = results.filter { $0.meetsAAA }.count
        let largeTextOnly = results.filter { $0.meetsLargeTextAA && !$0.meetsAA }.count
        let failed = results.filter { !$0.meetsLargeTextAA }.count
        
        let aaPercentage = Double(passedAA) / Double(totalTests) * 100
        let aaaPercentage = Double(passedAAA) / Double(totalTests) * 100
        
        report += """
        - **Total Tests:** \(totalTests)
        - **WCAG AA Passed:** \(passedAA) (\(String(format: "%.1f", aaPercentage))%)
        - **WCAG AAA Passed:** \(passedAAA) (\(String(format: "%.1f", aaaPercentage))%)
        - **Large Text Only:** \(largeTextOnly)
        - **Failed:** \(failed)
        
        ### Compliance Status
        
        """
        
        if failed == 0 {
            report += "✅ **FULLY COMPLIANT** - All color combinations meet WCAG AA standards!\n\n"
        } else if aaPercentage >= 95 {
            report += "⚠️ **MOSTLY COMPLIANT** - \(failed) color combination(s) need attention.\n\n"
        } else {
            report += "❌ **NON-COMPLIANT** - Multiple color combinations require remediation.\n\n"
        }
        
        // Group results by category
        let categories = Dictionary(grouping: results, by: { $0.category })
        
        report += """
        ---
        
        ## Detailed Results by Category
        
        """
        
        for (category, categoryResults) in categories.sorted(by: { $0.key < $1.key }) {
            report += """
            
            ### \(category)
            
            | Color Combination | Contrast Ratio | Status |
            |-------------------|----------------|--------|
            
            """
            
            for result in categoryResults.sorted(by: { $0.name < $1.name }) {
                report += "| \(result.name) | \(result.formattedRatio) | \(result.status) |\n"
            }
        }
        
        // Failures section
        let failures = results.filter { !$0.meetsAA }
        if !failures.isEmpty {
            report += """
            
            ---
            
            ## ⚠️ Remediation Required
            
            The following color combinations do not meet WCAG AA standards:
            
            """
            
            for failure in failures {
                report += """
                
                ### \(failure.name)
                - **Contrast Ratio:** \(failure.formattedRatio)
                - **Required:** 4.5:1 (AA) or 3.0:1 (Large Text)
                - **Status:** \(failure.status)
                
                **Recommendations:**
                """
                
                if failure.meetsLargeTextAA {
                    report += "\n- ✅ Use only for large text (18pt+ or 14pt+ bold)\n"
                    report += "- Consider darkening foreground or lightening background for normal text\n"
                } else {
                    report += "\n- ❌ Not suitable for any text size\n"
                    report += "- **Action Required:** Adjust color values to meet minimum 3.0:1 ratio\n"
                    
                    // Calculate suggested adjustments
                    let targetRatio = 4.5
                    let currentRatio = failure.contrastRatio
                    let adjustment = (targetRatio / currentRatio) * 100
                    report += "- Suggested: Increase contrast by approximately \(String(format: "%.0f", adjustment - 100))%\n"
                }
            }
        }
        
        report += """
        
        ---
        
        ## Testing Methodology
        
        ### Automated Testing
        - Used built-in `AppColors.meetsContrastRequirements()` helper
        - Tested all feature-specific color namespaces (Dashboard, Budget, Guest, Vendor)
        - Tested semantic colors on various backgrounds
        - Calculated contrast ratios using WCAG 2.1 formula
        
        ### Standards Applied
        - **WCAG AA (Normal Text):** 4.5:1 minimum contrast ratio
        - **WCAG AA (Large Text):** 3.0:1 minimum contrast ratio
        - **WCAG AAA (Normal Text):** 7.0:1 minimum contrast ratio
        - **Large Text Definition:** 18pt+ or 14pt+ bold
        
        ### Color Combinations Tested
        1. **Dashboard Colors:** Quick actions and card backgrounds
        2. **Budget Colors:** Status indicators on various backgrounds
        3. **Guest Colors:** RSVP status indicators
        4. **Vendor Colors:** Vendor status indicators
        5. **Semantic Colors:** General UI status and text colors
        
        ---
        
        ## Recommendations
        
        ### Best Practices
        1. ✅ Use semantic colors for consistent accessibility
        2. ✅ Test new colors before implementation
        3. ✅ Provide alternative indicators (icons, patterns) alongside color
        4. ✅ Support system dark/light mode preferences
        5. ✅ Test with color blindness simulators
        
        ### Implementation Guidelines
        - Always use `AppColors.meetsContrastRequirements()` before adding new colors
        - Document any exceptions with clear justification
        - Consider adding automated tests to CI/CD pipeline
        - Regularly audit colors when design system changes
        
        ---
        
        ## Next Steps
        
        1. ✅ Review this report with design team
        2. ⏳ Address any failing color combinations
        3. ⏳ Conduct manual VoiceOver testing
        4. ⏳ Test with high contrast mode
        5. ⏳ Test with color blindness simulators
        6. ⏳ Update documentation with accessibility guidelines
        
        ---
        
        **Report Generated by:** AccessibilityAudit.swift
        **For Issue:** JES-54 - Color Accessibility Audit
        
        """
        
        return report
    }
    
    /// Print audit results to console
    static func printAuditResults() {
        let results = runCompleteAudit()
        
        print("\n" + String(repeating: "=", count: 80))
        print("COLOR ACCESSIBILITY AUDIT - WCAG AA COMPLIANCE")
        print(String(repeating: "=", count: 80) + "\n")
        
        let categories = Dictionary(grouping: results, by: { $0.category })
        
        for (category, categoryResults) in categories.sorted(by: { $0.key < $1.key }) {
            print("\n\(category)")
            print(String(repeating: "-", count: 80))
            
            for result in categoryResults.sorted(by: { $0.name < $1.name }) {
                print("\(result.status) \(result.name)")
                print("   Contrast: \(result.formattedRatio)")
            }
        }
        
        print("\n" + String(repeating: "=", count: 80))
        
        let totalTests = results.count
        let passedAA = results.filter { $0.meetsAA }.count
        let failed = results.filter { !$0.meetsAA }.count
        
        print("SUMMARY: \(passedAA)/\(totalTests) passed WCAG AA (\(failed) failed)")
        print(String(repeating: "=", count: 80) + "\n")
    }
}

// MARK: - AppColors Extension for Testing

extension AppColors {
    /// Public wrapper for contrast ratio calculation (for testing)
    static func contrastRatio(between color1: NSColor, and color2: NSColor) -> Double {
        let l1 = relativeLuminance(of: color1)
        let l2 = relativeLuminance(of: color2)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Create a Color from a hex string
    static func fromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
