//
//  GiftsStore.swift
//  I Do Blueprint
//
//  Extracted from BudgetStoreV2 as part of JES-42
//  Manages gifts and money owed operations with database persistence
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Store for managing gifts and money owed
/// Handles tracking of gifts received, money owed, and related operations
@MainActor
class GiftsStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var giftsAndOwed: [GiftOrOwed] = []
    @Published private(set) var giftsReceived: [GiftReceived] = []
    @Published private(set) var moneyOwed: [MoneyOwed] = []
    @Published var isLoading = false
    @Published var error: BudgetError?

    // MARK: - Dependencies

    @Dependency(\.budgetRepository) var repository
    private let logger = AppLogger.database

    // MARK: - Computed Properties

    /// Total amount of pending gifts and money owed
    var totalPending: Double {
        giftsAndOwed.reduce(0) { $0 + $1.amount }
    }

    /// Total amount of gifts received
    var totalReceived: Double {
        giftsReceived.reduce(0) { $0 + $1.amount }
    }

    /// Total amount of confirmed gifts
    var totalConfirmed: Double {
        giftsAndOwed.filter { $0.status == .confirmed }.reduce(0) { $0 + $1.amount }
    }

    /// Total budget addition from all gifts
    var totalBudgetAddition: Double {
        totalReceived + totalConfirmed
    }

    /// Gifts that are confirmed
    var confirmedGifts: [GiftOrOwed] {
        giftsAndOwed.filter { $0.status == .confirmed }
    }

    /// Gifts that are pending
    var pendingGifts: [GiftOrOwed] {
        giftsAndOwed.filter { $0.status == .pending }
    }

    // MARK: - Public Methods

    /// Load all gifts data including gifts received and money owed
    func loadGiftsData() async {
        do {
            async let giftsAndOwedTask = repository.fetchGiftsAndOwed()
            async let giftsReceivedTask = repository.fetchGiftsReceived()
            async let moneyOwedTask = repository.fetchMoneyOwed()

            giftsAndOwed = try await giftsAndOwedTask
            giftsReceived = try await giftsReceivedTask
            moneyOwed = try await moneyOwedTask

            logger.info("Loaded gifts data: \(giftsAndOwed.count) gifts/owed, \(giftsReceived.count) received, \(moneyOwed.count) owed")
        } catch {
            await handleError(error, operation: "loadGiftsData")
            self.error = .fetchFailed(underlying: error)
        }
    }

    // MARK: - Gifts and Owed Operations

    /// Add a new gift or owed item with database persistence
    func addGiftOrOwed(_ gift: GiftOrOwed) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createGiftOrOwed(gift)
            giftsAndOwed.append(created)
            logger.info("Added gift or owed: \(created.id)")
        } catch {
            await handleError(error, operation: "addGiftOrOwed") { [weak self] in
                await self?.addGiftOrOwed(gift)
            }
            self.error = .createFailed(underlying: error)
        }

        isLoading = false
    }

    /// Update an existing gift or owed item with database persistence
    func updateGiftOrOwed(_ gift: GiftOrOwed) async {
        isLoading = true
        error = nil

        do {
            let updated = try await repository.updateGiftOrOwed(gift)
            if let index = giftsAndOwed.firstIndex(where: { $0.id == updated.id }) {
                giftsAndOwed[index] = updated
            }
            logger.info("Updated gift or owed: \(updated.id)")
        } catch {
            await handleError(error, operation: "updateGiftOrOwed", context: [
                "giftId": gift.id.uuidString
            ]) { [weak self] in
                await self?.updateGiftOrOwed(gift)
            }
            self.error = .updateFailed(underlying: error)
        }

        isLoading = false
    }

    /// Delete a gift or owed item with database persistence
    func deleteGiftOrOwed(id: UUID) async {
        isLoading = true
        error = nil

        do {
            try await repository.deleteGiftOrOwed(id: id)
            giftsAndOwed.removeAll { $0.id == id }
            logger.info("Deleted gift or owed: \(id)")
        } catch {
            await handleError(error, operation: "deleteGiftOrOwed", context: [
                "giftId": id.uuidString
            ]) { [weak self] in
                await self?.deleteGiftOrOwed(id: id)
            }
            self.error = .deleteFailed(underlying: error)
        }

        isLoading = false
    }

    // MARK: - Gifts Received Operations

    /// Add a new gift received with database persistence
    func addGiftReceived(_ gift: GiftReceived) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createGiftReceived(gift)
            giftsReceived.append(created)
            logger.info("Added gift received: \(created.id)")
        } catch {
            await handleError(error, operation: "addGiftReceived") { [weak self] in
                await self?.addGiftReceived(gift)
            }
            self.error = .createFailed(underlying: error)
        }

        isLoading = false
    }

    /// Update an existing gift received with database persistence
    func updateGiftReceived(_ gift: GiftReceived) async {
        isLoading = true
        error = nil

        do {
            let updated = try await repository.updateGiftReceived(gift)
            if let index = giftsReceived.firstIndex(where: { $0.id == updated.id }) {
                giftsReceived[index] = updated
            }
            logger.info("Updated gift received: \(updated.id)")
        } catch {
            await handleError(error, operation: "updateGiftReceived", context: [
                "giftId": gift.id.uuidString
            ]) { [weak self] in
                await self?.updateGiftReceived(gift)
            }
            self.error = .updateFailed(underlying: error)
        }

        isLoading = false
    }

    /// Delete a gift received with database persistence
    func deleteGiftReceived(id: UUID) async {
        isLoading = true
        error = nil

        do {
            try await repository.deleteGiftReceived(id: id)
            giftsReceived.removeAll { $0.id == id }
            logger.info("Deleted gift received: \(id)")
        } catch {
            await handleError(error, operation: "deleteGiftReceived", context: [
                "giftId": id.uuidString
            ]) { [weak self] in
                await self?.deleteGiftReceived(id: id)
            }
            self.error = .deleteFailed(underlying: error)
        }

        isLoading = false
    }

    // MARK: - Money Owed Operations

    /// Add a new money owed item with database persistence
    func addMoneyOwed(_ money: MoneyOwed) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createMoneyOwed(money)
            moneyOwed.append(created)
            logger.info("Added money owed: \(created.id)")
        } catch {
            await handleError(error, operation: "addMoneyOwed") { [weak self] in
                await self?.addMoneyOwed(money)
            }
            self.error = .createFailed(underlying: error)
        }

        isLoading = false
    }

    /// Update an existing money owed item with database persistence
    func updateMoneyOwed(_ money: MoneyOwed) async {
        isLoading = true
        error = nil

        do {
            let updated = try await repository.updateMoneyOwed(money)
            if let index = moneyOwed.firstIndex(where: { $0.id == updated.id }) {
                moneyOwed[index] = updated
            }
            logger.info("Updated money owed: \(updated.id)")
        } catch {
            await handleError(error, operation: "updateMoneyOwed", context: [
                "moneyId": money.id.uuidString
            ]) { [weak self] in
                await self?.updateMoneyOwed(money)
            }
            self.error = .updateFailed(underlying: error)
        }

        isLoading = false
    }

    /// Delete a money owed item with database persistence
    func deleteMoneyOwed(id: UUID) async {
        isLoading = true
        error = nil

        do {
            try await repository.deleteMoneyOwed(id: id)
            moneyOwed.removeAll { $0.id == id }
            logger.info("Deleted money owed: \(id)")
        } catch {
            await handleError(error, operation: "deleteMoneyOwed", context: [
                "moneyId": id.uuidString
            ]) { [weak self] in
                await self?.deleteMoneyOwed(id: id)
            }
            self.error = .deleteFailed(underlying: error)
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    /// Get gifts linked to a specific scenario
    func giftsLinkedToScenario(_ scenarioId: UUID) -> [GiftOrOwed] {
        giftsAndOwed.filter { $0.scenarioId == scenarioId }
    }

    /// Get unlinked gifts (not associated with any scenario)
    var unlinkedGifts: [GiftOrOwed] {
        giftsAndOwed.filter { $0.scenarioId == nil }
    }

    /// Get total amount of gifts linked to a scenario
    func totalGiftsForScenario(_ scenarioId: UUID) -> Double {
        giftsLinkedToScenario(scenarioId).reduce(0) { $0 + $1.amount }
    }

    // MARK: - Gift Linking Operations

    /// Unlink a gift from a budget item
    /// - Parameters:
    ///   - giftId: The gift UUID string
    ///   - budgetItemId: The budget item UUID string
    ///   - scenarioId: The scenario UUID string used for precise cache invalidation
    func unlinkGift(giftId: String, budgetItemId: String, scenarioId: String) async throws {
        // Proportional unlink: remove the specified item from the gift's allocation set,
        // then rebalance the remaining items proportionally by their budgeted amounts.
        guard let giftUUID = UUID(uuidString: giftId) else {
            let errorInfo = [NSLocalizedDescriptionKey: "Invalid gift UUID"]
            let error = NSError(domain: "GiftsStore", code: -1, userInfo: errorInfo)
            throw BudgetError.updateFailed(underlying: error)
        }

        do {
            logger.info("Starting proportional unlink for gift_id=\(giftId), removing budget_item_id=\(budgetItemId) in scenario=\(scenarioId)")

            async let allocationsAsync = repository.fetchAllocationsForGift(giftId: giftUUID, scenarioId: scenarioId)
            async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            let (existing, items) = try await (allocationsAsync, itemsAsync)

            // Exclude the removed item
            let removeKey = budgetItemId.lowercased()
            var remainingIds = existing.map { $0.budgetItemId.lowercased() }.filter { $0 != removeKey }

            // If nothing remains, replace with empty set (fully unlinked)
            if remainingIds.isEmpty {
                try await repository.replaceGiftAllocations(giftId: giftUUID, scenarioId: scenarioId, with: [])
            } else {
                // Build weights from remaining items' vendorEstimateWithTax
                let budgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
                // Keep only ids that exist in items
                remainingIds = remainingIds.filter { budgetById[$0] != nil }

                let totalBudgeted = remainingIds.compactMap { budgetById[$0] }.reduce(0, +)
                let amount = giftsAndOwed.first(where: { $0.id == giftUUID })?.amount ?? 0
                let coupleId = existing.first?.coupleId ?? items.first?.coupleId.uuidString ?? ""
                let isTest = existing.first?.isTestData

                var newAllocations: [GiftAllocation] = []
                if totalBudgeted > 0 {
                    var remaining = amount
                    for (idx, key) in remainingIds.enumerated() {
                        let weight = budgetById[key]! / totalBudgeted
                        var value = amount * weight
                        value = (value * 100).rounded() / 100 // round to cents
                        if idx == remainingIds.count - 1 { value = (remaining * 100).rounded() / 100 }
                        remaining -= value
                        newAllocations.append(
                            GiftAllocation(
                                id: UUID().uuidString,
                                giftId: giftUUID.uuidString,
                                budgetItemId: key,
                                allocatedAmount: value,
                                percentage: nil,
                                notes: nil,
                                createdAt: Date(),
                                updatedAt: nil,
                                coupleId: coupleId,
                                scenarioId: scenarioId,
                                isTestData: isTest
                            )
                        )
                    }
                } else {
                    // If we cannot compute weights, allocate 100% to the first remaining item
                    let target = remainingIds.first!
                    newAllocations = [
                        GiftAllocation(
                            id: UUID().uuidString,
                            giftId: giftUUID.uuidString,
                            budgetItemId: target,
                            allocatedAmount: amount,
                            percentage: nil,
                            notes: nil,
                            createdAt: Date(),
                            updatedAt: nil,
                            coupleId: coupleId,
                            scenarioId: scenarioId,
                            isTestData: isTest
                        )
                    ]
                }

                try await repository.replaceGiftAllocations(giftId: giftUUID, scenarioId: scenarioId, with: newAllocations)
            }

            // Invalidate related caches synchronously
            // Note: scenarioId should NOT be lowercased - it must match the exact cache key format
            await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            await RepositoryCache.shared.invalidatePrefix("gift_allocations_")
            await RepositoryCache.shared.invalidatePrefix("budget_overview_items_")
            await RepositoryCache.shared.invalidatePrefix("budget_dev_items_")
            if let tenantId = SessionManager.shared.getTenantId()?.uuidString {
                await RepositoryCache.shared.remove("gifts_and_owed_\(tenantId)")
            }

            logger.info("Gift proportional unlink complete and caches invalidated for scenarioId=\(scenarioId)")
        } catch {
            await handleError(error, operation: "unlinkGift", context: [
                "giftId": giftId,
                "budgetItemId": budgetItemId,
                "scenarioId": scenarioId
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    // MARK: - Partial Contribution Support

    /// Record a partial contribution payment
    /// - Parameters:
    ///   - contribution: The contribution to record a partial payment for
    ///   - amountReceived: The amount received in this payment
    /// - Returns: The updated contribution
    @discardableResult
    func recordPartialContribution(contribution: GiftOrOwed, amountReceived: Double) async -> GiftOrOwed? {
        isLoading = true
        error = nil

        var updated = contribution
        let newAmountReceived = contribution.amountReceived + amountReceived
        updated.amountReceived = newAmountReceived
        updated.paymentRecordedAt = Date()
        updated.updatedAt = Date()

        // Determine status based on amount received
        if newAmountReceived >= contribution.amount {
            updated.status = .received
            updated.receivedDate = Date()
        } else if newAmountReceived > 0 {
            updated.status = .partial
        }

        do {
            let result = try await repository.updateGiftOrOwed(updated)
            if let index = giftsAndOwed.firstIndex(where: { $0.id == result.id }) {
                giftsAndOwed[index] = result
            }
            logger.info("Recorded partial contribution: \(result.id), amount: \(amountReceived), total received: \(newAmountReceived)")
            isLoading = false
            return result
        } catch {
            await handleError(error, operation: "recordPartialContribution", context: [
                "contributionId": contribution.id.uuidString,
                "amountReceived": String(amountReceived)
            ]) { [weak self] in
                await self?.recordPartialContribution(contribution: contribution, amountReceived: amountReceived)
            }
            self.error = .updateFailed(underlying: error)
            isLoading = false
            return nil
        }
    }

    /// Mark a contribution as fully received (shortcut for full payment)
    /// - Parameter contribution: The contribution to mark as received
    @discardableResult
    func markAsReceived(_ contribution: GiftOrOwed) async -> GiftOrOwed? {
        var updated = contribution
        updated.status = .received
        updated.amountReceived = contribution.amount
        updated.receivedDate = Date()
        updated.paymentRecordedAt = Date()
        updated.updatedAt = Date()

        do {
            let result = try await repository.updateGiftOrOwed(updated)
            if let index = giftsAndOwed.firstIndex(where: { $0.id == result.id }) {
                giftsAndOwed[index] = result
            }
            logger.info("Marked contribution as received: \(result.id)")
            return result
        } catch {
            await handleError(error, operation: "markAsReceived", context: [
                "contributionId": contribution.id.uuidString
            ])
            self.error = .updateFailed(underlying: error)
            return nil
        }
    }

    /// Reset a contribution back to pending status
    /// - Parameter contribution: The contribution to reset
    @discardableResult
    func markAsPending(_ contribution: GiftOrOwed) async -> GiftOrOwed? {
        var updated = contribution
        updated.status = .pending
        updated.amountReceived = 0
        updated.receivedDate = nil
        updated.paymentRecordedAt = nil
        updated.updatedAt = Date()

        do {
            let result = try await repository.updateGiftOrOwed(updated)
            if let index = giftsAndOwed.firstIndex(where: { $0.id == result.id }) {
                giftsAndOwed[index] = result
            }
            logger.info("Reset contribution to pending: \(result.id)")
            return result
        } catch {
            await handleError(error, operation: "markAsPending", context: [
                "contributionId": contribution.id.uuidString
            ])
            self.error = .updateFailed(underlying: error)
            return nil
        }
    }

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        giftsAndOwed = []
        giftsReceived = []
        moneyOwed = []
    }
}
