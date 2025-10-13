import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct BudgetDevelopmentView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @StateObject private var googleIntegration = GoogleIntegrationManager()

    // Core state
    @State private var budgetItems: [BudgetItem] = []
    @State private var savedScenarios: [SavedScenario] = []
    @State private var selectedScenario: String = "new"
    @State private var currentScenarioId: String?
    @State private var budgetName: String = "Wedding Budget Development"
    @State private var selectedTaxRateId: Int64?
    @State private var loading = true
    @State private var saving = false
    @State private var uploading = false

    // Track newly created items that need to be saved
    @State private var newlyCreatedItemIds: Set<String> = []

    // Track items that need to be deleted from database
    @State private var itemsToDelete: Set<String> = []

    private let logger = AppLogger.ui

    // UI state
    @State private var newCategoryNames: [String: String] = [:]
    @State private var newSubcategoryNames: [String: String] = [:]
    @State private var newEventNames: [String: String] = [:]
    @State private var expandedCategories: Set<String> = Set()

    // Dialogs
    @State private var showingTaxRateDialog = false
    @State private var showingRenameDialog = false
    @State private var showingDuplicateDialog = false
    @State private var showingDeleteDialog = false
    @State private var showingExportMenu = false

    // Dialog data
    @State private var customTaxRateData = CustomTaxRateData()
    @State private var renameScenarioData = ScenarioDialogData()
    @State private var duplicateScenarioData = ScenarioDialogData()
    @State private var deleteScenarioData = ScenarioDialogData()

    // Computed property to get the actual tax rate value as a percentage (e.g., 10.35 for 10.35%)
    private var selectedTaxRate: Double {
        guard let selectedId = selectedTaxRateId,
              let taxInfo = budgetStore.taxRates.first(where: { $0.id == selectedId })
        else {
            return (budgetStore.taxRates.first?.taxRate ?? 0.0) * 100
        }
        return taxInfo.taxRate * 100
    }

    var body: some View {
        VStack(spacing: 0) {
            // Configuration header
            configurationHeader

            ScrollView {
                VStack(spacing: 24) {
                    // Budget summary cards
                    budgetSummaryCards

                    // Budget items table
                    budgetItemsTable

                    // Summary sections
                    if !budgetItems.isEmpty {
                        summaryBreakdowns
                    }
                }
                .padding()
            }
        }
        .task {
            await loadInitialData()
        }
        .sheet(isPresented: $showingTaxRateDialog) {
            TaxRateDialogView(
                customTaxRateData: $customTaxRateData,
                onSave: handleAddCustomTaxRate)
        }
        .sheet(isPresented: $showingRenameDialog) {
            RenameScenarioDialogView(
                renameData: $renameScenarioData,
                onSave: handleRenameScenario)
        }
        .sheet(isPresented: $showingDuplicateDialog) {
            DuplicateScenarioDialogView(
                duplicateData: $duplicateScenarioData,
                onSave: handleDuplicateScenario)
        }
        .alert("Delete Scenario", isPresented: $showingDeleteDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await handleDeleteScenario() }
            }
        } message: {
            Text("Are you sure you want to delete '\(deleteScenarioData.name)'? This action cannot be undone.")
        }
    }

    // MARK: - View Components

    private var configurationHeader: some View {
        BudgetConfigurationHeader(
            selectedScenario: $selectedScenario,
            budgetName: $budgetName,
            selectedTaxRateId: $selectedTaxRateId,
            saving: $saving,
            uploading: $uploading,
            savedScenarios: savedScenarios,
            currentScenarioId: currentScenarioId,
            taxRates: budgetStore.taxRates,
            isGoogleAuthenticated: googleIntegration.authManager.isAuthenticated,
            onExportJSON: exportBudgetAsJSON,
            onExportCSV: exportBudgetAsCSV,
            onExportToGoogleDrive: exportToGoogleDrive,
            onExportToGoogleSheets: exportToGoogleSheets,
            onSignInToGoogle: signInToGoogle,
            onSignOutFromGoogle: { googleIntegration.authManager.signOut() },
            onSaveScenario: saveScenario,
            onUploadScenario: uploadScenario,
            onLoadScenario: loadScenario,
            onSetPrimaryScenario: setPrimaryScenario,
            onShowRenameDialog: { id, name in
                renameScenarioData = ScenarioDialogData(id: id, name: name)
                showingRenameDialog = true
            },
            onShowDuplicateDialog: { id, name in
                duplicateScenarioData = ScenarioDialogData(id: id, name: name)
                showingDuplicateDialog = true
            },
            onShowDeleteDialog: { id, name in
                deleteScenarioData = ScenarioDialogData(id: id, name: name)
                showingDeleteDialog = true
            },
            onShowTaxRateDialog: {
                customTaxRateData = CustomTaxRateData()
                showingTaxRateDialog = true
            }
        )
    }

    private var budgetSummaryCards: some View {
        BudgetSummaryCardsSection(
            totalWithoutTax: totalWithoutTax,
            totalTax: totalTax,
            totalWithTax: totalWithTax
        )
    }

    private var budgetItemsTable: some View {
        BudgetItemsTable(
            budgetItems: $budgetItems,
            newCategoryNames: $newCategoryNames,
            newSubcategoryNames: $newSubcategoryNames,
            newEventNames: $newEventNames,
            budgetStore: budgetStore,
            selectedTaxRate: selectedTaxRate,
            onAddItem: {
                logger.debug("Add Item button clicked")
                addBudgetItem()
            },
            onUpdateItem: updateBudgetItem,
            onRemoveItem: removeBudgetItem,
            onAddCategory: handleNewCategoryName,
            onAddSubcategory: handleNewSubcategoryName,
            onAddEvent: handleNewEventName
        )
    }

    private var summaryBreakdowns: some View {
        BudgetSummaryBreakdowns(
            expandedCategories: $expandedCategories,
            eventBreakdown: eventBreakdown,
            categoryBreakdown: categoryBreakdown,
            personBreakdown: personBreakdown,
            totalWithTax: totalWithTax
        )
    }

    // MARK: - Computed Properties

    private var totalWithoutTax: Double {
        budgetItems.reduce(0) { $0 + $1.vendorEstimateWithoutTax }
    }

    private var totalTax: Double {
        budgetItems.reduce(0) { $0 + ($1.vendorEstimateWithTax - $1.vendorEstimateWithoutTax) }
    }

    private var totalWithTax: Double {
        budgetItems.reduce(0) { $0 + $1.vendorEstimateWithTax }
    }

    private var eventBreakdown: [String: Double] {
        var breakdown: [String: Double] = [:]

        for item in budgetItems {
            let eventIds = item.eventIds ?? []
            let costPerEvent = !eventIds.isEmpty ? item.vendorEstimateWithTax / Double(eventIds.count) : 0

            for eventId in eventIds {
                if let event = budgetStore.weddingEvents.first(where: { $0.id == eventId }) {
                    breakdown[event.eventName, default: 0] += costPerEvent
                }
            }
        }

        return breakdown
    }

    private var categoryBreakdown: [String: (total: Double, subcategories: [String: Double])] {
        var breakdown: [String: (total: Double, subcategories: [String: Double])] = [:]

        for item in budgetItems {
            guard !item.category.isEmpty else { continue }

            if breakdown[item.category] == nil {
                breakdown[item.category] = (total: 0, subcategories: [:])
            }

            breakdown[item.category]!.total += item.vendorEstimateWithTax

            if let subcategory = item.subcategory, !subcategory.isEmpty {
                breakdown[item.category]!.subcategories[subcategory, default: 0] += item.vendorEstimateWithTax
            }
        }

        return breakdown
    }

    private var personBreakdown: [String: Double] {
        var breakdown: [String: Double] = ["Jess": 0, "Liz": 0, "Both": 0]

        for item in budgetItems {
            breakdown[item.personResponsible ?? "Both", default: 0] += item.vendorEstimateWithTax
        }

        return breakdown
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        loading = true
        defer { loading = false }

        await budgetStore.loadBudgetData()
        await fetchSavedScenarios()

        // Just use first rate since TaxInfo doesn't have isDefault
        if let firstRate = budgetStore.taxRates.first {
            selectedTaxRateId = firstRate.id
        }

        // Auto-select the first scenario if available (preferably the primary one)
        if let primaryScenario = savedScenarios.first(where: { $0.isPrimary }) {
            await MainActor.run {
                selectedScenario = primaryScenario.id
            }
            await loadScenario(primaryScenario.id)
        } else if let firstScenario = savedScenarios.first {
            await MainActor.run {
                selectedScenario = firstScenario.id
            }
            await loadScenario(firstScenario.id)
        }
    }

    private func fetchSavedScenarios() async {
        // Use the real scenarios loaded by BudgetStore from Supabase
        savedScenarios = budgetStore.savedScenarios
    }

    private func loadScenario(_ scenarioId: String) async {
        logger.debug("Loading scenario: \(scenarioId)")

        if scenarioId == "new" {
            await MainActor.run {
                budgetItems = []
                budgetName = "Wedding Budget Development"
                currentScenarioId = nil
                newlyCreatedItemIds.removeAll() // Clear tracking set for new scenario
            }
            return
        }

        // Load real scenario data from Supabase
        if let scenario = savedScenarios.first(where: { $0.id == scenarioId }) {
            logger.debug("Found scenario: \(scenario.scenarioName)")

            // Load budget items for this scenario from database
            let items = await budgetStore.loadBudgetDevelopmentItems(scenarioId: scenarioId)
            logger.debug("Loaded \(items.count) budget items")

            await MainActor.run {
                budgetName = scenario.scenarioName
                currentScenarioId = scenario.id
                budgetItems = items
                newlyCreatedItemIds.removeAll() // Clear tracking set when loading existing scenario
            }
        } else {
            logger.warning("Scenario not found: \(scenarioId)")
        }
    }

    // MARK: - Budget Item Management

    private func addBudgetItem() {
        logger.debug("addBudgetItem() called, current count: \(budgetItems.count)")

        guard let coupleId = SessionManager.shared.getTenantId() else {
            logger.error("Cannot add budget item: No couple selected")
            return
        }

        let newItem = BudgetItem(
            id: UUID().uuidString,
            scenarioId: currentScenarioId,
            itemName: "",
            category: "",
            subcategory: "",
            vendorEstimateWithoutTax: 0,
            taxRate: selectedTaxRate,
            vendorEstimateWithTax: 0,
            personResponsible: "Both",
            notes: "",
            createdAt: Date(),
            updatedAt: Date(),
            eventId: nil,
            eventIds: [],
            linkedExpenseId: nil,
            linkedGiftOwedId: nil,
            coupleId: coupleId.uuidString,
            isTestData: false)

        logger.debug("Created new item with ID: \(newItem.id)")
        budgetItems.insert(newItem, at: 0)
        newlyCreatedItemIds.insert(newItem.id) // Track this as a new item
        logger.debug("New budgetItems count: \(budgetItems.count), will save to database when Save button is clicked")
    }

    private func updateBudgetItem(_ id: String, field: String, value: Any) {
        guard let index = budgetItems.firstIndex(where: { $0.id == id }) else { return }

        var item = budgetItems[index]

        switch field {
        case "itemName":
            item.itemName = value as? String ?? ""
        case "eventIds":
            item.eventIds = value as? [String] ?? []
        // eventNames is now a computed property
        case "category":
            item.category = value as? String ?? ""
            item.subcategory = "" // Clear subcategory when category changes
        case "subcategory":
            item.subcategory = value as? String ?? ""
        case "vendorEstimateWithoutTax":
            item.vendorEstimateWithoutTax = value as? Double ?? 0
            item.vendorEstimateWithTax = item.vendorEstimateWithoutTax * (1 + item.taxRate / 100)
        case "taxRate":
            item.taxRate = value as? Double ?? 0
            item.vendorEstimateWithTax = item.vendorEstimateWithoutTax * (1 + item.taxRate / 100)
        case "personResponsible":
            item.personResponsible = value as? String ?? "Both"
        case "notes":
            item.notes = value as? String ?? ""
        default:
            break
        }

        budgetItems[index] = item
    }

    private func removeBudgetItem(_ id: String) {
        // Check if this item exists in the database (not in newlyCreatedItemIds)
        if !newlyCreatedItemIds.contains(id) {
            // This item exists in the database and needs to be deleted
            itemsToDelete.insert(id)
            logger.debug("Marked item \(id) for deletion from database")
        } else {
            // This was a newly created item that hasn't been saved yet, just remove from tracking
            newlyCreatedItemIds.remove(id)
            logger.debug("Removed unsaved item \(id) from tracking")
        }

        // Remove from local array
        budgetItems.removeAll { $0.id == id }
    }

    // MARK: - Category Management

    private func handleNewCategoryName(_ itemId: String, _ categoryName: String) async {
        guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if category already exists
        let existingCategory = budgetStore.categories.first {
            $0.categoryName == trimmedName && $0.parentCategoryId == nil
        }

        if existingCategory == nil {
            // Create new category
            let newCategory = BudgetCategory(
                id: UUID(),
                coupleId: UUID(), // Default couple ID
                categoryName: trimmedName,
                parentCategoryId: nil,
                allocatedAmount: 0,
                spentAmount: 0,
                typicalPercentage: 0,
                priorityLevel: 5,
                isEssential: false,
                notes: "Category created from budget development",
                forecastedAmount: 0,
                confidenceLevel: 0.5,
                lockedAllocation: false,
                description: "Category created from budget development",
                createdAt: Date())
            await budgetStore.addCategory(newCategory)
        }

        updateBudgetItem(itemId, field: "category", value: trimmedName)
        newCategoryNames.removeValue(forKey: itemId)
    }

    private func handleNewSubcategoryName(_ itemId: String, _ subcategoryName: String) async {
        guard !subcategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let item = budgetItems.first(where: { $0.id == itemId }),
              !item.category.isEmpty else { return }

        let trimmedName = subcategoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find parent category
        guard let parentCategory = budgetStore.categories.first(where: {
            $0.categoryName == item.category && $0.parentCategoryId == nil
        }) else { return }

        // Check if subcategory already exists
        let existingSubcategory = budgetStore.categories.first {
            $0.categoryName == trimmedName && $0.parentCategoryId == parentCategory.id
        }

        if existingSubcategory == nil {
            // Create new subcategory
            let newSubcategory = BudgetCategory(
                id: UUID(),
                coupleId: UUID(), // Default couple ID
                categoryName: trimmedName,
                parentCategoryId: parentCategory.id,
                allocatedAmount: 0,
                spentAmount: 0,
                typicalPercentage: 0,
                priorityLevel: 5,
                isEssential: false,
                notes: "Subcategory created from budget development",
                forecastedAmount: 0,
                confidenceLevel: 0.5,
                lockedAllocation: false,
                description: "Subcategory created from budget development",
                createdAt: Date())
            await budgetStore.addCategory(newSubcategory)
        }

        updateBudgetItem(itemId, field: "subcategory", value: trimmedName)
        newSubcategoryNames.removeValue(forKey: itemId)
    }

    private func handleNewEventName(_ itemId: String, _: String) {
        // In the Next.js version, this directs users to settings
        // We'll show an alert here
        newEventNames.removeValue(forKey: itemId)
        // Show alert directing to settings
    }

    // MARK: - Scenario Management

    private func saveScenario() async {
        saving = true
        defer { saving = false }

        logger.debug("saveScenario() called - saving scenario and budget items to database")

        guard let coupleId = SessionManager.shared.getTenantId() else {
            logger.error("Cannot save scenario: No couple selected")
            return
        }

        let scenarioData = SavedScenario(
            id: currentScenarioId ?? UUID().uuidString,
            scenarioName: budgetName,
            createdAt: Date(),
            updatedAt: Date(),
            totalWithoutTax: totalWithoutTax,
            totalTax: totalTax,
            totalWithTax: totalWithTax,
            isPrimary: false,
            coupleId: coupleId.uuidString,
            isTestData: false)

        do {
            // Save/update scenario in database
            let isUpdate = currentScenarioId != nil
            logger.debug("\(isUpdate ? "Updating" : "Creating") scenario in database...")
            let savedScenario = try await budgetStore.saveBudgetDevelopmentScenario(scenarioData, isUpdate: isUpdate)

            // Delete items marked for deletion
            if !itemsToDelete.isEmpty {
                logger.debug("Deleting \(itemsToDelete.count) items from database...")
                for itemId in itemsToDelete {
                    do {
                        try await budgetStore.deleteBudgetDevelopmentItem(id: itemId)
                        logger.debug("Successfully deleted item: \(itemId)")
                    } catch {
                        logger.error("Failed to delete item \(itemId)", error: error)
                    }
                }
                // Clear the deletion set after processing
                itemsToDelete.removeAll()
            }

            // Update local state with database results FIRST
            if currentScenarioId == nil {
                // New scenario
                savedScenarios.append(savedScenario)
                currentScenarioId = savedScenario.id
                selectedScenario = savedScenario.id
            } else {
                // Update existing scenario
                if let index = savedScenarios.firstIndex(where: { $0.id == currentScenarioId }) {
                    savedScenarios[index] = savedScenario
                }
            }

            // Update scenario IDs for all items before saving them
            for (index, item) in budgetItems.enumerated() {
                budgetItems[index].scenarioId = savedScenario.id
            }

            logger.debug("Saving all \(budgetItems.count) budget items to database...")

            // Save ALL budget items (both new and existing)
            // saveBudgetDevelopmentItem() handles create vs update logic internally
            var savedCount = 0
            for (index, item) in budgetItems.enumerated() {
                do {
                    let savedItem = try await budgetStore.saveBudgetDevelopmentItem(item)
                    budgetItems[index] = savedItem // Replace local item with database version
                    savedCount += 1

                    // Remove from tracking set if it was newly created
                    if newlyCreatedItemIds.contains(item.id) {
                        newlyCreatedItemIds.remove(item.id)
                    }
                } catch {
                    logger.error("Failed to save budget item \(item.itemName)", error: error)
                    // Keep the local version if save fails
                }
            }

            logger.info("Successfully saved scenario and \(savedCount) budget items to database")
        } catch {
            logger.error("Failed to save scenario to database", error: error)
            // Fallback: save to local state only
            if currentScenarioId == nil {
                savedScenarios.append(scenarioData)
                currentScenarioId = scenarioData.id
                selectedScenario = scenarioData.id
            } else {
                if let index = savedScenarios.firstIndex(where: { $0.id == currentScenarioId }) {
                    savedScenarios[index] = scenarioData
                }
            }
        }

        // Trigger overview dashboard refresh
        await budgetStore.refreshData()
    }

    private func uploadScenario() async {
        guard currentScenarioId != nil else { return }

        uploading = true
        defer { uploading = false }

        // In a real implementation, this would update category allocations
        // based on the current scenario data

        await budgetStore.refreshData()
    }

    private func setPrimaryScenario(_ scenarioId: String) async {
        // Set all scenarios as non-primary first
        for index in savedScenarios.indices {
            savedScenarios[index].isPrimary = false
        }

        // Set selected scenario as primary
        if let index = savedScenarios.firstIndex(where: { $0.id == scenarioId }) {
            savedScenarios[index].isPrimary = true
        }

        await budgetStore.refreshData()
    }

    private func handleRenameScenario() async {
        guard !renameScenarioData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let index = savedScenarios.firstIndex(where: { $0.id == renameScenarioData.id }) else { return }

        savedScenarios[index].scenarioName = renameScenarioData.name.trimmingCharacters(in: .whitespacesAndNewlines)

        if currentScenarioId == renameScenarioData.id {
            budgetName = savedScenarios[index].scenarioName
        }

        showingRenameDialog = false
        await budgetStore.refreshData()
    }

    private func handleDuplicateScenario() async {
        guard !duplicateScenarioData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let originalScenario = savedScenarios.first(where: { $0.id == duplicateScenarioData.id }) else { return }

        let duplicateScenario = SavedScenario(
            id: UUID().uuidString,
            scenarioName: duplicateScenarioData.name.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            updatedAt: Date(),
            totalWithoutTax: originalScenario.totalWithoutTax,
            totalTax: originalScenario.totalTax,
            totalWithTax: originalScenario.totalWithTax,
            isPrimary: false,
            coupleId: originalScenario.coupleId,
            isTestData: originalScenario.isTestData)

        savedScenarios.append(duplicateScenario)
        showingDuplicateDialog = false
        await budgetStore.refreshData()
    }

    private func handleDeleteScenario() async {
        savedScenarios.removeAll { $0.id == deleteScenarioData.id }

        if currentScenarioId == deleteScenarioData.id {
            selectedScenario = "new"
            await loadScenario("new")
        }

        await budgetStore.refreshData()
    }

    // MARK: - Actions

    private func handleAddCustomTaxRate() {
        // In the Next.js version, this directs users to settings
        // We'll show an alert here
        showingTaxRateDialog = false
    }

    private func exportBudgetAsJSON() {
        let budgetData = BudgetExportData(
            name: budgetName,
            items: budgetItems,
            totals: BudgetTotals(
                totalWithoutTax: totalWithoutTax,
                totalTax: totalTax,
                totalWithTax: totalWithTax),
            exportDate: Date())

        logger.debug("Loaded \(budgetItems.count) budget items for export")
        logger.debug("Exporting budget data: \(budgetData)")

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(budgetData)

            // Create save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(budgetName.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).json"
            savePanel.message = "Export Budget as JSON"
            savePanel.prompt = "Export"

            // Show save panel and handle response
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try jsonData.write(to: url)
                        logger.info("Successfully exported budget to: \(url.path)")

                        // Show success notification
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Export Successful"
                            alert.informativeText = "Budget exported to:\n\(url.path)"
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    } catch {
                        logger.error("Failed to write budget file", error: error)

                        // Show error alert
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Export Failed"
                            alert.informativeText = "Failed to save budget file:\n\(error.localizedDescription)"
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            }
        } catch {
            logger.error("Failed to encode budget data", error: error)

            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = "Failed to encode budget data:\n\(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func exportBudgetAsCSV() {
        logger.debug("Exporting \(budgetItems.count) budget items as CSV")

        // Generate CSV string
        let csvString = generateCSVString()

        // Create save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "\(budgetName.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"
        savePanel.message = "Export Budget as CSV"
        savePanel.prompt = "Export"

        // Show save panel and handle response
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    logger.info("Successfully exported budget to: \(url.path)")

                    // Show success notification
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Export Successful"
                        alert.informativeText = "Budget exported to:\n\(url.path)\n\nYou can now open this file in Excel, Google Sheets, or any spreadsheet application."
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                } catch {
                    logger.error("Failed to write CSV file", error: error)

                    // Show error alert
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Export Failed"
                        alert.informativeText = "Failed to save CSV file:\n\(error.localizedDescription)"
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        }
    }

    // Helper function to escape CSV values
    private func escapeCSV(_ value: String) -> String {
        // If the value contains a comma, newline, or quote, wrap it in quotes and escape internal quotes
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    // MARK: - Google Export Functions

    private func signInToGoogle() async {
        do {
            try await googleIntegration.authManager.authenticate()
            logger.info("Successfully signed in to Google")

            // Show success alert
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Google Sign-In Successful"
                alert.informativeText = "You can now export to Google Drive and Google Sheets."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        } catch {
            logger.error("Failed to sign in to Google", error: error)

            // Show error alert
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Google Sign-In Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    private func exportToGoogleDrive() async {
        do {
            logger.debug("Uploading budget to Google Drive...")

            // Generate CSV data
            let csvString = generateCSVString()
            guard let csvData = csvString.data(using: .utf8) else {
                throw NSError(
                    domain: "BudgetExport",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to encode CSV data"])
            }

            let fileName = "\(budgetName.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"

            // Upload to Google Drive
            let fileId = try await googleIntegration.driveManager.uploadCSV(data: csvData, fileName: fileName)

            logger.info("Successfully uploaded to Google Drive: \(fileId)")

            // Show success alert
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Upload Successful"
                alert.informativeText = "Budget exported to Google Drive as '\(fileName)'.\n\nYou can find it in your Google Drive."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        } catch {
            logger.error("Failed to upload to Google Drive", error: error)

            // Show error alert
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Upload Failed"
                alert.informativeText = "Failed to upload to Google Drive:\n\(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    private func exportToGoogleSheets() async {
        do {
            logger.debug("Creating Google Sheet...")

            let sheetTitle = "\(budgetName) - \(Date().formatted(date: .abbreviated, time: .omitted))"

            // Create Google Sheet
            let spreadsheetId = try await googleIntegration.sheetsManager.createSpreadsheetFromBudget(
                title: sheetTitle,
                items: budgetItems,
                totals: BudgetTotals(
                    totalWithoutTax: totalWithoutTax,
                    totalTax: totalTax,
                    totalWithTax: totalWithTax),
                weddingEvents: budgetStore.weddingEvents)

            logger.info("Successfully created Google Sheet: \(spreadsheetId)")

            let sheetURL = "https://docs.google.com/spreadsheets/d/\(spreadsheetId)"

            // Show success alert with link
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Google Sheet Created"
                alert.informativeText = "Budget exported as Google Sheet.\n\n\(sheetURL)\n\nClick OK to open in browser."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open in Browser")
                alert.addButton(withTitle: "Close")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    if let url = URL(string: sheetURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        } catch {
            logger.error("Failed to create Google Sheet", error: error)

            // Show error alert
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = "Failed to create Google Sheet:\n\(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    // Helper to generate CSV string (reusable for both local and Drive export)
    private func generateCSVString() -> String {
        var csvString = "Item Name,Category,Subcategory,Events,Estimate (No Tax),Tax Rate %,Estimate (With Tax),Person Responsible,Notes\n"

        for item in budgetItems {
            let eventNames = (item.eventIds ?? [])
                .compactMap { eventId in
                    budgetStore.weddingEvents.first(where: { $0.id == eventId })?.eventName
                }
                .joined(separator: "; ")

            let row = [
                escapeCSV(item.itemName),
                escapeCSV(item.category),
                escapeCSV(item.subcategory ?? ""),
                escapeCSV(eventNames),
                String(format: "%.2f", item.vendorEstimateWithoutTax),
                String(format: "%.2f", item.taxRate),
                String(format: "%.2f", item.vendorEstimateWithTax),
                escapeCSV(item.personResponsible ?? ""),
                escapeCSV(item.notes ?? "")
            ].joined(separator: ",")

            csvString += row + "\n"
        }

        csvString += "\n"
        csvString += "SUMMARY\n"
        csvString += "Total Without Tax,,,,,,$\(String(format: "%.2f", totalWithoutTax))\n"
        csvString += "Total Tax,,,,,,$\(String(format: "%.2f", totalTax))\n"
        csvString += "Total With Tax,,,,,,$\(String(format: "%.2f", totalWithTax))\n"
        csvString += "\n"
        csvString += "Exported on,\(Date().formatted(date: .long, time: .shortened))\n"

        return csvString
    }
}

// MARK: - Data Models

struct CustomTaxRateData {
    var region: String = ""
    var taxRate: String = ""
}

struct ScenarioDialogData {
    var id: String = ""
    var name: String = ""
}

struct BudgetExportData: Codable {
    let name: String
    let items: [BudgetItem]
    let totals: BudgetTotals
    let exportDate: Date
}

struct BudgetTotals: Codable {
    let totalWithoutTax: Double
    let totalTax: Double
    let totalWithTax: Double
}

#Preview {
    BudgetDevelopmentView()
        .environmentObject(BudgetStoreV2())
}
