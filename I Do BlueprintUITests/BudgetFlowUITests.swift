//
//  BudgetFlowUITests.swift
//  I Do BlueprintUITests
//
//  UI tests for Budget management workflows
//

import XCTest

final class BudgetFlowUITests: XCTestCase {
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

    // MARK: - Budget View Tests

    func testBudgetViewDisplays() throws {
        // Navigate to Budget section
        let budgetButton = app.buttons["Budget"]
        XCTAssertTrue(budgetButton.waitForExistence(timeout: 5))
        budgetButton.click()

        // Verify budget summary appears
        let budgetSummary = app.staticTexts["Total Budget"]
        XCTAssertTrue(budgetSummary.waitForExistence(timeout: 3))
    }

    func testBudgetCalculatorWorks() throws {
        // Navigate to Budget
        app.buttons["Budget"].click()

        // Open calculator
        let calculatorButton = app.buttons["Budget Calculator"]
        XCTAssertTrue(calculatorButton.waitForExistence(timeout: 3))
        calculatorButton.click()

        // Enter budget
        let budgetField = app.textFields["Total Budget"]
        XCTAssertTrue(budgetField.waitForExistence(timeout: 2))
        budgetField.click()
        budgetField.typeText("50000")

        // Verify calculation appears
        XCTAssertTrue(app.staticTexts["$50,000"].waitForExistence(timeout: 2))
    }

    // MARK: - Category Tests

    func testAddCategoryFlow() throws {
        // Navigate to Budget
        app.buttons["Budget"].click()

        // Click Add Category
        let addCategoryButton = app.buttons["Add Category"]
        XCTAssertTrue(addCategoryButton.waitForExistence(timeout: 3))
        addCategoryButton.click()

        // Fill category form
        let nameField = app.textFields["Category Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.click()
        nameField.typeText("Catering")

        let allocatedField = app.textFields["Allocated Amount"]
        allocatedField.click()
        allocatedField.typeText("15000")

        // Save category
        app.buttons["Save"].click()

        // Verify category appears
        XCTAssertTrue(app.staticTexts["Catering"].waitForExistence(timeout: 3))
    }

    // MARK: - Expense Tests

    func testAddExpenseFlow() throws {
        // Navigate to Budget
        app.buttons["Budget"].click()

        // Click Add Expense
        let addExpenseButton = app.buttons["Add Expense"]
        XCTAssertTrue(addExpenseButton.waitForExistence(timeout: 3))
        addExpenseButton.click()

        // Fill expense form
        let descriptionField = app.textFields["Description"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 2))
        descriptionField.click()
        descriptionField.typeText("Venue Deposit")

        let amountField = app.textFields["Amount"]
        amountField.click()
        amountField.typeText("2500")

        // Select category
        let categoryPopup = app.popUpButtons["Category"]
        categoryPopup.click()
        app.menuItems["Venue"].click()

        // Save expense
        app.buttons["Save"].click()

        // Verify expense appears
        XCTAssertTrue(app.staticTexts["Venue Deposit"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["$2,500"].exists)
    }

    func testLinkExpenseToVendor() throws {
        // Navigate to Budget
        app.buttons["Budget"].click()

        // Select an expense
        let firstExpense = app.tables["ExpenseList"].cells.firstMatch
        XCTAssertTrue(firstExpense.waitForExistence(timeout: 3))
        firstExpense.click()

        // Click Link Vendor
        let linkButton = app.buttons["Link to Vendor"]
        XCTAssertTrue(linkButton.waitForExistence(timeout: 2))
        linkButton.click()

        // Select vendor
        let vendorList = app.tables["VendorPicker"]
        XCTAssertTrue(vendorList.waitForExistence(timeout: 2))
        vendorList.cells.firstMatch.click()

        // Verify link appears
        XCTAssertTrue(app.staticTexts["Linked to Vendor"].waitForExistence(timeout: 3))
    }

    // MARK: - Analytics Tests

    func testViewBudgetAnalytics() throws {
        // Navigate to Budget
        app.buttons["Budget"].click()

        // Click Analytics tab
        let analyticsTab = app.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 3))
        analyticsTab.click()

        // Verify charts appear
        XCTAssertTrue(app.images["BudgetChart"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Spending by Category"].exists)
    }

    func testExportBudgetReport() throws {
        // Navigate to Budget
        app.buttons["Budget"].click()

        // Click Export
        let exportButton = app.buttons["Export Report"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3))
        exportButton.click()

        // Select PDF format
        let pdfOption = app.buttons["Export to PDF"]
        XCTAssertTrue(pdfOption.waitForExistence(timeout: 2))
        pdfOption.click()

        // Verify export success
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'exported'")).firstMatch.waitForExistence(timeout: 5))
    }
}
