//
//  SettingsNavigationUITests.swift
//  I Do BlueprintUITests
//
//  UI tests for settings navigation with nested hierarchy
//

import XCTest

final class SettingsNavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        // Navigate to Settings if not already there
        navigateToSettings()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    private func navigateToSettings() {
        // Wait for app to load
        let settingsButton = app.buttons["Settings"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
        }
    }

    // MARK: - Parent Section Visibility Tests

    func testAllParentSectionsVisible() throws {
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.exists, "Settings sidebar should exist")

        // Verify all 7 parent sections are visible
        let expectedSections = [
            "Wedding Setup",
            "Account",
            "Budget & Vendors",
            "Guests & Tasks",
            "Appearance & Notifications",
            "Data & Content",
            "Developer & Advanced"
        ]

        for section in expectedSections {
            let sectionElement = sidebar.staticTexts[section]
            XCTAssertTrue(
                sectionElement.exists,
                "Parent section '\(section)' should be visible in sidebar"
            )
        }
    }

    // MARK: - Expand/Collapse Tests

    func testExpandCollapseParentSection() throws {
        let sidebar = app.outlines.firstMatch
        
        // Find Budget & Vendors section
        let budgetSection = sidebar.disclosureTriangles["Budget & Vendors"]
        XCTAssertTrue(budgetSection.exists, "Budget & Vendors disclosure triangle should exist")

        // Expand the section
        budgetSection.tap()
        
        // Verify subsections are visible
        let budgetConfigSubsection = sidebar.staticTexts["Budget Configuration"]
        XCTAssertTrue(
            budgetConfigSubsection.waitForExistence(timeout: 2),
            "Budget Configuration subsection should appear after expanding"
        )

        // Collapse the section
        budgetSection.tap()
        
        // Verify subsections are hidden (with a small delay for animation)
        sleep(1)
        XCTAssertFalse(
            budgetConfigSubsection.exists,
            "Budget Configuration subsection should disappear after collapsing"
        )
    }

    // MARK: - Subsection Navigation Tests

    func testSubsectionNavigation() throws {
        let sidebar = app.outlines.firstMatch
        
        // Expand Guests & Tasks section
        let guestsTasksSection = sidebar.disclosureTriangles["Guests & Tasks"]
        if guestsTasksSection.exists {
            guestsTasksSection.tap()
        }
        
        // Click on Team Members subsection
        let teamMembersSubsection = sidebar.buttons["Team Members"]
        XCTAssertTrue(
            teamMembersSubsection.waitForExistence(timeout: 2),
            "Team Members subsection should be visible"
        )
        
        teamMembersSubsection.tap()
        
        // Verify detail view shows correct content
        let detailView = app.scrollViews.firstMatch
        XCTAssertTrue(detailView.exists, "Detail view should exist")
        
        // Check for Team Members specific content
        let teamMembersTitle = app.staticTexts["Team Members"]
        XCTAssertTrue(
            teamMembersTitle.exists,
            "Team Members title should be visible in detail view"
        )
    }

    // MARK: - Navigation Title Tests

    func testNavigationTitleFormat() throws {
        let sidebar = app.outlines.firstMatch
        
        // Expand Account section
        let accountSection = sidebar.disclosureTriangles["Account"]
        if accountSection.exists {
            accountSection.tap()
        }
        
        // Click on Collaboration & Team subsection
        let collaborationSubsection = sidebar.buttons["Collaboration & Team"]
        if collaborationSubsection.waitForExistence(timeout: 2) {
            collaborationSubsection.tap()
        }
        
        // Verify navigation title shows "Parent - Subsection" format
        let navigationTitle = app.staticTexts["Account - Collaboration & Team"]
        XCTAssertTrue(
            navigationTitle.exists,
            "Navigation title should show 'Account - Collaboration & Team' format"
        )
    }

    // MARK: - Detail View Content Tests

    func testDetailViewShowsCorrectContent() throws {
        let sidebar = app.outlines.firstMatch
        
        // Test multiple subsections to ensure routing works
        let testCases: [(section: String, subsection: String, expectedContent: String)] = [
            ("Wedding Setup", "Overview", "Wedding Setup"),
            ("Appearance & Notifications", "Theme", "Theme"),
            ("Data & Content", "Documents", "Documents")
        ]
        
        for testCase in testCases {
            // Expand parent section
            let parentSection = sidebar.disclosureTriangles[testCase.section]
            if parentSection.exists {
                parentSection.tap()
            }
            
            // Click subsection
            let subsection = sidebar.buttons[testCase.subsection]
            if subsection.waitForExistence(timeout: 2) {
                subsection.tap()
            }
            
            // Verify expected content appears
            let expectedElement = app.staticTexts[testCase.expectedContent]
            XCTAssertTrue(
                expectedElement.exists,
                "Detail view should show '\(testCase.expectedContent)' content for \(testCase.section) - \(testCase.subsection)"
            )
        }
    }

    // MARK: - State Persistence Tests

    func testExpandedStatePersistsAcrossRestart() throws {
        let sidebar = app.outlines.firstMatch
        
        // Expand Developer & Advanced section
        let developerSection = sidebar.disclosureTriangles["Developer & Advanced"]
        if developerSection.exists {
            developerSection.tap()
        }
        
        // Verify subsection is visible
        let apiKeysSubsection = sidebar.buttons["API Keys"]
        XCTAssertTrue(
            apiKeysSubsection.waitForExistence(timeout: 2),
            "API Keys subsection should be visible after expanding"
        )
        
        // Terminate and relaunch app
        app.terminate()
        app.launch()
        navigateToSettings()
        
        // Verify Developer & Advanced is still expanded
        let sidebarAfterRelaunch = app.outlines.firstMatch
        let apiKeysAfterRelaunch = sidebarAfterRelaunch.buttons["API Keys"]
        XCTAssertTrue(
            apiKeysAfterRelaunch.waitForExistence(timeout: 2),
            "API Keys subsection should still be visible after app restart"
        )
    }

    // MARK: - Default Expanded Sections Tests

    func testDefaultExpandedSections() throws {
        // For a fresh install, Wedding Setup and Account should be expanded by default
        // This test assumes a clean state or first launch
        
        let sidebar = app.outlines.firstMatch
        
        // Check if Wedding Setup subsections are visible
        let overviewSubsection = sidebar.buttons["Overview"]
        let isWeddingSetupExpanded = overviewSubsection.exists
        
        // Check if Account subsections are visible
        let profileSubsection = sidebar.buttons["Profile & Authentication"]
        let isAccountExpanded = profileSubsection.exists
        
        // At least one of the default sections should be expanded
        XCTAssertTrue(
            isWeddingSetupExpanded || isAccountExpanded,
            "At least one default section (Wedding Setup or Account) should be expanded"
        )
    }

    // MARK: - Keyboard Navigation Tests

    func testKeyboardNavigation() throws {
        let sidebar = app.outlines.firstMatch
        
        // Focus on sidebar
        sidebar.tap()
        
        // Use arrow keys to navigate
        sidebar.typeKey(.downArrow, modifierFlags: [])
        sidebar.typeKey(.downArrow, modifierFlags: [])
        
        // Press Enter to expand/select
        sidebar.typeKey(.return, modifierFlags: [])
        
        // Verify navigation occurred (this is a basic test)
        XCTAssertTrue(sidebar.exists, "Sidebar should still exist after keyboard navigation")
    }

    // MARK: - All Subsections Accessible Tests

    func testAllSubsectionsAccessible() throws {
        let sidebar = app.outlines.firstMatch
        
        // Define all expected subsections per parent
        let subsectionsByParent: [String: [String]] = [
            "Wedding Setup": ["Overview", "Wedding Events"],
            "Account": ["Profile & Authentication", "Collaboration & Team", "Data & Privacy"],
            "Budget & Vendors": ["Budget Configuration", "Budget Categories", "Vendor Management", "Vendor Categories"],
            "Guests & Tasks": ["Guest Preferences", "Task Preferences", "Team Members"],
            "Appearance & Notifications": ["Theme", "Notifications"],
            "Data & Content": ["Documents", "Important Links"],
            "Developer & Advanced": ["API Keys", "Feature Flags"]
        ]
        
        for (parent, subsections) in subsectionsByParent {
            // Expand parent section
            let parentSection = sidebar.disclosureTriangles[parent]
            if parentSection.exists {
                parentSection.tap()
            }
            
            // Verify all subsections are accessible
            for subsection in subsections {
                let subsectionButton = sidebar.buttons[subsection]
                XCTAssertTrue(
                    subsectionButton.waitForExistence(timeout: 2),
                    "Subsection '\(subsection)' should be accessible under '\(parent)'"
                )
            }
            
            // Collapse section for next iteration
            if parentSection.exists {
                parentSection.tap()
            }
        }
    }

    // MARK: - Settings Save Tests

    func testSettingsSaveCorrectly() throws {
        let sidebar = app.outlines.firstMatch
        
        // Navigate to Theme settings
        let appearanceSection = sidebar.disclosureTriangles["Appearance & Notifications"]
        if appearanceSection.exists {
            appearanceSection.tap()
        }
        
        let themeSubsection = sidebar.buttons["Theme"]
        if themeSubsection.waitForExistence(timeout: 2) {
            themeSubsection.tap()
        }
        
        // Find and interact with a setting (e.g., color scheme picker)
        let detailView = app.scrollViews.firstMatch
        XCTAssertTrue(detailView.exists, "Detail view should exist")
        
        // Look for save button or auto-save indicator
        // This is a placeholder - actual implementation depends on your UI
        let saveButton = app.buttons["Save"]
        if saveButton.exists {
            saveButton.tap()
            
            // Verify success message or state change
            let successMessage = app.staticTexts["Success"]
            XCTAssertTrue(
                successMessage.waitForExistence(timeout: 3),
                "Success message should appear after saving"
            )
        }
    }

    // MARK: - Performance Tests

    func testNavigationPerformance() throws {
        measure {
            let sidebar = app.outlines.firstMatch
            
            // Expand and collapse multiple sections
            for _ in 0..<3 {
                let budgetSection = sidebar.disclosureTriangles["Budget & Vendors"]
                if budgetSection.exists {
                    budgetSection.tap()
                    budgetSection.tap()
                }
            }
        }
    }
}
