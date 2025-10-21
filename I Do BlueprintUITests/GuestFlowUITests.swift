//
//  GuestFlowUITests.swift
//  I Do BlueprintUITests
//
//  UI tests for Guest management workflows
//

import XCTest

final class GuestFlowUITests: XCTestCase {
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

    // MARK: - Guest List Tests

    func testGuestListDisplays() throws {
        // Navigate to Guests section
        let guestsButton = app.buttons["Guests"]
        XCTAssertTrue(guestsButton.waitForExistence(timeout: 5))
        guestsButton.click()

        // Verify guest list appears
        let guestList = app.tables["GuestList"]
        XCTAssertTrue(guestList.waitForExistence(timeout: 3))
    }

    func testGuestSearchWorks() throws {
        // Navigate to Guests
        app.buttons["Guests"].click()

        // Use search field
        let searchField = app.searchFields["Search guests..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))

        searchField.click()
        searchField.typeText("John")

        // Wait for search to filter
        Thread.sleep(forTimeInterval: 0.5)

        // Verify search results
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'john'")).count > 0)
    }

    func testGuestRSVPFilter() throws {
        // Navigate to Guests
        app.buttons["Guests"].click()

        // Open RSVP filter
        let filterButton = app.buttons["RSVP Status"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 3))
        filterButton.click()

        // Select "Confirmed"
        let confirmedFilter = app.buttons["Confirmed"]
        XCTAssertTrue(confirmedFilter.waitForExistence(timeout: 2))
        confirmedFilter.click()

        // Verify filtered results
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(app.staticTexts["Confirmed"].exists || app.staticTexts["No guests found"].exists)
    }

    // MARK: - Add Guest Tests

    func testAddGuestFlow() throws {
        // Navigate to Guests
        app.buttons["Guests"].click()

        // Click Add Guest
        let addButton = app.buttons["Add Guest"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.click()

        // Fill guest form
        let firstNameField = app.textFields["First Name"]
        XCTAssertTrue(firstNameField.waitForExistence(timeout: 2))
        firstNameField.click()
        firstNameField.typeText("Jane")

        let lastNameField = app.textFields["Last Name"]
        lastNameField.click()
        lastNameField.typeText("Smith")

        let emailField = app.textFields["Email"]
        emailField.click()
        emailField.typeText("jane@example.com")

        // Select RSVP status
        let rsvpPopup = app.popUpButtons["RSVP Status"]
        XCTAssertTrue(rsvpPopup.exists)
        rsvpPopup.click()
        app.menuItems["Confirmed"].click()

        // Select meal preference
        let mealPopup = app.popUpButtons["Meal Preference"]
        mealPopup.click()
        app.menuItems["Vegetarian"].click()

        // Save guest
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists)
        saveButton.click()

        // Verify guest appears in list
        XCTAssertTrue(app.staticTexts["Jane Smith"].waitForExistence(timeout: 3))
    }

    func testAddGuestValidation() throws {
        // Navigate to Guests
        app.buttons["Guests"].click()

        // Click Add Guest
        app.buttons["Add Guest"].click()

        // Try to save without required fields
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.click()

        // Verify validation error
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'required'")).count > 0)
    }

    // MARK: - Edit Guest Tests

    func testEditGuestFlow() throws {
        // Navigate to Guests
        app.buttons["Guests"].click()

        // Select first guest
        let firstGuest = app.tables["GuestList"].cells.firstMatch
        XCTAssertTrue(firstGuest.waitForExistence(timeout: 3))
        firstGuest.click()

        // Click Edit
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        editButton.click()

        // Update RSVP status
        let rsvpPopup = app.popUpButtons["RSVP Status"]
        rsvpPopup.click()
        app.menuItems["Declined"].click()

        // Save changes
        app.buttons["Save"].click()

        // Verify updated status
        XCTAssertTrue(app.staticTexts["Declined"].waitForExistence(timeout: 3))
    }

    // MARK: - Export Tests

    func testExportGuestList() throws {
        // Navigate to Guests
        app.buttons["Guests"].click()

        // Click Export button
        let exportButton = app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3))
        exportButton.click()

        // Select Excel format
        let excelOption = app.buttons["Export to Excel"]
        XCTAssertTrue(excelOption.waitForExistence(timeout: 2))
        excelOption.click()

        // Verify export success message
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'exported'")).firstMatch.waitForExistence(timeout: 5))
    }
}
