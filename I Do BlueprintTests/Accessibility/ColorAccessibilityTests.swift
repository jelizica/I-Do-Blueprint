//
//  ColorAccessibilityTests.swift
//  I Do BlueprintTests
//
//  Automated tests for WCAG AA color accessibility compliance
//  Created for JES-54
//

import XCTest
@testable import I_Do_Blueprint
import SwiftUI

final class ColorAccessibilityTests: XCTestCase {
    
    // MARK: - Dashboard Color Tests
    
    func testDashboardQuickActionColors() throws {
        let darkBg = NSColor(AppColors.Dashboard.mainBackground)
        
        // Task Action
        let taskAction = NSColor(AppColors.Dashboard.taskAction)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: taskAction, background: darkBg),
            "Task action color should meet WCAG AA on dark background"
        )
        
        // Note Action
        let noteAction = NSColor(AppColors.Dashboard.noteAction)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: noteAction, background: darkBg),
            "Note action color should meet WCAG AA on dark background"
        )
        
        // Event Action
        let eventAction = NSColor(AppColors.Dashboard.eventAction)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: eventAction, background: darkBg),
            "Event action color should meet WCAG AA on dark background"
        )
        
        // Guest Action
        let guestAction = NSColor(AppColors.Dashboard.guestAction)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: guestAction, background: darkBg),
            "Guest action color should meet WCAG AA on dark background"
        )
    }
    
    func testDashboardCardColors() throws {
        // Budget Card with Black Text
        let budgetCard = NSColor(AppColors.Dashboard.budgetCard)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: .black, background: budgetCard),
            "Budget card should have sufficient contrast with black text"
        )
        
        // RSVP Card with White Text
        let rsvpCard = NSColor(AppColors.Dashboard.rsvpCard)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: .white, background: rsvpCard),
            "RSVP card should have sufficient contrast with white text"
        )
        
        // Vendor Card with White Text
        let vendorCard = NSColor(AppColors.Dashboard.vendorCard)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: .white, background: vendorCard),
            "Vendor card should have sufficient contrast with white text"
        )
        
        // Guest Card with White Text
        let guestCard = NSColor(AppColors.Dashboard.guestCard)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: .white, background: guestCard),
            "Guest card should have sufficient contrast with white text"
        )
        
        // Countdown Card with White Text
        let countdownCard = NSColor(AppColors.Dashboard.countdownCard)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: .white, background: countdownCard),
            "Countdown card should have sufficient contrast with white text"
        )
        
        // Budget Visualization Card with Black Text
        let budgetVizCard = NSColor(AppColors.Dashboard.budgetVisualizationCard)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: .black, background: budgetVizCard),
            "Budget visualization card should have sufficient contrast with black text"
        )
        
        // Task Progress Card with White Text
        let taskProgressCard = NSColor(AppColors.Dashboard.taskProgressCard)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: .white, background: taskProgressCard),
            "Task progress card should have sufficient contrast with white text"
        )
    }
    
    // MARK: - Budget Color Tests
    
    func testBudgetColorsOnLightBackground() throws {
        let lightBg = NSColor.windowBackgroundColor
        
        // Income
        let income = NSColor(AppColors.Budget.income)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: income, background: lightBg),
            "Income color should meet WCAG AA on light background"
        )
        
        // Expense
        let expense = NSColor(AppColors.Budget.expense)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: expense, background: lightBg),
            "Expense color should meet WCAG AA on light background"
        )
        
        // Pending
        let pending = NSColor(AppColors.Budget.pending)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: pending, background: lightBg),
            "Pending color should meet WCAG AA on light background"
        )
        
        // Allocated
        let allocated = NSColor(AppColors.Budget.allocated)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: allocated, background: lightBg),
            "Allocated color should meet WCAG AA on light background"
        )
    }
    
    func testBudgetColorsOnCardBackground() throws {
        let cardBg = NSColor(AppColors.cardBackground)
        
        // Income
        let income = NSColor(AppColors.Budget.income)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: income, background: cardBg),
            "Income color should meet WCAG AA on card background"
        )
        
        // Expense
        let expense = NSColor(AppColors.Budget.expense)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: expense, background: cardBg),
            "Expense color should meet WCAG AA on card background"
        )
        
        // Pending
        let pending = NSColor(AppColors.Budget.pending)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: pending, background: cardBg),
            "Pending color should meet WCAG AA on card background"
        )
        
        // Allocated
        let allocated = NSColor(AppColors.Budget.allocated)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: allocated, background: cardBg),
            "Allocated color should meet WCAG AA on card background"
        )
    }
    
    // MARK: - Guest Color Tests
    
    func testGuestColorsOnLightBackground() throws {
        let lightBg = NSColor.windowBackgroundColor
        
        // Confirmed
        let confirmed = NSColor(AppColors.Guest.confirmed)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: confirmed, background: lightBg),
            "Confirmed color should meet WCAG AA on light background"
        )
        
        // Pending
        let pending = NSColor(AppColors.Guest.pending)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: pending, background: lightBg),
            "Pending color should meet WCAG AA on light background"
        )
        
        // Declined
        let declined = NSColor(AppColors.Guest.declined)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: declined, background: lightBg),
            "Declined color should meet WCAG AA on light background"
        )
        
        // Invited
        let invited = NSColor(AppColors.Guest.invited)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: invited, background: lightBg),
            "Invited color should meet WCAG AA on light background"
        )
        
        // Plus One
        let plusOne = NSColor(AppColors.Guest.plusOne)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: plusOne, background: lightBg),
            "Plus one color should meet WCAG AA on light background"
        )
    }
    
    func testGuestColorsOnCardBackground() throws {
        let cardBg = NSColor(AppColors.cardBackground)
        
        // Confirmed
        let confirmed = NSColor(AppColors.Guest.confirmed)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: confirmed, background: cardBg),
            "Confirmed color should meet WCAG AA on card background"
        )
        
        // Pending
        let pending = NSColor(AppColors.Guest.pending)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: pending, background: cardBg),
            "Pending color should meet WCAG AA on card background"
        )
        
        // Declined
        let declined = NSColor(AppColors.Guest.declined)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: declined, background: cardBg),
            "Declined color should meet WCAG AA on card background"
        )
        
        // Invited
        let invited = NSColor(AppColors.Guest.invited)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: invited, background: cardBg),
            "Invited color should meet WCAG AA on card background"
        )
        
        // Plus One
        let plusOne = NSColor(AppColors.Guest.plusOne)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: plusOne, background: cardBg),
            "Plus one color should meet WCAG AA on card background"
        )
    }
    
    // MARK: - Vendor Color Tests
    
    func testVendorColorsOnLightBackground() throws {
        let lightBg = NSColor.windowBackgroundColor
        
        // Booked
        let booked = NSColor(AppColors.Vendor.booked)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: booked, background: lightBg),
            "Booked color should meet WCAG AA on light background"
        )
        
        // Pending
        let pending = NSColor(AppColors.Vendor.pending)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: pending, background: lightBg),
            "Pending color should meet WCAG AA on light background"
        )
        
        // Contacted
        let contacted = NSColor(AppColors.Vendor.contacted)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: contacted, background: lightBg),
            "Contacted color should meet WCAG AA on light background"
        )
        
        // Not Contacted
        let notContacted = NSColor(AppColors.Vendor.notContacted)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: notContacted, background: lightBg),
            "Not contacted color should meet WCAG AA on light background"
        )
        
        // Contract
        let contract = NSColor(AppColors.Vendor.contract)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: contract, background: lightBg),
            "Contract color should meet WCAG AA on light background"
        )
    }
    
    func testVendorColorsOnCardBackground() throws {
        let cardBg = NSColor(AppColors.cardBackground)
        
        // Booked
        let booked = NSColor(AppColors.Vendor.booked)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: booked, background: cardBg),
            "Booked color should meet WCAG AA on card background"
        )
        
        // Pending
        let pending = NSColor(AppColors.Vendor.pending)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: pending, background: cardBg),
            "Pending color should meet WCAG AA on card background"
        )
        
        // Contacted
        let contacted = NSColor(AppColors.Vendor.contacted)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: contacted, background: cardBg),
            "Contacted color should meet WCAG AA on card background"
        )
        
        // Not Contacted
        let notContacted = NSColor(AppColors.Vendor.notContacted)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: notContacted, background: cardBg),
            "Not contacted color should meet WCAG AA on card background"
        )
        
        // Contract
        let contract = NSColor(AppColors.Vendor.contract)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: contract, background: cardBg),
            "Contract color should meet WCAG AA on card background"
        )
    }
    
    // MARK: - Semantic Color Tests
    
    func testSemanticStatusColors() throws {
        let lightBg = NSColor.windowBackgroundColor
        
        // Success
        let success = NSColor(AppColors.success)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: success, background: lightBg),
            "Success color should meet WCAG AA on light background"
        )
        
        // Warning
        let warning = NSColor(AppColors.warning)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: warning, background: lightBg),
            "Warning color should meet WCAG AA on light background"
        )
        
        // Error
        let error = NSColor(AppColors.error)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: error, background: lightBg),
            "Error color should meet WCAG AA on light background"
        )
        
        // Info
        let info = NSColor(AppColors.info)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: info, background: lightBg),
            "Info color should meet WCAG AA on light background"
        )
    }
    
    func testSemanticTextColors() throws {
        let lightBg = NSColor.windowBackgroundColor
        
        // Primary Text
        let textPrimary = NSColor(AppColors.textPrimary)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: textPrimary, background: lightBg),
            "Primary text should meet WCAG AA on light background"
        )
        
        // Secondary Text
        let textSecondary = NSColor(AppColors.textSecondary)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: textSecondary, background: lightBg),
            "Secondary text should meet WCAG AA on light background"
        )
        
        // Tertiary Text
        let textTertiary = NSColor(AppColors.textTertiary)
        XCTAssertTrue(
            AppColors.meetsContrastRequirements(foreground: textTertiary, background: lightBg),
            "Tertiary text should meet WCAG AA on light background"
        )
    }
    
    // MARK: - Contrast Ratio Calculation Tests
    
    func testContrastRatioCalculation() throws {
        // Test known contrast ratios
        
        // Black on white should be 21:1
        let blackOnWhite = AppColors.contrastRatio(between: .black, and: .white)
        XCTAssertEqual(blackOnWhite, 21.0, accuracy: 0.1, "Black on white should be 21:1")
        
        // White on black should be 21:1
        let whiteOnBlack = AppColors.contrastRatio(between: .white, and: .black)
        XCTAssertEqual(whiteOnBlack, 21.0, accuracy: 0.1, "White on black should be 21:1")
        
        // Same color should be 1:1
        let sameColor = AppColors.contrastRatio(between: .white, and: .white)
        XCTAssertEqual(sameColor, 1.0, accuracy: 0.1, "Same color should be 1:1")
    }
    
    func testWCAGAACompliance() throws {
        // Test that 4.5:1 is the minimum for AA
        let lightGray = NSColor(white: 0.6, alpha: 1.0)
        let white = NSColor.white
        
        let ratio = AppColors.contrastRatio(between: lightGray, and: white)
        
        if ratio >= 4.5 {
            XCTAssertTrue(
                AppColors.meetsContrastRequirements(foreground: lightGray, background: white),
                "Colors with 4.5:1+ ratio should pass AA"
            )
        } else {
            XCTAssertFalse(
                AppColors.meetsContrastRequirements(foreground: lightGray, background: white),
                "Colors with <4.5:1 ratio should fail AA"
            )
        }
    }
    
    func testWCAGAAACompliance() throws {
        // Test that 7:1 is the minimum for AAA
        let darkGray = NSColor(white: 0.3, alpha: 1.0)
        let white = NSColor.white
        
        let ratio = AppColors.contrastRatio(between: darkGray, and: white)
        
        if ratio >= 7.0 {
            XCTAssertTrue(
                AppColors.meetsEnhancedContrastRequirements(foreground: darkGray, background: white),
                "Colors with 7:1+ ratio should pass AAA"
            )
        } else {
            XCTAssertFalse(
                AppColors.meetsEnhancedContrastRequirements(foreground: darkGray, background: white),
                "Colors with <7:1 ratio should fail AAA"
            )
        }
    }
    
    // MARK: - Performance Tests
    
    func testContrastCalculationPerformance() throws {
        let color1 = NSColor.systemBlue
        let color2 = NSColor.white
        
        measure {
            for _ in 0..<1000 {
                _ = AppColors.contrastRatio(between: color1, and: color2)
            }
        }
    }
    
    // MARK: - Comprehensive Audit Test
    
    func testCompleteAccessibilityAudit() throws {
        let results = AccessibilityAudit.runCompleteAudit()
        
        let failures = results.filter { !$0.meetsAA }
        
        if !failures.isEmpty {
            let failureList = failures.map { "\($0.name): \($0.formattedRatio)" }.joined(separator: "\n")
            XCTFail("The following color combinations do not meet WCAG AA standards:\n\(failureList)")
        }
        
        // Log summary
        let totalTests = results.count
        let passedAA = results.filter { $0.meetsAA }.count
        let passedAAA = results.filter { $0.meetsAAA }.count
        
        print("\n=== Accessibility Audit Summary ===")
        print("Total Tests: \(totalTests)")
        print("WCAG AA Passed: \(passedAA)")
        print("WCAG AAA Passed: \(passedAAA)")
        print("===================================\n")
    }
}
