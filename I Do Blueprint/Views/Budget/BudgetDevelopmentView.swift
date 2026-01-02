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
    
    /// Binding to parent's currentPage for unified header navigation
    /// When nil, uses internal state (for standalone usage via BudgetPage.view)
    var externalCurrentPage: Binding<BudgetPage>?
    
    /// Internal state for standalone usage
    @State private var internalCurrentPage: BudgetPage = .budgetBuilder
    
    /// Computed binding that uses external if available, otherwise internal
    private var currentPage: Binding<BudgetPage> {
        externalCurrentPage ?? $internalCurrentPage
    }
    
    /// Convenience initializer with external binding (used by BudgetDashboardHubView)
    init(currentPage: Binding<BudgetPage>) {
        self.externalCurrentPage = currentPage
    }
    
    /// Default initializer for standalone usage (used by BudgetPage.view)
    init() {
        self.externalCurrentPage = nil
    }

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
    @State var isLoadingScenario = false

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
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            
            VStack(spacing: 0) {
                // Unified header with "Budget" title, "Budget Development" subtitle, ellipsis menu, and nav dropdown
                BudgetDevelopmentUnifiedHeader(
                    windowSize: windowSize,
                    currentPage: currentPage,
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
                    VStack(spacing: windowSize == .compact ? Spacing.lg : 24) {
                        // Budget summary cards
                        BudgetSummaryCardsSection(
                            windowSize: windowSize,
                            totalWithoutTax: totalWithoutTax,
                            totalTax: totalTax,
                            totalWithTax: totalWithTax
                        )

                        // Budget items table - only render if tenant ID is available
                        if SessionManager.shared.currentTenantId != nil {
                            if isLoadingScenario {
                                // Loading state with spinner
                                VStack(spacing: Spacing.lg) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .progressViewStyle(.circular)
                                    
                                    Text("Loading scenario...")
                                        .font(.seatingBody)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(12)
                            } else {
                                BudgetItemsTable(
                                windowSize: windowSize,
                                budgetItems: $budgetItems,
                                newCategoryNames: $newCategoryNames,
                                newSubcategoryNames: $newSubcategoryNames,
                                newEventNames: $newEventNames,
                                budgetStore: budgetStore,
                                selectedTaxRate: selectedTaxRate,
                                currentScenarioId: currentScenarioId,
                                coupleId: SessionManager.shared.currentTenantId!.uuidString,
                                onAddItem: addBudgetItem,
                                onUpdateItem: updateBudgetItem,
                                onRemoveItem: removeBudgetItem,
                                onAddCategory: handleNewCategoryName,
                                onAddSubcategory: handleNewSubcategoryName,
                                onAddEvent: handleNewEventName,
                                onAddFolder: addFolder,
                                responsibleOptions: personOptions
                                )
                            }
                        } else {
                            // Error state when no tenant is selected
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.orange)
                                
                                Text("No Wedding Selected")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Please select your wedding couple to continue working on your budget.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 400)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.huge)
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                        }

                        // Summary sections
                        if !budgetItems.isEmpty {
                            BudgetSummaryBreakdowns(
                                windowSize: windowSize,
                                expandedCategories: $expandedCategories,
                                eventBreakdown: eventBreakdown,
                                categoryBreakdown: categoryBreakdown,
                                categoryItems: categoryItems,
                                personBreakdown: personBreakdown,
                                totalWithTax: totalWithTax,
                                responsibleOptions: personOptions
                            )
                        }
                    }
                    .frame(width: availableWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                }
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
