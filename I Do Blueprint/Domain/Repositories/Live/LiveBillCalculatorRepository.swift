//
//  LiveBillCalculatorRepository.swift
//  I Do Blueprint
//
//  Production implementation of BillCalculatorRepositoryProtocol with caching
//

import Foundation
import Supabase

/// Production implementation of BillCalculatorRepositoryProtocol
actor LiveBillCalculatorRepository: BillCalculatorRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    private let cacheStrategy = BillCalculatorCacheStrategy()

    // SessionManager for tenant scoping
    private let sessionManager: SessionManager

    // In-flight request de-duplication
    private var inFlightCalculators: [UUID: Task<[BillCalculator], Error>] = [:]

    init(supabase: SupabaseClient? = nil, sessionManager: SessionManager = .shared) {
        self.supabase = supabase
        self.sessionManager = sessionManager
    }

    // Convenience initializer using SupabaseManager
    init() {
        supabase = SupabaseManager.shared.client
        sessionManager = .shared
    }

    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    // Helper to get tenant ID
    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }

    // MARK: - Calculator Operations

    func fetchCalculators() async throws -> [BillCalculator] {
        let tenantId = try await getTenantId()
        let cacheKey = CacheConfiguration.KeyPrefix.billCalculator.key(tenantId: tenantId)

        // Check cache first
        if let cached: [BillCalculator] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: bill calculators (\(cached.count) items)")
            return cached
        }

        // Coalesce in-flight requests per-tenant
        if let task = inFlightCalculators[tenantId] {
            return try await task.value
        }

        let task = Task<[BillCalculator], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            let client = try await self.getClient()
            let startTime = Date()
            self.logger.info("Cache miss: fetching bill calculators from database")

            // Fetch calculators with joined data
            let calculatorRows: [BillCalculatorRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculators")
                    .select("""
                        *,
                        vendor_information(vendor_name),
                        wedding_events(event_name),
                        tax_info(tax_rate, region)
                    """)
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            // Fetch all items for these calculators
            let calculatorIds = calculatorRows.map { $0.id }
            var itemsByCalculator: [UUID: [BillCalculatorItem]] = [:]

            if !calculatorIds.isEmpty {
                let items: [BillCalculatorItem] = try await RepositoryNetwork.withRetry {
                    try await client
                        .from("bill_calculator_items")
                        .select()
                        .eq("couple_id", value: tenantId)
                        .execute()
                        .value
                }

                for item in items {
                    itemsByCalculator[item.calculatorId, default: []].append(item)
                }
            }

            // Combine calculators with their items
            let calculators = calculatorRows.map { row in
                row.toBillCalculator(items: itemsByCalculator[row.id] ?? [])
            }

            let duration = Date().timeIntervalSince(startTime)
            await RepositoryCache.shared.set(cacheKey, value: calculators, ttl: 60)
            await PerformanceMonitor.shared.recordOperation("fetchBillCalculators", duration: duration)
            self.logger.info("Fetched \(calculators.count) bill calculators in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchBillCalculators", outcome: .success, duration: duration)
            return calculators
        }

        inFlightCalculators[tenantId] = task
        do {
            let result = try await task.value
            inFlightCalculators[tenantId] = nil
            return result
        } catch {
            inFlightCalculators[tenantId] = nil
            logger.error("Failed to fetch bill calculators", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchBillCalculators",
                "repository": "LiveBillCalculatorRepository"
            ])
            throw BillCalculatorError.fetchFailed(underlying: error)
        }
    }

    func fetchCalculator(id: UUID) async throws -> BillCalculator {
        let tenantId = try await getTenantId()
        let cacheKey = CacheConfiguration.KeyPrefix.billCalculatorDetail.key(tenantId: tenantId, id: id.uuidString)

        // Check cache first
        if let cached: BillCalculator = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: bill calculator detail")
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        // Fetch calculator with joined data
        let row: BillCalculatorRow = try await RepositoryNetwork.withRetry {
            try await client
                .from("bill_calculators")
                .select("""
                    *,
                    vendor_information(vendor_name),
                    wedding_events(event_name),
                    tax_info(tax_rate, region)
                """)
                .eq("id", value: id)
                .eq("couple_id", value: tenantId)
                .single()
                .execute()
                .value
        }

        // Fetch items for this calculator
        let items: [BillCalculatorItem] = try await RepositoryNetwork.withRetry {
            try await client
                .from("bill_calculator_items")
                .select()
                .eq("calculator_id", value: id)
                .eq("couple_id", value: tenantId)
                .order("sort_order", ascending: true)
                .execute()
                .value
        }

        let calculator = row.toBillCalculator(items: items)

        let duration = Date().timeIntervalSince(startTime)
        await RepositoryCache.shared.set(cacheKey, value: calculator, ttl: 60)
        await PerformanceMonitor.shared.recordOperation("fetchBillCalculator", duration: duration)
        logger.info("Fetched bill calculator in \(String(format: "%.2f", duration))s")

        return calculator
    }

    func fetchCalculatorsByVendor(vendorId: Int64) async throws -> [BillCalculator] {
        let tenantId = try await getTenantId()
        let cacheKey = "bill_calculators_vendor_\(tenantId.uuidString)_\(vendorId)"

        // Check cache first
        if let cached: [BillCalculator] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: bill calculators for vendor \(vendorId) (\(cached.count) items)")
            return cached
        }

        let client = try getClient()
        let startTime = Date()
        logger.info("Cache miss: fetching bill calculators for vendor \(vendorId) from database")

        // Fetch calculators with joined data filtered by vendor_id
        let calculatorRows: [BillCalculatorRow] = try await RepositoryNetwork.withRetry {
            try await client
                .from("bill_calculators")
                .select("""
                    *,
                    vendor_information(vendor_name),
                    wedding_events(event_name),
                    tax_info(tax_rate, region)
                """)
                .eq("couple_id", value: tenantId)
                .eq("vendor_id", value: String(vendorId))
                .order("created_at", ascending: false)
                .execute()
                .value
        }

        // Fetch all items for these calculators
        let calculatorIds = calculatorRows.map { $0.id }
        var itemsByCalculator: [UUID: [BillCalculatorItem]] = [:]

        if !calculatorIds.isEmpty {
            let items: [BillCalculatorItem] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .select()
                    .in("calculator_id", values: calculatorIds)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            for item in items {
                itemsByCalculator[item.calculatorId, default: []].append(item)
            }
        }

        // Combine calculators with their items
        let calculators = calculatorRows.map { row in
            row.toBillCalculator(items: itemsByCalculator[row.id] ?? [])
        }

        let duration = Date().timeIntervalSince(startTime)
        await RepositoryCache.shared.set(cacheKey, value: calculators, ttl: 60)
        await PerformanceMonitor.shared.recordOperation("fetchBillCalculatorsByVendor", duration: duration)
        logger.info("Fetched \(calculators.count) bill calculators for vendor \(vendorId) in \(String(format: "%.2f", duration))s")
        AnalyticsService.trackNetwork(operation: "fetchBillCalculatorsByVendor", outcome: .success, duration: duration)

        return calculators
    }

    func createCalculator(_ calculator: BillCalculator) async throws -> BillCalculator {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            // Insert calculator
            let insertData = BillCalculatorInsertData(from: calculator)
            let createdRow: BillCalculatorRow = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculators")
                    .insert(insertData)
                    .select("""
                        *,
                        vendor_information(vendor_name),
                        wedding_events(event_name),
                        tax_info(tax_rate, region)
                    """)
                    .single()
                    .execute()
                    .value
            }

            // Insert items if any
            var createdItems: [BillCalculatorItem] = []
            if !calculator.items.isEmpty {
                let itemsToInsert = calculator.items.map { item in
                    BillCalculatorItemInsertData(from: BillCalculatorItem(
                        id: item.id,
                        calculatorId: createdRow.id,
                        coupleId: tenantId,
                        type: item.type,
                        name: item.name,
                        amount: item.amount,
                        sortOrder: item.sortOrder
                    ))
                }

                createdItems = try await RepositoryNetwork.withRetry {
                    try await client
                        .from("bill_calculator_items")
                        .insert(itemsToInsert)
                        .select()
                        .execute()
                        .value
                }
            }

            let created = createdRow.toBillCalculator(items: createdItems)

            // Invalidate caches
            await cacheStrategy.invalidate(for: .billCalculatorCreated(tenantId: tenantId, calculatorId: created.id))

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("createBillCalculator", duration: duration)
            logger.info("Created bill calculator in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "createBillCalculator", outcome: .success, duration: duration)

            return created
        } catch {
            logger.error("Failed to create bill calculator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createBillCalculator",
                "repository": "LiveBillCalculatorRepository"
            ])
            throw BillCalculatorError.createFailed(underlying: error)
        }
    }

    func updateCalculator(_ calculator: BillCalculator) async throws -> BillCalculator {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            // Update calculator metadata
            let updateData = BillCalculatorInsertData(from: calculator)
            let updatedRow: BillCalculatorRow = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculators")
                    .update(updateData)
                    .eq("id", value: calculator.id)
                    .eq("couple_id", value: tenantId)
                    .select("""
                        *,
                        vendor_information(vendor_name),
                        wedding_events(event_name),
                        tax_info(tax_rate, region)
                    """)
                    .single()
                    .execute()
                    .value
            }

            // Fetch existing items from database to compare
            let existingItems: [BillCalculatorItem] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .select()
                    .eq("calculator_id", value: calculator.id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            let existingIds = Set(existingItems.map { $0.id })
            let localIds = Set(calculator.items.map { $0.id })

            // Find items to delete (exist in DB but not in local state)
            let itemsToDelete = existingIds.subtracting(localIds)
            for itemId in itemsToDelete {
                try await RepositoryNetwork.withRetry {
                    try await client
                        .from("bill_calculator_items")
                        .delete()
                        .eq("id", value: itemId)
                        .eq("couple_id", value: tenantId)
                        .execute()
                }
                logger.debug("Deleted item \(itemId.uuidString)")
            }

            // Find items to insert (exist in local state but not in DB)
            let itemsToInsert = calculator.items.filter { !existingIds.contains($0.id) }
            if !itemsToInsert.isEmpty {
                let insertData = itemsToInsert.map { item in
                    BillCalculatorItemInsertData(from: BillCalculatorItem(
                        id: item.id,
                        calculatorId: calculator.id,
                        coupleId: tenantId,
                        type: item.type,
                        name: item.name,
                        amount: item.amount,
                        sortOrder: item.sortOrder
                    ))
                }
                try await RepositoryNetwork.withRetry {
                    try await client
                        .from("bill_calculator_items")
                        .insert(insertData)
                        .execute()
                }
                logger.debug("Inserted \(itemsToInsert.count) new items")
            }

            // Find items to update (exist in both)
            let itemsToUpdate = calculator.items.filter { existingIds.contains($0.id) }
            for item in itemsToUpdate {
                let updateItemData = BillCalculatorItemUpdateData(from: item)
                try await RepositoryNetwork.withRetry {
                    try await client
                        .from("bill_calculator_items")
                        .update(updateItemData)
                        .eq("id", value: item.id)
                        .eq("couple_id", value: tenantId)
                        .execute()
                }
            }
            if !itemsToUpdate.isEmpty {
                logger.debug("Updated \(itemsToUpdate.count) existing items")
            }

            // Fetch final items state
            let finalItems: [BillCalculatorItem] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .select()
                    .eq("calculator_id", value: calculator.id)
                    .eq("couple_id", value: tenantId)
                    .order("sort_order", ascending: true)
                    .execute()
                    .value
            }

            let updated = updatedRow.toBillCalculator(items: finalItems)

            // Invalidate caches
            await cacheStrategy.invalidate(for: .billCalculatorUpdated(tenantId: tenantId, calculatorId: calculator.id))

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("updateBillCalculator", duration: duration)
            logger.info("Updated bill calculator in \(String(format: "%.2f", duration))s (deleted: \(itemsToDelete.count), inserted: \(itemsToInsert.count), updated: \(itemsToUpdate.count))")
            AnalyticsService.trackNetwork(operation: "updateBillCalculator", outcome: .success, duration: duration)

            return updated
        } catch {
            logger.error("Failed to update bill calculator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateBillCalculator",
                "repository": "LiveBillCalculatorRepository",
                "calculatorId": calculator.id.uuidString
            ])
            throw BillCalculatorError.updateFailed(underlying: error)
        }
    }

    func deleteCalculator(id: UUID) async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            // Items are cascade deleted
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculators")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
            }

            // Invalidate caches
            await cacheStrategy.invalidate(for: .billCalculatorDeleted(tenantId: tenantId, calculatorId: id))

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("deleteBillCalculator", duration: duration)
            logger.info("Deleted bill calculator in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteBillCalculator", outcome: .success, duration: duration)
        } catch {
            logger.error("Failed to delete bill calculator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteBillCalculator",
                "repository": "LiveBillCalculatorRepository",
                "calculatorId": id.uuidString
            ])
            throw BillCalculatorError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Item Operations

    func createItem(_ item: BillCalculatorItem) async throws -> BillCalculatorItem {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let insertData = BillCalculatorItemInsertData(from: item)
            let created: BillCalculatorItem = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate caches
            await cacheStrategy.invalidate(for: .billCalculatorItemCreated(tenantId: tenantId, calculatorId: item.calculatorId))

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("createBillCalculatorItem", duration: duration)
            logger.info("Created bill calculator item in \(String(format: "%.2f", duration))s")

            return created
        } catch {
            logger.error("Failed to create bill calculator item", error: error)
            throw BillCalculatorError.itemCreateFailed(underlying: error)
        }
    }

    func updateItem(_ item: BillCalculatorItem) async throws -> BillCalculatorItem {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let updateData = BillCalculatorItemUpdateData(from: item)
            let updated: BillCalculatorItem = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .update(updateData)
                    .eq("id", value: item.id)
                    .eq("couple_id", value: tenantId)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate caches
            await cacheStrategy.invalidate(for: .billCalculatorItemUpdated(tenantId: tenantId, calculatorId: item.calculatorId))

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("updateBillCalculatorItem", duration: duration)
            logger.info("Updated bill calculator item in \(String(format: "%.2f", duration))s")

            return updated
        } catch {
            logger.error("Failed to update bill calculator item", error: error)
            throw BillCalculatorError.itemUpdateFailed(underlying: error)
        }
    }

    func deleteItem(id: UUID) async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            // First get the item to know the calculator ID for cache invalidation
            let item: BillCalculatorItem = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .select()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .single()
                    .execute()
                    .value
            }

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
            }

            // Invalidate caches
            await cacheStrategy.invalidate(for: .billCalculatorItemDeleted(tenantId: tenantId, calculatorId: item.calculatorId))

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("deleteBillCalculatorItem", duration: duration)
            logger.info("Deleted bill calculator item in \(String(format: "%.2f", duration))s")
        } catch {
            logger.error("Failed to delete bill calculator item", error: error)
            throw BillCalculatorError.itemDeleteFailed(underlying: error)
        }
    }

    func createItems(_ items: [BillCalculatorItem]) async throws -> [BillCalculatorItem] {
        guard !items.isEmpty else { return [] }

        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let insertData = items.map { BillCalculatorItemInsertData(from: $0) }
            let created: [BillCalculatorItem] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("bill_calculator_items")
                    .insert(insertData)
                    .select()
                    .execute()
                    .value
            }

            // Invalidate caches for all affected calculators
            let calculatorIds = Set(items.map { $0.calculatorId })
            for calculatorId in calculatorIds {
                await cacheStrategy.invalidate(for: .billCalculatorItemCreated(tenantId: tenantId, calculatorId: calculatorId))
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("createBillCalculatorItems", duration: duration)
            logger.info("Created \(created.count) bill calculator items in \(String(format: "%.2f", duration))s")

            return created
        } catch {
            logger.error("Failed to create bill calculator items", error: error)
            throw BillCalculatorError.itemCreateFailed(underlying: error)
        }
    }

    // MARK: - Reference Data

    func fetchTaxInfoOptions() async throws -> [TaxInfo] {
        // Cache key version suffix forces refresh when data format changes
        // v2: taxRate stored as decimal (0.085), not percentage (8.5)
        let cacheKey = "tax_info_global_v2"

        // Check cache first (long TTL for reference data)
        if let cached: [TaxInfo] = await RepositoryCache.shared.get(cacheKey, maxAge: 3600) {
            logger.info("Cache hit: tax info (\(cached.count) items)")
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        logger.info("Fetching tax info options from database...")

        do {
            let taxInfos: [TaxInfo] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("tax_info")
                    .select()
                    .order("region", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await RepositoryCache.shared.set(cacheKey, value: taxInfos, ttl: 3600)
            await PerformanceMonitor.shared.recordOperation("fetchTaxInfoOptions", duration: duration)
            logger.info("Fetched \(taxInfos.count) tax info options in \(String(format: "%.2f", duration))s")

            return taxInfos
        } catch {
            logger.error("Failed to decode tax info options", error: error)
            throw error
        }
    }
}

// MARK: - Bill Calculator Row (for JOIN parsing)

/// Internal struct for parsing joined query results
private struct BillCalculatorRow: Decodable {
    let id: UUID
    let coupleId: UUID
    let name: String
    let vendorId: Int64?
    let eventId: UUID?
    let taxInfoId: Int64?
    let guestCount: Int
    let useManualGuestCount: Bool?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    // Joined relations
    let vendorInformation: VendorNameJoin?
    let weddingEvents: EventNameJoin?
    let taxInfo: TaxInfoJoin?

    private enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case name
        case vendorId = "vendor_id"
        case eventId = "event_id"
        case taxInfoId = "tax_info_id"
        case guestCount = "guest_count"
        case useManualGuestCount = "use_manual_guest_count"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case vendorInformation = "vendor_information"
        case weddingEvents = "wedding_events"
        case taxInfo = "tax_info"
    }

    struct VendorNameJoin: Decodable {
        let vendorName: String?
        private enum CodingKeys: String, CodingKey {
            case vendorName = "vendor_name"
        }
    }

    struct EventNameJoin: Decodable {
        let eventName: String?
        private enum CodingKeys: String, CodingKey {
            case eventName = "event_name"
        }
    }

    struct TaxInfoJoin: Decodable {
        /// Tax rate as percentage (e.g., 8.5 for 8.5%)
        /// Converted from decimal format in database (0.085) to percentage for UI
        let taxRate: Double?
        let region: String?

        private enum CodingKeys: String, CodingKey {
            case taxRate = "tax_rate"
            case region
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            region = try container.decodeIfPresent(String.self, forKey: .region)

            // Database returns numeric as string, handle both string and double formats
            // Convert from decimal (0.085) to percentage (8.5) for BillCalculator
            let rawRate: Double?
            if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .taxRate) {
                rawRate = doubleValue
            } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .taxRate),
                      let parsedDouble = Double(stringValue) {
                rawRate = parsedDouble
            } else {
                rawRate = nil
            }
            // Convert to percentage for BillCalculator which expects percentage format
            taxRate = rawRate.map { $0 * 100.0 }
        }
    }

    func toBillCalculator(items: [BillCalculatorItem]) -> BillCalculator {
        BillCalculator(
            id: id,
            coupleId: coupleId,
            name: name,
            vendorId: vendorId,
            eventId: eventId,
            taxInfoId: taxInfoId,
            guestCount: guestCount,
            useManualGuestCount: useManualGuestCount ?? false,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            vendorName: vendorInformation?.vendorName,
            eventName: weddingEvents?.eventName,
            taxRate: taxInfo?.taxRate,
            taxRegion: taxInfo?.region,
            items: items
        )
    }
}
