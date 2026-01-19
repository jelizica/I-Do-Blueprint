//
//  GiftAllocationService.swift
//  I Do Blueprint
//
//  Handles gift allocation calculations and redistribution.
//  Mirrors BudgetAllocationService pattern for proportional gift allocation.
//

import Foundation

// MARK: - GiftAllocationServiceProtocol

/// Business logic for recalculating proportional gift allocations.
protocol GiftAllocationServiceProtocol: Sendable {
    /// Recalculates proportional allocations when a budget item amount changes within a scenario.
    func recalculateGiftAllocations(budgetItemId: String, scenarioId: String) async throws

    /// Recalculates proportional allocations for a single gift within a specific scenario.
    func recalculateGiftAllocations(giftId: UUID, scenarioId: String) async throws

    /// Recalculates proportional allocations for a gift across all scenarios using the new amount.
    func recalculateGiftAllocationsForAllScenarios(giftId: UUID, newAmount: Double) async throws

    /// Adds or links a gift to a budget item and rebalances all allocations proportionally
    /// across all linked items in the scenario.
    func linkGiftProportionally(gift: GiftOrOwed, to budgetItemId: String, inScenario scenarioId: String) async throws
}

// MARK: - GiftAllocationService

/// Handles complex gift allocation calculations and redistribution.
actor GiftAllocationService: GiftAllocationServiceProtocol {
    private let repository: BudgetRepositoryProtocol
    private let logger = AppLogger.general

    init(repository: BudgetRepositoryProtocol) {
        self.repository = repository
    }

    // Adds or links a gift to a budget item, then rebalances allocations proportionally
    func linkGiftProportionally(gift: GiftOrOwed, to budgetItemId: String, inScenario scenarioId: String) async throws {
        logger.info("[GiftAllocationService] Linking gift \(gift.id) to item \(budgetItemId) with proportional rebalance in scenario \(scenarioId)")

        // 1) Fetch existing allocations for this gift in the scenario
        let existing = try await repository.fetchAllocationsForGift(giftId: gift.id, scenarioId: scenarioId)

        // 2) Compute the affected item ids (existing + new)
        var affectedItemIds = Set(existing.map { $0.budgetItemId.lowercased() })
        affectedItemIds.insert(budgetItemId.lowercased())

        // 3) Fetch scenario items to get budgeted amounts for affected ids
        let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        let budgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
        let keys = affectedItemIds.filter { budgetById[$0] != nil }
        let totalBudgeted = keys.compactMap { budgetById[$0] }.reduce(0, +)

        // 4) Build new allocation set using proportional weights (fallback: 100% to target item)
        let coupleId = existing.first?.coupleId ?? items.first?.coupleId.uuidString ?? ""
        let isTest = existing.first?.isTestData
        let amount = gift.amount

        var allocations: [GiftAllocation] = []
        if totalBudgeted > 0 {
            // Round to cents and fix rounding residue on the last element
            var remaining = amount
            for (idx, key) in keys.enumerated() {
                let weight = budgetById[key]! / totalBudgeted
                var value = amount * weight
                // round to 2 decimals
                value = (value * 100).rounded() / 100
                if idx == keys.count - 1 { value = (remaining * 100).rounded() / 100 }
                remaining -= value
                allocations.append(
                    GiftAllocation(
                        id: UUID().uuidString,
                        giftId: gift.id.uuidString,
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
            // If we can't compute weights, allocate entire amount to the requested item
            allocations = [
                GiftAllocation(
                    id: UUID().uuidString,
                    giftId: gift.id.uuidString,
                    budgetItemId: budgetItemId,
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

        // 5) Atomically replace allocations
        try await repository.replaceGiftAllocations(giftId: gift.id, scenarioId: scenarioId, with: allocations)
    }

    // Recalculates proportional allocations when a budget item amount changes
    func recalculateGiftAllocations(budgetItemId: String, scenarioId: String) async throws {
        logger.info("[GiftAllocationService] Recalculating gift allocations for budget item \(budgetItemId) in scenario \(scenarioId)")

        // 1) Fetch allocations linked to this budget item to discover affected gifts
        let allocationsForItem = try await repository.fetchGiftAllocations(scenarioId: scenarioId, budgetItemId: budgetItemId)
        guard !allocationsForItem.isEmpty else { return }
        let affectedGiftIds = Array(Set(allocationsForItem.compactMap { UUID(uuidString: $0.giftId) }))

        // 2) Fetch all gifts and items in scenario for proportion calculations
        async let giftsAsync = repository.fetchGiftsAndOwed()
        async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        let (allGifts, items) = try await (giftsAsync, itemsAsync)
        let giftAmountById = Dictionary(uniqueKeysWithValues: allGifts.map { ($0.id, $0.amount) })
        let itemBudgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })

        // 3) For each gift, recompute proportions and replace
        for giftId in affectedGiftIds {
            // a) Fetch all allocations for this gift within the scenario
            let allocations = try await repository.fetchAllocationsForGift(giftId: giftId, scenarioId: scenarioId)
            guard allocations.count > 1 else { continue }

            // b) Compute proportions using budgeted amounts for each allocation's item
            let keys = allocations.map { $0.budgetItemId.lowercased() }
            let totalBudgeted = keys.compactMap { itemBudgetById[$0] }.reduce(0, +)
            guard totalBudgeted > 0 else { continue }

            let amount = giftAmountById[giftId] ?? 0
            let baseCoupleId = allocations.first?.coupleId ?? ""
            let isTest = allocations.first?.isTestData

            let newAllocations: [GiftAllocation] = allocations.compactMap { alloc in
                guard let budgeted = itemBudgetById[alloc.budgetItemId.lowercased()] else { return nil }
                let proportion = budgeted / totalBudgeted
                return GiftAllocation(
                    id: UUID().uuidString,
                    giftId: giftId.uuidString,
                    budgetItemId: alloc.budgetItemId,
                    allocatedAmount: amount * proportion,
                    percentage: nil,
                    notes: nil,
                    createdAt: Date(),
                    updatedAt: nil,
                    coupleId: baseCoupleId,
                    scenarioId: scenarioId,
                    isTestData: isTest
                )
            }

            try await repository.replaceGiftAllocations(giftId: giftId, scenarioId: scenarioId, with: newAllocations)
        }
    }

    // Recalculates allocations when a gift amount changes (single scenario)
    func recalculateGiftAllocations(giftId: UUID, scenarioId: String) async throws {
        logger.info("[GiftAllocationService] Recalculating allocations for gift \(giftId) in scenario \(scenarioId)")

        // Fetch allocations and scenario items
        async let allocationsAsync = repository.fetchAllocationsForGift(giftId: giftId, scenarioId: scenarioId)
        async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        async let giftsAsync = repository.fetchGiftsAndOwed()
        let (allocations, items, gifts) = try await (allocationsAsync, itemsAsync, giftsAsync)
        guard allocations.count > 1 else { return }

        let itemBudgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
        let giftAmount = gifts.first(where: { $0.id == giftId })?.amount ?? 0
        let baseCoupleId = allocations.first?.coupleId ?? ""
        let isTest = allocations.first?.isTestData

        let keys = allocations.map { $0.budgetItemId.lowercased() }
        let totalBudgeted = keys.compactMap { itemBudgetById[$0] }.reduce(0, +)
        guard totalBudgeted > 0 else { return }

        let newAllocations: [GiftAllocation] = allocations.compactMap { alloc in
            guard let budgeted = itemBudgetById[alloc.budgetItemId.lowercased()] else { return nil }
            let proportion = budgeted / totalBudgeted
            return GiftAllocation(
                id: UUID().uuidString,
                giftId: giftId.uuidString,
                budgetItemId: alloc.budgetItemId,
                allocatedAmount: giftAmount * proportion,
                percentage: nil,
                notes: nil,
                createdAt: Date(),
                updatedAt: nil,
                coupleId: baseCoupleId,
                scenarioId: scenarioId,
                isTestData: isTest
            )
        }

        try await repository.replaceGiftAllocations(giftId: giftId, scenarioId: scenarioId, with: newAllocations)
    }

    func recalculateGiftAllocationsForAllScenarios(giftId: UUID, newAmount: Double) async throws {
        logger.info("[GiftAllocationService] Recalculating allocations for gift \(giftId) across all scenarios")
        // Fetch all allocations for the gift across scenarios
        let allAllocations = try await repository.fetchAllocationsForGiftAllScenarios(giftId: giftId)
        guard !allAllocations.isEmpty else { return }
        let groups = Dictionary(grouping: allAllocations, by: { $0.scenarioId })

        // For each scenario, compute using scenario's items
        for (scenarioId, allocations) in groups {
            let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            let itemBudgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
            let baseCoupleId = allocations.first?.coupleId ?? ""
            let isTest = allocations.first?.isTestData

            let keys = allocations.map { $0.budgetItemId.lowercased() }
            let totalBudgeted = keys.compactMap { itemBudgetById[$0] }.reduce(0, +)
            guard totalBudgeted > 0 else { continue }

            let newAllocations: [GiftAllocation] = allocations.compactMap { alloc in
                guard let budgeted = itemBudgetById[alloc.budgetItemId.lowercased()] else { return nil }
                let proportion = budgeted / totalBudgeted
                return GiftAllocation(
                    id: UUID().uuidString,
                    giftId: giftId.uuidString,
                    budgetItemId: alloc.budgetItemId,
                    allocatedAmount: newAmount * proportion,
                    percentage: nil,
                    notes: nil,
                    createdAt: Date(),
                    updatedAt: nil,
                    coupleId: baseCoupleId,
                    scenarioId: scenarioId,
                    isTestData: isTest
                )
            }

            try await repository.replaceGiftAllocations(giftId: giftId, scenarioId: scenarioId, with: newAllocations)
        }
    }
}
