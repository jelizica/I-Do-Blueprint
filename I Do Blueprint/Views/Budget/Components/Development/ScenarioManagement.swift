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
        // Set loading state at the start
        await MainActor.run {
            isLoadingScenario = true
        }
        
        if scenarioId == "new" {
            await MainActor.run {
                budgetItems = []
                budgetName = "Wedding Budget Development"
                currentScenarioId = nil
                newlyCreatedItemIds.removeAll()
                isLoadingScenario = false
            }
            return
        }

        if let scenario = savedScenarios.first(where: { $0.id == scenarioId }) {
            let items = await budgetStore.development.loadBudgetDevelopmentItems(scenarioId: scenarioId)

            await MainActor.run {
                budgetName = scenario.scenarioName
                currentScenarioId = scenario.id
                budgetItems = items
                newlyCreatedItemIds.removeAll()
                isLoadingScenario = false
            }
        } else {
            logger.warning("Scenario not found: \(scenarioId)")
            await MainActor.run {
                isLoadingScenario = false
            }
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
            coupleId: coupleId,  // ✅ Pass UUID directly
            isTestData: false)

        do {
            // Delete items marked for deletion first (if any existing items were removed)
            if !itemsToDelete.isEmpty {
                for itemId in itemsToDelete {
                    do {
                        try await budgetStore.development.deleteBudgetDevelopmentItem(id: itemId)
                    } catch {
                        logger.error("Failed to delete item \(itemId)", error: error)
                    }
                }
                itemsToDelete.removeAll()
            }

            // Call atomic save (scenario first, then items)
            let (persistedScenarioId, insertedCount) = try await budgetStore.development.saveScenarioWithItems(scenarioData, items: budgetItems)

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

            // Reload the scenario from the database to ensure we have the latest data
            // This is critical for ensuring tax rates and other fields are properly reflected
            await loadScenario(persistedScenarioId)
            
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
        // Capture original primary for potential rollback
        let originalPrimaryIndex = savedScenarios.firstIndex(where: { $0.isPrimary })

        // Find the index of the scenario to make primary
        guard let index = savedScenarios.firstIndex(where: { $0.id == scenarioId }) else {
            logger.warning("Cannot set primary scenario: scenario not found: \(scenarioId)")
            // Restore original primary if exists (defensive)
            if let originalIndex = originalPrimaryIndex {
                savedScenarios[originalIndex].isPrimary = true
            }
            return
        }

        // If the selected is already primary, nothing to do
        if originalPrimaryIndex == index {
            return
        }

        // Update local state: mark previous primary false and new one true
        if let originalIndex = originalPrimaryIndex {
            savedScenarios[originalIndex].isPrimary = false
        }
        savedScenarios[index].isPrimary = true

        // Persist only the changed scenarios to the database
        do {
            // Update only the affected scenarios
            if let originalIndex = originalPrimaryIndex, originalIndex != index {
                _ = try await budgetStore.development.updateBudgetDevelopmentScenario(savedScenarios[originalIndex])
            }
            _ = try await budgetStore.development.updateBudgetDevelopmentScenario(savedScenarios[index])

            logger.info("Successfully set primary scenario: \(savedScenarios[index].scenarioName)")
        } catch {
            logger.error("Failed to set primary scenario", error: error)

            // Restore original primary state on error
            if let originalIndex = originalPrimaryIndex {
                // Revert the two affected entries
                savedScenarios[originalIndex].isPrimary = true
            }
            // Ensure the new index is not primary
            savedScenarios[index].isPrimary = false
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
