//
//  BillCalculatorStoreV2.swift
//  I Do Blueprint
//
//  State management for Bill Calculator feature
//

import Combine
import Dependencies
import Foundation
import SwiftUI

// MARK: - Bill Calculator Store V2

@MainActor
class BillCalculatorStoreV2: ObservableObject {
    @Dependency(\.billCalculatorRepository) var repository

    @Published var loadingState: LoadingState<[BillCalculator]> = .idle
    @Published var taxInfoOptions: [TaxInfo] = []

    // Selected calculator for detail view
    @Published var selectedCalculator: BillCalculator?

    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?

    private let logger = AppLogger.database

    // MARK: - Computed Properties

    var calculators: [BillCalculator] {
        loadingState.data ?? []
    }

    var isLoading: Bool {
        loadingState.isLoading
    }

    var error: BillCalculatorError? {
        if case .error(let err) = loadingState {
            return err as? BillCalculatorError ?? .fetchFailed(underlying: err)
        }
        return nil
    }

    // MARK: - Load Calculators

    func loadCalculators() async {
        // Cancel any previous load task
        loadTask?.cancel()

        loadTask = Task { @MainActor in
            guard loadingState.isIdle || loadingState.hasError else { return }

            loadingState = .loading

            do {
                try Task.checkCancellation()

                let fetchedCalculators = try await repository.fetchCalculators()

                try Task.checkCancellation()

                loadingState = .loaded(fetchedCalculators)
            } catch is CancellationError {
                AppLogger.ui.debug("BillCalculatorStoreV2.loadCalculators: Load cancelled")
                loadingState = .idle
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("BillCalculatorStoreV2.loadCalculators: Load cancelled (URLError)")
                loadingState = .idle
            } catch {
                loadingState = .error(BillCalculatorError.fetchFailed(underlying: error))
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(operation: "loadCalculators", feature: "billCalculator")
                )
            }
        }

        await loadTask?.value
    }

    func loadCalculator(id: UUID) async -> BillCalculator? {
        do {
            let calculator = try await repository.fetchCalculator(id: id)
            selectedCalculator = calculator
            return calculator
        } catch {
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "loadCalculator",
                    feature: "billCalculator",
                    metadata: ["calculatorId": id.uuidString]
                )
            )
            return nil
        }
    }

    func loadTaxInfoOptions() async {
        do {
            let options = try await repository.fetchTaxInfoOptions()
            AppLogger.general.info("Loaded \(options.count) tax info options")
            for option in options {
                AppLogger.general.debug("Tax option: \(option.region) - \(option.taxRate)%")
            }
            taxInfoOptions = options
        } catch {
            AppLogger.general.error("Failed to load tax info options", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "loadTaxInfoOptions", feature: "billCalculator")
            )
        }
    }

    // MARK: - Create Calculator (with optimistic update)

    func createCalculator(_ calculator: BillCalculator) async -> BillCalculator? {
        // Optimistic update
        let optimisticCalculator = calculator

        if case .loaded(var currentCalculators) = loadingState {
            currentCalculators.insert(optimisticCalculator, at: 0)
            loadingState = .loaded(currentCalculators)
        }

        do {
            let created = try await repository.createCalculator(calculator)

            // Replace optimistic with real
            if case .loaded(var calculators) = loadingState,
               let index = calculators.firstIndex(where: { $0.id == calculator.id }) {
                calculators[index] = created
                loadingState = .loaded(calculators)
            }

            showSuccess("Calculator created successfully")
            return created
        } catch {
            // Rollback optimistic update
            if case .loaded(var calculators) = loadingState {
                calculators.removeAll { $0.id == calculator.id }
                loadingState = .loaded(calculators)
            }
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "createCalculator", feature: "billCalculator")
            )
            return nil
        }
    }

    // MARK: - Update Calculator (with optimistic update)

    func updateCalculator(_ calculator: BillCalculator) async -> BillCalculator? {
        guard case .loaded(var currentCalculators) = loadingState,
              let index = currentCalculators.firstIndex(where: { $0.id == calculator.id }) else {
            return nil
        }

        // Store original for rollback
        let originalCalculator = currentCalculators[index]

        // Optimistic update
        currentCalculators[index] = calculator
        loadingState = .loaded(currentCalculators)

        // Also update selectedCalculator if applicable
        if selectedCalculator?.id == calculator.id {
            selectedCalculator = calculator
        }

        do {
            let updated = try await repository.updateCalculator(calculator)

            // Update with server response
            if case .loaded(var calculators) = loadingState,
               let idx = calculators.firstIndex(where: { $0.id == calculator.id }) {
                calculators[idx] = updated
                loadingState = .loaded(calculators)
            }

            if selectedCalculator?.id == updated.id {
                selectedCalculator = updated
            }

            // Notify budget store that bill calculator changed (guest count may have changed)
            await notifyBudgetStoreOfChange(calculatorId: calculator.id)

            showSuccess("Calculator updated successfully")
            return updated
        } catch {
            // Rollback on error
            if case .loaded(var calculators) = loadingState,
               let idx = calculators.firstIndex(where: { $0.id == calculator.id }) {
                calculators[idx] = originalCalculator
                loadingState = .loaded(calculators)
            }

            if selectedCalculator?.id == calculator.id {
                selectedCalculator = originalCalculator
            }

            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "updateCalculator",
                    feature: "billCalculator",
                    metadata: ["calculatorId": calculator.id.uuidString]
                )
            )
            return nil
        }
    }

    // MARK: - Delete Calculator (with optimistic update)

    func deleteCalculator(id: UUID) async {
        guard case .loaded(var currentCalculators) = loadingState,
              let index = currentCalculators.firstIndex(where: { $0.id == id }) else {
            return
        }

        // Store for rollback
        let deletedCalculator = currentCalculators[index]
        let deletedIndex = index

        // Optimistic delete
        currentCalculators.remove(at: index)
        loadingState = .loaded(currentCalculators)

        // Clear selected if it was the deleted one
        if selectedCalculator?.id == id {
            selectedCalculator = nil
        }

        do {
            try await repository.deleteCalculator(id: id)
            showSuccess("Calculator deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var calculators) = loadingState {
                calculators.insert(deletedCalculator, at: deletedIndex)
                loadingState = .loaded(calculators)
            }

            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "deleteCalculator",
                    feature: "billCalculator",
                    metadata: ["calculatorId": id.uuidString]
                )
            )
        }
    }

    // MARK: - Item Operations

    func createItem(_ item: BillCalculatorItem) async -> BillCalculatorItem? {
        do {
            let created = try await repository.createItem(item)

            // Update the calculator's items in memory
            updateCalculatorItems(calculatorId: item.calculatorId) { items in
                items.append(created)
            }

            // Notify budget store that bill items changed
            await notifyBudgetStoreOfChange(calculatorId: item.calculatorId)

            return created
        } catch {
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "createItem",
                    feature: "billCalculator",
                    metadata: ["calculatorId": item.calculatorId.uuidString]
                )
            )
            return nil
        }
    }

    func updateItem(_ item: BillCalculatorItem) async -> BillCalculatorItem? {
        do {
            let updated = try await repository.updateItem(item)

            // Update the item in memory
            updateCalculatorItems(calculatorId: item.calculatorId) { items in
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index] = updated
                }
            }

            // Notify budget store that bill items changed
            await notifyBudgetStoreOfChange(calculatorId: item.calculatorId)

            return updated
        } catch {
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "updateItem",
                    feature: "billCalculator",
                    metadata: ["itemId": item.id.uuidString]
                )
            )
            return nil
        }
    }

    func deleteItem(id: UUID, calculatorId: UUID) async {
        do {
            try await repository.deleteItem(id: id)

            // Remove from in-memory list
            updateCalculatorItems(calculatorId: calculatorId) { items in
                items.removeAll { $0.id == id }
            }

            // Notify budget store that bill items changed
            await notifyBudgetStoreOfChange(calculatorId: calculatorId)

        } catch {
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "deleteItem",
                    feature: "billCalculator",
                    metadata: ["itemId": id.uuidString]
                )
            )
        }
    }

    func createItems(_ items: [BillCalculatorItem]) async -> [BillCalculatorItem] {
        guard !items.isEmpty else { return [] }

        do {
            let created = try await repository.createItems(items)

            // Update in-memory for each calculator
            let groupedByCalculator = Dictionary(grouping: created, by: { $0.calculatorId })
            for (calculatorId, newItems) in groupedByCalculator {
                updateCalculatorItems(calculatorId: calculatorId) { existingItems in
                    existingItems.append(contentsOf: newItems)
                }
            }

            // Notify budget store that bill items changed
            // For batch creates, use the first item's calculator ID (typically all items are for one calculator)
            await notifyBudgetStoreOfChange(calculatorId: items.first?.calculatorId)

            return created
        } catch {
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "createItems", feature: "billCalculator")
            )
            return []
        }
    }

    // MARK: - Helper Methods

    /// Updates items for a specific calculator in both the list and selected calculator
    private func updateCalculatorItems(calculatorId: UUID, update: (inout [BillCalculatorItem]) -> Void) {
        // Update in loaded list
        if case .loaded(var calculators) = loadingState,
           let index = calculators.firstIndex(where: { $0.id == calculatorId }) {
            var updatedCalculator = calculators[index]
            var items = updatedCalculator.items
            update(&items)
            updatedCalculator = BillCalculator(
                id: updatedCalculator.id,
                coupleId: updatedCalculator.coupleId,
                name: updatedCalculator.name,
                vendorId: updatedCalculator.vendorId,
                eventId: updatedCalculator.eventId,
                taxInfoId: updatedCalculator.taxInfoId,
                guestCount: updatedCalculator.guestCount,
                notes: updatedCalculator.notes,
                createdAt: updatedCalculator.createdAt,
                updatedAt: Date(),
                vendorName: updatedCalculator.vendorName,
                eventName: updatedCalculator.eventName,
                taxRate: updatedCalculator.taxRate,
                taxRegion: updatedCalculator.taxRegion,
                items: items
            )
            calculators[index] = updatedCalculator
            loadingState = .loaded(calculators)
        }

        // Update selected calculator if applicable
        if var selected = selectedCalculator, selected.id == calculatorId {
            var items = selected.items
            update(&items)
            selected = BillCalculator(
                id: selected.id,
                coupleId: selected.coupleId,
                name: selected.name,
                vendorId: selected.vendorId,
                eventId: selected.eventId,
                taxInfoId: selected.taxInfoId,
                guestCount: selected.guestCount,
                notes: selected.notes,
                createdAt: selected.createdAt,
                updatedAt: Date(),
                vendorName: selected.vendorName,
                eventName: selected.eventName,
                taxRate: selected.taxRate,
                taxRegion: selected.taxRegion,
                items: items
            )
            selectedCalculator = selected
        }
    }

    // MARK: - Convenience Methods

    func load() async {
        await loadCalculators()
    }

    func refresh() async {
        loadingState = .idle
        await loadCalculators()
    }

    func retryLoad() async {
        await loadCalculators()
    }

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        loadingState = .idle
        selectedCalculator = nil
        taxInfoOptions = []
    }

    // MARK: - Guest Count Sync

    /// Syncs guest count for all calculators in auto mode directly in the database.
    /// Called when guest RSVP changes to ensure bill calculators and linked budget items stay in sync.
    /// This method works regardless of whether calculators are loaded in memory.
    /// - Parameter newGuestCount: The new attending guest count
    func syncAutoModeCalculatorsGuestCount(_ newGuestCount: Int) async {
        do {
            // Update directly in database - works even if calculators aren't loaded
            let updatedCount = try await repository.syncAutoModeGuestCount(newGuestCount)

            if updatedCount > 0 {
                logger.info("Synced guest count (\(newGuestCount)) to \(updatedCount) auto-mode calculator(s) in database")

                // Invalidate in-memory cache if calculators are loaded
                if case .loaded(var currentCalculators) = loadingState {
                    // Update in-memory state to match database
                    for index in currentCalculators.indices {
                        if currentCalculators[index].guestCountMode == .auto {
                            var calc = currentCalculators[index]
                            calc.guestCount = newGuestCount
                            currentCalculators[index] = calc
                        }
                    }
                    loadingState = .loaded(currentCalculators)
                }

                // Notify budget store to refresh (database trigger updated linked budget items)
                await notifyBudgetStoreOfChange()
            } else {
                logger.debug("syncAutoModeCalculatorsGuestCount: No auto-mode calculators needed updating")
            }
        } catch {
            logger.error("Failed to sync auto-mode guest count", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "syncAutoModeCalculatorsGuestCount",
                    feature: "billCalculator",
                    metadata: ["newGuestCount": String(newGuestCount)]
                )
            )
        }
    }

    // MARK: - Budget Sync

    /// Notifies budget-related stores to invalidate caches and triggers recalculation.
    /// Called after bill calculator mutations because database triggers update:
    /// - Linked budget items (via sync_bill_to_linked_budget_items)
    /// - Linked expense amounts (via sync_bill_to_linked_expenses)
    /// - Parameter calculatorId: Optional bill calculator UUID for payment plan recalculation
    private func notifyBudgetStoreOfChange(calculatorId: UUID? = nil) async {
        // 1. Invalidate budget development caches (budget items updated by trigger)
        await AppStores.shared.budget.development.invalidateCachesForBillCalculatorChange()

        // 2. Invalidate expense caches and recalculate allocations (expense amounts updated by trigger)
        await AppStores.shared.budget.expenseStore.invalidateCachesForBillCalculatorChange(billCalculatorId: calculatorId)

        // 3. Recalculate linked payment plans (all types, not just async)
        if let calculatorId = calculatorId {
            await AppStores.shared.budget.payments.recalculateLinkedPlans(billCalculatorIds: [calculatorId])
        }

        logger.info("Notified budget stores of bill calculator change")
    }
}
