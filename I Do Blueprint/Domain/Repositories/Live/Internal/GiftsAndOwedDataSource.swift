//
//  GiftsAndOwedDataSource.swift
//  I Do Blueprint
//
//  Internal data source for gifts, gifts received, and money owed operations
//  Extracted from LiveBudgetRepository for better maintainability
//

import Foundation
import Supabase

/// Internal data source handling all gifts, gifts received, and money owed CRUD operations
/// This is not exposed publicly - all access goes through BudgetRepositoryProtocol
actor GiftsAndOwedDataSource {
    private let supabase: SupabaseClient
    private let logger = AppLogger.repository

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // MARK: - Gifts and Owed Operations

    func fetchGiftsAndOwed(tenantId: UUID) async throws -> [GiftOrOwed] {
        let cacheKey = "gifts_and_owed_\(tenantId.uuidString)"

        if let cached: [GiftOrOwed] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let startTime = Date()

        let items: [GiftOrOwed] = try await RepositoryNetwork.withRetry {
            try await self.supabase
                .from("gifts_and_owed")
                .select()
                .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                .order("created_at", ascending: false)
                .execute()
                .value
        }

        let duration = Date().timeIntervalSince(startTime)

        // Only log if slow
        if duration > 1.0 {
            logger.info("Slow gifts/owed fetch: \(String(format: "%.2f", duration))s for \(items.count) items")
        }

        await RepositoryCache.shared.set(cacheKey, value: items)

        return items
    }

    func createGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        do {
            let startTime = Date()

            let created: GiftOrOwed = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("gifts_and_owed")
                    .insert(gift)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created gift/owed: \(created.title)")

            // Invalidate cache with tenant ID
            await RepositoryCache.shared.remove("gifts_and_owed_\(gift.coupleId.uuidString)")
            if let scenarioId = gift.scenarioId {
                await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")
            }

            return created
        } catch {
            logger.error("Failed to create gift/owed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createGiftOrOwed",
                "dataSource": "GiftsAndOwedDataSource"
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        do {
            let startTime = Date()

            // Create updated gift object with new timestamp
            var updated = gift
            updated.updatedAt = Date()

            let result: GiftOrOwed = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("gifts_and_owed")
                    .update(updated)
                    .eq("id", value: gift.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated gift/owed: \(result.title)")

            // Invalidate cache with tenant ID
            await RepositoryCache.shared.remove("gifts_and_owed_\(gift.coupleId.uuidString)")
            if let scenarioId = gift.scenarioId {
                await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")
            }

            return result
        } catch {
            logger.error("Failed to update gift/owed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateGiftOrOwed",
                "dataSource": "GiftsAndOwedDataSource",
                "giftId": gift.id.uuidString
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteGiftOrOwed(id: UUID) async throws {
        do {
            let startTime = Date()

            // Fetch the gift first to get couple_id and scenario_id for proper cache invalidation
            let gifts: [GiftOrOwed] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("gifts_and_owed")
                    .select()
                    .eq("id", value: id)
                    .limit(1)
                    .execute()
                    .value
            }
            let gift = gifts.first

            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("gifts_and_owed")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted gift/owed: \(id)")

            // Invalidate cache with tenant ID
            if let gift = gift {
                await RepositoryCache.shared.remove("gifts_and_owed_\(gift.coupleId.uuidString)")
                if let scenarioId = gift.scenarioId {
                    await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")
                }
            }
        } catch {
            logger.error("Failed to delete gift/owed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteGiftOrOwed",
                "dataSource": "GiftsAndOwedDataSource",
                "giftId": id.uuidString
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Gift Received Operations

    func fetchGiftsReceived() async throws -> [GiftReceived] {
        let cacheKey = "gifts_received"

        if let cached: [GiftReceived] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let startTime = Date()

        let gifts: [GiftReceived] = try await RepositoryNetwork.withRetry {
            try await self.supabase
                .from("gift_received")
                .select()
                .order("date_received", ascending: false)
                .execute()
                .value
        }

        let duration = Date().timeIntervalSince(startTime)

        // Only log if slow
        if duration > 1.0 {
            logger.info("Slow gifts received fetch: \(String(format: "%.2f", duration))s for \(gifts.count) items")
        }

        await RepositoryCache.shared.set(cacheKey, value: gifts)

        return gifts
    }

    func createGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        do {
            let startTime = Date()

            let created: GiftReceived = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("gift_received")
                    .insert(gift)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created gift received from: \(created.fromPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_received")

            return created
        } catch {
            logger.error("Failed to create gift received", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createGiftReceived",
                "dataSource": "GiftsAndOwedDataSource"
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        do {
            let startTime = Date()

            // Create updated gift object with new timestamp
            var updated = gift
            updated.updatedAt = Date()

            let result: GiftReceived = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("gift_received")
                    .update(updated)
                    .eq("id", value: gift.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated gift received from: \(result.fromPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_received")

            return result
        } catch {
            logger.error("Failed to update gift received", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateGiftReceived",
                "dataSource": "GiftsAndOwedDataSource",
                "giftId": gift.id.uuidString
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteGiftReceived(id: UUID) async throws {
        do {
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("gift_received")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted gift received: \(id)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_received")
        } catch {
            logger.error("Failed to delete gift received", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteGiftReceived",
                "dataSource": "GiftsAndOwedDataSource",
                "giftId": id.uuidString
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Money Owed Operations

    func fetchMoneyOwed() async throws -> [MoneyOwed] {
        let cacheKey = "money_owed"

        if let cached: [MoneyOwed] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let startTime = Date()

        let items: [MoneyOwed] = try await RepositoryNetwork.withRetry {
            try await self.supabase
                .from("money_owed")
                .select()
                .order("is_paid", ascending: true)
                .order("due_date", ascending: true, nullsFirst: false)
                .execute()
                .value
        }

        let duration = Date().timeIntervalSince(startTime)

        // Only log if slow
        if duration > 1.0 {
            logger.info("Slow money owed fetch: \(String(format: "%.2f", duration))s for \(items.count) items")
        }

        await RepositoryCache.shared.set(cacheKey, value: items)

        return items
    }

    func createMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        do {
            let startTime = Date()

            let created: MoneyOwed = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("money_owed")
                    .insert(money)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created money owed to: \(created.toPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("money_owed")

            return created
        } catch {
            logger.error("Failed to create money owed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createMoneyOwed",
                "dataSource": "GiftsAndOwedDataSource"
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        do {
            let startTime = Date()

            // Create updated money object with new timestamp
            var updated = money
            updated.updatedAt = Date()

            let result: MoneyOwed = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("money_owed")
                    .update(updated)
                    .eq("id", value: money.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated money owed to: \(result.toPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("money_owed")

            return result
        } catch {
            logger.error("Failed to update money owed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateMoneyOwed",
                "dataSource": "GiftsAndOwedDataSource",
                "moneyId": money.id.uuidString
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteMoneyOwed(id: UUID) async throws {
        do {
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("money_owed")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            _ = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted money owed: \(id)")

            // Invalidate cache
            await RepositoryCache.shared.remove("money_owed")
        } catch {
            logger.error("Failed to delete money owed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteMoneyOwed",
                "dataSource": "GiftsAndOwedDataSource",
                "moneyId": id.uuidString
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
}
