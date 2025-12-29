//
//  AffordabilityDataSource.swift
//  I Do Blueprint
//
//  Internal data source for affordability scenario and contribution operations.
//  Handles CRUD operations for affordability scenarios, contributions, and gift linking.
//

import Foundation
import Supabase

/// Internal actor-based data source for affordability operations
/// Provides caching, in-flight request coalescing, and comprehensive error handling
actor AffordabilityDataSource {
    private let supabase: SupabaseClient
    private nonisolated let logger = AppLogger.repository
    
    // In-flight request de-duplication
    private var inFlightScenarios: Task<[AffordabilityScenario], Error>?
    private var inFlightContributions: [UUID: Task<[ContributionItem], Error>] = [:]
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Affordability Scenarios
    
    /// Fetches all affordability scenarios for the current tenant
    /// - Parameter tenantId: The couple's tenant ID
    /// - Returns: Array of affordability scenarios sorted by creation date (newest first)
    /// - Throws: BudgetError if fetch fails
    func fetchAffordabilityScenarios(tenantId: UUID) async throws -> [AffordabilityScenario] {
        let cacheKey = "affordability_scenarios_\(tenantId.uuidString)"
        
        // Check cache first (5 min TTL)
        if let cached: [AffordabilityScenario] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: affordability scenarios (\(cached.count) items)")
            return cached
        }
        
        // Coalesce in-flight requests
        if let task = inFlightScenarios {
            return try await task.value
        }
        
        let task = Task<[AffordabilityScenario], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            
            let startTime = Date()
            
            let scenarios: [AffordabilityScenario] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("affordability_scenarios")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Only log if slow
            if duration > 1.0 {
                self.logger.info("Slow affordability scenarios fetch: \(String(format: "%.2f", duration))s for \(scenarios.count) items")
            }
            
            // Cache the result
            await RepositoryCache.shared.set(cacheKey, value: scenarios, ttl: 300)
            
            return scenarios
        }
        
        inFlightScenarios = task
        
        do {
            let result = try await task.value
            inFlightScenarios = nil
            return result
        } catch {
            inFlightScenarios = nil
            let duration = Date().timeIntervalSince(Date())
            logger.error("Affordability scenarios fetch failed after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchAffordabilityScenarios",
                "tenantId": tenantId.uuidString
            ])
            
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Saves (creates or updates) an affordability scenario
    /// - Parameter scenario: The scenario to save
    /// - Returns: The saved scenario with server-generated fields
    /// - Throws: BudgetError if save fails
    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario {
        let startTime = Date()
        
        do {
            let saved: AffordabilityScenario = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("affordability_scenarios")
                    .upsert(scenario)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Saved affordability scenario: \(saved.scenarioName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("affordability_scenarios_\(scenario.coupleId.uuidString)")
            
            return saved
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to save affordability scenario after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "saveAffordabilityScenario",
                "scenarioName": scenario.scenarioName,
                "tenantId": scenario.coupleId.uuidString
            ])
            
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Deletes an affordability scenario
    /// - Parameters:
    ///   - id: The scenario ID to delete
    ///   - tenantId: The couple's tenant ID (for cache invalidation)
    /// - Throws: BudgetError if delete fails
    func deleteAffordabilityScenario(id: UUID, tenantId: UUID) async throws {
        let startTime = Date()
        
        do {
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("affordability_scenarios")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted affordability scenario: \(id) in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("affordability_scenarios_\(tenantId.uuidString)")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete affordability scenario after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteAffordabilityScenario",
                "scenarioId": id.uuidString,
                "tenantId": tenantId.uuidString
            ])
            
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
    
    // MARK: - Affordability Contributions
    
    /// Fetches all contributions for a specific affordability scenario
    /// Combines direct contributions and linked gifts
    /// - Parameter scenarioId: The scenario ID
    /// - Returns: Array of contribution items
    /// - Throws: BudgetError if fetch fails
    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem] {
        let cacheKey = "affordability_contributions_\(scenarioId.uuidString)"
        
        // Check cache first (5 min TTL)
        if let cached: [ContributionItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            #if DEBUG
            logger.debug("Cache hit: affordability_contributions for scenario \(scenarioId) - \(cached.count) items")
            #endif
            return cached
        }
        
        // Coalesce in-flight requests
        if let task = inFlightContributions[scenarioId] {
            return try await task.value
        }
        
        let task = Task<[ContributionItem], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            
            #if DEBUG
            self.logger.debug("Fetching affordability contributions for scenario \(scenarioId)...")
            self.logger.debug("Cache miss - fetching fresh data from database")
            #endif
            
            // Fetch direct contributions from affordability_gifts_contributions
            let directContributions: [ContributionItem]
            do {
                directContributions = try await self.supabase
                    .from("affordability_gifts_contributions")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .order("contribution_date", ascending: false)
                    .execute()
                    .value
                #if DEBUG
                self.logger.debug("Fetched \(directContributions.count) direct contributions")
                #endif
            } catch {
                self.logger.error("Error fetching direct contributions", error: error)
                throw error
            }
            
            // Fetch linked gifts from gifts_and_owed
            let linkedGifts: [GiftOrOwed]
            do {
                linkedGifts = try await self.supabase
                    .from("gifts_and_owed")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .execute()
                    .value
                #if DEBUG
                self.logger.debug("Fetched \(linkedGifts.count) linked gifts")
                for gift in linkedGifts {
                    self.logger.debug("Gift ID: \(gift.id), Title: \(gift.title), From: \(gift.fromPerson ?? "N/A")")
                }
                #endif
            } catch {
                self.logger.error("Error fetching linked gifts", error: error)
                throw error
            }
            
            #if DEBUG
            self.logger.debug("Found \(directContributions.count) direct contributions and \(linkedGifts.count) linked gifts")
            #endif
            
            // Convert linked gifts to ContributionItems
            let giftContributions = linkedGifts.map { gift in
                ContributionItem(
                    id: gift.id,
                    scenarioId: scenarioId,
                    contributorName: gift.fromPerson ?? gift.title,
                    amount: gift.amount,
                    contributionDate: gift.receivedDate ?? gift.expectedDate ?? Date(),
                    contributionType: gift.type == .giftReceived ? .gift : .external,
                    notes: gift.description,
                    coupleId: gift.coupleId,
                    createdAt: gift.createdAt ?? Date(),
                    updatedAt: gift.updatedAt
                )
            }
            
            // Combine both sources
            let contributions = directContributions + giftContributions
            
            await RepositoryCache.shared.set(cacheKey, value: contributions, ttl: 300)
            #if DEBUG
            self.logger.debug("Cached \(contributions.count) contributions")
            #endif
            
            return contributions
        }
        
        inFlightContributions[scenarioId] = task
        
        do {
            let result = try await task.value
            inFlightContributions.removeValue(forKey: scenarioId)
            return result
        } catch {
            inFlightContributions.removeValue(forKey: scenarioId)
            logger.error("Affordability contributions fetch failed", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchAffordabilityContributions",
                "scenarioId": scenarioId.uuidString
            ])
            
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Saves (creates or updates) an affordability contribution
    /// - Parameter contribution: The contribution to save
    /// - Returns: The saved contribution with server-generated fields
    /// - Throws: BudgetError if save fails
    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem {
        let startTime = Date()
        
        do {
            let saved: ContributionItem = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("affordability_gifts_contributions")
                    .upsert(contribution)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Saved contribution from: \(saved.contributorName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("affordability_contributions_\(contribution.scenarioId.uuidString)")
            
            return saved
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to save contribution after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "saveAffordabilityContribution",
                "contributorName": contribution.contributorName,
                "scenarioId": contribution.scenarioId.uuidString
            ])
            
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Deletes an affordability contribution
    /// - Parameters:
    ///   - id: The contribution ID to delete
    ///   - scenarioId: The scenario ID (for cache invalidation)
    /// - Throws: BudgetError if delete fails
    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws {
        let startTime = Date()
        
        do {
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("affordability_gifts_contributions")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted contribution: \(id) in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId.uuidString)")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete contribution after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteAffordabilityContribution",
                "contributionId": id.uuidString,
                "scenarioId": scenarioId.uuidString
            ])
            
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
    
    // MARK: - Gift Linking
    
    /// Links multiple gifts to an affordability scenario
    /// - Parameters:
    ///   - giftIds: Array of gift IDs to link
    ///   - scenarioId: The scenario ID to link to
    /// - Throws: BudgetError if linking fails
    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws {
        let startTime = Date()
        
        do {
            for giftId in giftIds {
                try await RepositoryNetwork.withRetry { [self] in
                    try await self.supabase
                        .from("gifts_and_owed")
                        .update(["scenario_id": scenarioId])
                        .eq("id", value: giftId)
                        .execute()
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Linked \(giftIds.count) gifts to scenario \(scenarioId) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches
            await RepositoryCache.shared.remove("gifts_and_owed")
            await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId.uuidString)")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to link gifts after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "linkGiftsToScenario",
                "giftCount": giftIds.count,
                "scenarioId": scenarioId.uuidString
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Unlinks a gift from an affordability scenario
    /// - Parameters:
    ///   - giftId: The gift ID to unlink
    ///   - scenarioId: The scenario ID (for cache invalidation)
    /// - Throws: BudgetError if unlinking fails
    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws {
        let startTime = Date()
        
        do {
            let response = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("gifts_and_owed")
                    .update(["scenario_id": AnyJSON.null])
                    .eq("id", value: giftId)
                    .select()
                    .execute()
            }
            
            // Verify the update worked by checking response status
            let affectedRows = (try? JSONDecoder().decode([GiftOrOwed].self, from: response.data).count) ?? 0
            
            let duration = Date().timeIntervalSince(startTime)
            
            if affectedRows == 0 {
                logger.warning("No rows updated - gift may not exist or already unlinked")
            } else {
                logger.info("Unlinked gift \(giftId) from scenario \(scenarioId) in \(String(format: "%.2f", duration))s")
            }
            
            // Invalidate caches
            await RepositoryCache.shared.remove("gifts_and_owed")
            await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId.uuidString)")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to unlink gift after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "unlinkGiftFromScenario",
                "giftId": giftId.uuidString,
                "scenarioId": scenarioId.uuidString
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
}
