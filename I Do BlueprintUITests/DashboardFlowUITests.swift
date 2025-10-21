//
//  DashboardFlowUITests.swift
//  I Do BlueprintUITests
//
//  UI tests for Dashboard workflows and navigation
//

import XCTest

final class DashboardFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--disable-animations"]
        app.launch()
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - Dashboard Display Tests

    func testDashboardLoads() throws {
        // Verify dashboard appears after launch
        let dashboardView = app.staticTexts["Dashboard"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 5))

        // Verify key widgets are present
        XCTAssertTrue(app.staticTexts["Budget Summary"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Upcoming Tasks"].exists)
        XCTAssertTrue(app.staticTexts["Vendor Status"].exists)
        XCTAssertTrue(app.staticTexts["Guest Count"].exists)
    }

    func testDashboardStatsDisplay() throws {
        // Verify budget stats
        let totalBudget = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch
        XCTAssertTrue(totalBudget.waitForExistence(timeout: 3))

        // Verify vendor count
        let vendorCount = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d+ vendors?'")).firstMatch
        XCTAssertTrue(vendorCount.exists || app.staticTexts["0 vendors"].exists)

        // Verify guest count
        let guestCount = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d+ guests?'")).firstMatch
        XCTAssertTrue(guestCount.exists || app.staticTexts["0 guests"].exists)
    }

    // MARK: - Quick Actions Tests

    func testQuickActionAddVendor() throws {
        // Click quick action to add vendor
        let addVendorButton = app.buttons["Quick Add Vendor"]
        XCTAssertTrue(addVendorButton.waitForExistence(timeout: 3))
        addVendorButton.click()

        // Verify vendor form appears
        XCTAssertTrue(app.textFields["Vendor Name"].waitForExistence(timeout: 2))
    }

    func testQuickActionAddGuest() throws {
        // Click quick action to add guest
        let addGuestButton = app.buttons["Quick Add Guest"]
        XCTAssertTrue(addGuestButton.waitForExistence(timeout: 3))
        addGuestButton.click()

        // Verify guest form appears
        XCTAssertTrue(app.textFields["First Name"].waitForExistence(timeout: 2))
    }

    func testQuickActionAddTask() throws {
        // Click quick action to add task
        let addTaskButton = app.buttons["Quick Add Task"]
        XCTAssertTrue(addTaskButton.waitForExistence(timeout: 3))
        addTaskButton.click()

        // Verify task form appears
        XCTAssertTrue(app.textFields["Task Title"].waitForExistence(timeout: 2))
    }

    // MARK: - Navigation Tests

    func testNavigateToVendors() throws {
        // Click on Vendor Status card
        let vendorCard = app.buttons["Vendor Status"]
        XCTAssertTrue(vendorCard.waitForExistence(timeout: 3))
        vendorCard.click()

        // Verify navigated to Vendors view
        XCTAssertTrue(app.staticTexts["Vendors"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tables["VendorList"].exists)
    }

    func testNavigateToGuests() throws {
        // Click on Guest Count card
        let guestCard = app.buttons["Guest Count"]
        XCTAssertTrue(guestCard.waitForExistence(timeout: 3))
        guestCard.click()

        // Verify navigated to Guests view
        XCTAssertTrue(app.staticTexts["Guests"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tables["GuestList"].exists)
    }

    func testNavigateToBudget() throws {
        // Click on Budget Summary card
        let budgetCard = app.buttons["Budget Summary"]
        XCTAssertTrue(budgetCard.waitForExistence(timeout: 3))
        budgetCard.click()

        // Verify navigated to Budget view
        XCTAssertTrue(app.staticTexts["Budget"].waitForExistence(timeout: 3))
    }

    func testNavigateToTasks() throws {
        // Click on Upcoming Tasks card
        let taskCard = app.buttons["Upcoming Tasks"]
        XCTAssertTrue(taskCard.waitForExistence(timeout: 3))
        taskCard.click()

        // Verify navigated to Tasks view
        XCTAssertTrue(app.staticTexts["Tasks"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tables["TaskList"].exists)
    }

    // MARK: - Refresh Tests

    func testDashboardRefresh() throws {
        // Pull to refresh or click refresh button
        let refreshButton = app.buttons["Refresh"]
        if refreshButton.exists {
            refreshButton.click()

            // Wait for refresh to complete
            Thread.sleep(forTimeInterval: 1.0)

            // Verify data is still displayed
            XCTAssertTrue(app.staticTexts["Budget Summary"].exists)
        }
    }
}
