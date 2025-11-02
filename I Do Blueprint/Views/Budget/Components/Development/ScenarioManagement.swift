//
//  ScenarioManagement.swift
//  I Do Blueprint
//
//  Scenario management operations for budget development
//

import Foundation

// MARK: - Scenario Management

extension BudgetDevelopmentView {
    
    // MARK: Data Loading
    
    func loadInitialData() async {
        loading = true
        defer { loading = false }
        
        await budgetStore.loadBudgetData()
        
        // Load tax rates from settings
        if !settingsStore.hasLoaded {
            await settingsStore.loadSettings()
        }
        budgetStore.loadTaxRatesFromSettings(settingsStore.settings.budget.taxRates)
        
        await fetchSavedScenarios()
        
        if let firstRate = budgetStore.taxRates.first {
            selectedTaxRateId = firstRate.id
        }
        
        // Auto-select the first scenario if available
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
    
    func fetchSavedScenarios() async {
        savedScenarios = budgetStore.savedScenarios
    }
    
    func loadScenario(_ scenarioId: String) async {
        if scenarioId == "new" {
            await MainActor.run {
                budgetItems = []
                budgetName = "Wedding Budget Development"
                currentScenarioId = nil
                newlyCreatedItemIds.removeAll()
            }
            return
        }
        
        if let scenario = savedScenarios.first(where: { $0.id == scenarioId }) {
            let items = await budgetStore.loadBudgetDevelopmentItems(scenarioId: scenarioId)
            
            await MainActor.run {
                budgetName = scenario.scenarioName
                currentScenarioId = scenario.id
                budgetItems = items
                newlyCreatedItemIds.removeAll()
            }
        } else {
            logger.warning("Scenario not found: \(scenarioId)")
        }
    }
    
    // MARK: Save Scenario
    
    func saveScenario() async {
        saving = true
        defer { saving = false }
        
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
            // Delete items marked for deletion first (if any existing items were removed)
            if !itemsToDelete.isEmpty {
                for itemId in itemsToDelete {
                    do {
                        try await budgetStore.deleteBudgetDevelopmentItem(id: itemId)
                    } catch {
                        logger.error("Failed to delete item \(itemId)", error: error)
                    }
                }
                itemsToDelete.removeAll()
            }
            
            // Call atomic save (scenario first, then items)
            let (persistedScenarioId, insertedCount) = try await budgetStore.saveScenarioWithItems(scenarioData, items: budgetItems)
            
            // Update local state
            if currentScenarioId == nil {
                savedScenarios.append(scenarioData)
                currentScenarioId = persistedScenarioId
                selectedScenario = persistedScenarioId
            } else {
                if let index = savedScenarios.firstIndex(where: { $0.id == currentScenarioId }) {
                    savedScenarios[index] = scenarioData
                }
                currentScenarioId = persistedScenarioId
            }
            
            // Update scenario IDs for all items locally
            for index in budgetItems.indices {
                budgetItems[index].scenarioId = persistedScenarioId
            }
            newlyCreatedItemIds.removeAll()
            
            logger.info("Successfully saved scenario and \(insertedCount) budget items to database")
        } catch {
            logger.error("Failed to save scenario to database", error: error)
            
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
        
        await budgetStore.refresh()
    }
    
    func uploadScenario() async {
        guard currentScenarioId != nil else { return }
        
        uploading = true
        defer { uploading = false }
        
        await budgetStore.refresh()
    }
    
    // MARK: Scenario Operations
    
    func setPrimaryScenario(_ scenarioId: String) async {
        for index in savedScenarios.indices {
            savedScenarios[index].isPrimary = false
        }
        
        if let index = savedScenarios.firstIndex(where: { $0.id == scenarioId }) {
            savedScenarios[index].isPrimary = true
        }
        
        await budgetStore.refresh()
    }
    
    func handleRenameScenario() async {
        guard !renameScenarioData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let index = savedScenarios.firstIndex(where: { $0.id == renameScenarioData.id }) else { return }
        
        savedScenarios[index].scenarioName = renameScenarioData.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if currentScenarioId == renameScenarioData.id {
            budgetName = savedScenarios[index].scenarioName
        }
        
        showingRenameDialog = false
        await budgetStore.refresh()
    }
    
    func handleDuplicateScenario() async {
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
        await budgetStore.refresh()
    }
    
    func handleDeleteScenario() async {
        savedScenarios.removeAll { $0.id == deleteScenarioData.id }
        
        if currentScenarioId == deleteScenarioData.id {
            selectedScenario = "new"
            await loadScenario("new")
        }
        
        await budgetStore.refresh()
    }
}
