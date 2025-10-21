import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct BudgetDevelopmentView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @StateObject var googleIntegration = GoogleIntegrationManager()
    @StateObject var exportHelper = BudgetExportHelper()
    
    // Core state
    @State var budgetItems: [BudgetItem] = []
    @State var savedScenarios: [SavedScenario] = []
    @State var selectedScenario: String = "new"
    @State var currentScenarioId: String?
    @State var budgetName: String = "Wedding Budget Development"
    @State var selectedTaxRateId: Int64?
    @State var loading = true
    @State var saving = false
    @State var uploading = false
    
    // Track newly created items that need to be saved
    @State var newlyCreatedItemIds: Set<String> = []
    
    // Track items that need to be deleted from database
    @State var itemsToDelete: Set<String> = []
    
    let logger = AppLogger.ui
    
    // UI state
    @State var newCategoryNames: [String: String] = [:]
    @State var newSubcategoryNames: [String: String] = [:]
    @State var newEventNames: [String: String] = [:]
    @State var expandedCategories: Set<String> = Set()
    
    // Dialogs
    @State var showingTaxRateDialog = false
    @State var showingRenameDialog = false
    @State var showingDuplicateDialog = false
    @State var showingDeleteDialog = false
    
    // Dialog data
    @State var customTaxRateData = CustomTaxRateData()
    @State var renameScenarioData = ScenarioDialogData()
    @State var duplicateScenarioData = ScenarioDialogData()
    @State var deleteScenarioData = ScenarioDialogData()
    
    var body: some View {
        VStack(spacing: 0) {
            // Configuration header
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Budget summary cards
                    BudgetSummaryCardsSection(
                        totalWithoutTax: totalWithoutTax,
                        totalTax: totalTax,
                        totalWithTax: totalWithTax
                    )
                    
                    // Budget items table
                    BudgetItemsTable(
                        budgetItems: $budgetItems,
                        newCategoryNames: $newCategoryNames,
                        newSubcategoryNames: $newSubcategoryNames,
                        newEventNames: $newEventNames,
                        budgetStore: budgetStore,
                        selectedTaxRate: selectedTaxRate,
                        onAddItem: addBudgetItem,
                        onUpdateItem: updateBudgetItem,
                        onRemoveItem: removeBudgetItem,
                        onAddCategory: handleNewCategoryName,
                        onAddSubcategory: handleNewSubcategoryName,
                        onAddEvent: handleNewEventName
                    )
                    
                    // Summary sections
                    if !budgetItems.isEmpty {
                        BudgetSummaryBreakdowns(
                            expandedCategories: $expandedCategories,
                            eventBreakdown: eventBreakdown,
                            categoryBreakdown: categoryBreakdown,
                            personBreakdown: personBreakdown,
                            totalWithTax: totalWithTax
                        )
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
}
