//
//  VendorFlowUITests.swift
//  I Do BlueprintUITests
//
//  UI tests for Vendor management workflows
//

import XCTest

final class VendorFlowUITests: XCTestCase {
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

    // MARK: - Vendor List Tests

    func testVendorListDisplays() throws {
        // Navigate to Vendors section
        let vendorsButton = app.buttons["Vendors"]
        XCTAssertTrue(vendorsButton.waitForExistence(timeout: 5))
        vendorsButton.click()

        // Verify vendor list appears
        let vendorList = app.tables["VendorList"]
        XCTAssertTrue(vendorList.waitForExistence(timeout: 3))
    }

    func testVendorSearchWorks() throws {
        // Navigate to Vendors
        app.buttons["Vendors"].click()

        // Find and use search field
        let searchField = app.searchFields["Search vendors..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))

        searchField.click()
        searchField.typeText("Photographer")

        // Wait for search results to filter
        Thread.sleep(forTimeInterval: 0.5)

        // Verify search filtered results
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'photographer'")).count > 0)
    }

    func testVendorFilterByCategory() throws {
        // Navigate to Vendors
        app.buttons["Vendors"].click()

        // Open filter menu
        let filterButton = app.buttons["Filter"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 3))
        filterButton.click()

        // Select Venue category
        let venueFilter = app.buttons["Venue"]
        XCTAssertTrue(venueFilter.waitForExistence(timeout: 2))
        venueFilter.click()

        // Close filter
        app.buttons["Apply"].click()

        // Verify filtered results
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(app.staticTexts["Venue"].exists || app.staticTexts["No vendors found"].exists)
    }

    // MARK: - Add Vendor Tests

    func testAddVendorFlow() throws {
        // Navigate to Vendors
        app.buttons["Vendors"].click()

        // Click Add Vendor button
        let addButton = app.buttons["Add Vendor"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.click()

        // Fill vendor form
        let nameField = app.textFields["Vendor Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.click()
        nameField.typeText("Test Venue")

        // Select vendor type
        let typePopup = app.popUpButtons["Vendor Type"]
        XCTAssertTrue(typePopup.exists)
        typePopup.click()
        app.menuItems["Venue"].click()

        // Enter cost
        let costField = app.textFields["Quoted Amount"]
        costField.click()
        costField.typeText("5000")

        // Enter contact info
        let emailField = app.textFields["Email"]
        emailField.click()
        emailField.typeText("venue@example.com")

        let phoneField = app.textFields["Phone"]
        phoneField.click()
        phoneField.typeText("555-1234")

        // Save vendor
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists)
        saveButton.click()

        // Verify vendor appears in list
        XCTAssertTrue(app.staticTexts["Test Venue"].waitForExistence(timeout: 3))
    }

    func testAddVendorValidation() throws {
        // Navigate to Vendors
        app.buttons["Vendors"].click()

        // Click Add Vendor
        app.buttons["Add Vendor"].click()

        // Try to save without required fields
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.click()

        // Verify validation error appears
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'required'")).count > 0)
    }

    // MARK: - Edit Vendor Tests

    func testEditVendorFlow() throws {
        // Navigate to Vendors
        app.buttons["Vendors"].click()

        // Select first vendor
        let firstVendor = app.tables["VendorList"].cells.firstMatch
        XCTAssertTrue(firstVendor.waitForExistence(timeout: 3))
        firstVendor.click()

        // Click Edit button
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        editButton.click()

        // Update vendor name
        let nameField = app.textFields["Vendor Name"]
        nameField.click()
        nameField.typeKey("a", modifierFlags: .command) // Select all
        nameField.typeText("Updated Venue")

        // Save changes
        app.buttons["Save"].click()

        // Verify updated name appears
        XCTAssertTrue(app.staticTexts["Updated Venue"].waitForExistence(timeout: 3))
    }
}
