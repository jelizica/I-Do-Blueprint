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

    // Bill calculator linking state
    @State var linkingBudgetItem: BudgetItem?
    @State var billCalculators: [BillCalculator] = []
    @State var existingLinkedBillIds: Set<UUID> = []

    // Track pending bill calculator link changes (deferred until Save)
    // Maps budget item ID to array of linked bill calculator IDs
    @State var pendingBillLinks: [String: [UUID]] = [:]
    // Track items that need their bill links cleared on save
    @State var pendingBillUnlinks: Set<String> = []

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

            ZStack {
                // Glassmorphism background matching Vendor/Guest pages
                MeshGradientBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Unified header bar - compact 56px style matching Budget Overview
                    BudgetDevelopmentUnifiedHeader(
                        windowSize: windowSize,
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

                    // Budget summary cards - OUTSIDE scroll view (matches Budget Overview)
                    BudgetSummaryCardsSection(
                        windowSize: windowSize,
                        totalWithoutTax: totalWithoutTax,
                        totalTax: totalTax,
                        totalWithTax: totalWithTax
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.md : Spacing.lg)

                    ScrollView {
                        VStack(spacing: windowSize == .compact ? Spacing.lg : 24) {
                            // Budget items table - only render if tenant ID is available
                        if SessionManager.shared.currentTenantId != nil {
                            if isLoadingScenario {
                                // Loading state with spinner - matches table glassmorphism
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
                                .padding()
                                .glassContainer(cornerRadius: 12)
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
                                    responsibleOptions: personOptions,
                                    onLinkBillCalculator: { itemId in
                                        // Find the budget item and fetch linked bill IDs before opening modal
                                        if let item = budgetItems.first(where: { $0.id == itemId }) {
                                            Task {
                                                await fetchLinkedBillIds(for: item)
                                                linkingBudgetItem = item
                                            }
                                        }
                                    },
                                    onUnlinkBillCalculator: { itemId in
                                        Task {
                                            await unlinkBillCalculator(fromItemId: itemId)
                                        }
                                    },
                                    onEditLinkedBill: { billId in
                                        // Navigate to bill calculator - this would typically use the app coordinator
                                        // For now, log the action
                                        logger.info("Edit linked bill requested: \(billId)")
                                    },
                                    getLinkedBillCalculators: { itemId in
                                        // For now, return single bill from legacy link
                                        // This will be updated to fetch from junction table
                                        guard let item = budgetItems.first(where: { $0.id == itemId }),
                                              let linkedId = item.linkedBillCalculatorId,
                                              let bill = billCalculators.first(where: { $0.id == linkedId }) else {
                                            return []
                                        }
                                        return [bill]
                                    }
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
            } // end VStack
            } // end ZStack
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
        .sheet(item: $linkingBudgetItem) { item in
            BillCalculatorLinkModal(
                budgetItem: item,
                onDismiss: {
                    existingLinkedBillIds = []
                    linkingBudgetItem = nil
                },
                onLinkComplete: { billCalculatorIds in
                    linkBillCalculators(billCalculatorIds, toItemId: item.id)
                    existingLinkedBillIds = []
                    linkingBudgetItem = nil
                },
                onUnlinkAll: {
                    unlinkBillCalculator(fromItemId: item.id)
                    existingLinkedBillIds = []
                    linkingBudgetItem = nil
                },
                existingLinkedBillIds: existingLinkedBillIds
            )
            .environmentObject(budgetStore)
            .environmentObject(settingsStore)
        }
        .task {
            // Load bill calculators for linking
            await loadBillCalculators()
        }
    }

    // MARK: - Bill Calculator Linking

    private func loadBillCalculators() async {
        await AppStores.shared.billCalculator.loadCalculators()
        billCalculators = AppStores.shared.billCalculator.calculators
    }

    /// Links multiple bill calculators to a budget item (local state only - persisted on Save)
    /// - Parameters:
    ///   - billCalculatorIds: Array of bill calculator IDs to link
    ///   - itemId: The budget item ID to link to
    private func linkBillCalculators(_ billCalculatorIds: [UUID], toItemId itemId: String) {
        guard !billCalculatorIds.isEmpty else {
            logger.warning("No bill calculators selected for linking")
            return
        }

        guard let index = budgetItems.firstIndex(where: { $0.id == itemId }) else {
            logger.error("Budget item not found: \(itemId)")
            return
        }

        // Calculate combined subtotal from selected bill calculators
        let selectedBills = billCalculators.filter { billCalculatorIds.contains($0.id) }
        let combinedSubtotal = selectedBills.reduce(0.0) { $0 + $1.subtotal }

        // Update local budget item state
        var item = budgetItems[index]

        // Store original amount if not already stored (for revert capability)
        if item.preLinkAmount == nil {
            item.preLinkAmount = item.vendorEstimateWithoutTax
        }

        // Update amounts with combined bill subtotal
        item.vendorEstimateWithoutTax = combinedSubtotal
        item.vendorEstimateWithTax = combinedSubtotal * (1 + item.taxRate / 100)

        // Set linked bill calculator ID (first one for UI indicator)
        item.linkedBillCalculatorId = billCalculatorIds.first

        budgetItems[index] = item

        // Track pending link for persistence on Save
        pendingBillLinks[itemId] = billCalculatorIds
        pendingBillUnlinks.remove(itemId)

        logger.info("Linked \(billCalculatorIds.count) bill(s) to budget item \(itemId) (local state, pending save)")
    }

    /// Fetches the existing linked bill IDs for a budget item
    /// Checks pending local links first, then falls back to junction table
    private func fetchLinkedBillIds(for item: BudgetItem) async {
        // Check if there are pending (unsaved) links for this item
        if let pendingIds = pendingBillLinks[item.id] {
            existingLinkedBillIds = Set(pendingIds)
            logger.info("Using \(pendingIds.count) pending (unsaved) link(s) for budget item \(item.id)")
            return
        }

        // Check if item is pending unlink
        if pendingBillUnlinks.contains(item.id) {
            existingLinkedBillIds = []
            logger.info("Item \(item.id) has pending unlink")
            return
        }

        // Fetch from junction table (persisted links)
        do {
            let links = try await budgetStore.development.fetchBillCalculatorLinks(forBudgetItem: item.id)
            existingLinkedBillIds = Set(links.map { $0.billCalculatorId })
            logger.info("Fetched \(links.count) linked bill(s) for budget item \(item.id)")
        } catch {
            // Fall back to legacy single link if junction table fetch fails
            if let linkedId = item.linkedBillCalculatorId {
                existingLinkedBillIds = [linkedId]
                logger.warning("Fell back to legacy link for budget item \(item.id)")
            } else {
                existingLinkedBillIds = []
            }
            logger.error("Failed to fetch linked bill IDs", error: error)
        }
    }

    /// Unlinks all bill calculators from a budget item (local state only - persisted on Save)
    private func unlinkBillCalculator(fromItemId itemId: String) {
        guard let index = budgetItems.firstIndex(where: { $0.id == itemId }) else {
            logger.error("Budget item not found for unlink: \(itemId)")
            return
        }

        var item = budgetItems[index]

        // Restore original amount if available
        let revertAmount = item.preLinkAmount ?? 0
        item.vendorEstimateWithoutTax = revertAmount
        item.vendorEstimateWithTax = revertAmount * (1 + item.taxRate / 100)

        // Clear link fields
        item.linkedBillCalculatorId = nil
        item.preLinkAmount = nil

        budgetItems[index] = item

        // Track pending unlink for persistence on Save
        pendingBillUnlinks.insert(itemId)
        pendingBillLinks.removeValue(forKey: itemId)

        logger.info("Unlinked all bills from budget item \(itemId) (local state, pending save)")
    }
}
