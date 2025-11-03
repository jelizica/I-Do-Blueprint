//
//  LiveVendorRepository.swift
//  My Wedding Planning App
//
//  Production implementation of VendorRepositoryProtocol with caching
//

import Foundation
import Supabase

/// Production implementation of VendorRepositoryProtocol
actor LiveVendorRepository: VendorRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    private let cacheStrategy = VendorCacheStrategy()

    // SessionManager for tenant scoping
    private let sessionManager: SessionManager

    // In-flight request de-duplication
    private var inFlightVendors: [UUID: Task<[Vendor], Error>] = [:]

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

    // Helper to get tenant ID, throws if not set
    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }

    // Helper to invalidate all vendor-related caches for a specific vendor
    private func invalidateVendorSpecificCaches(vendorId: Int64, tenantId: UUID) async {
        await RepositoryCache.shared.remove("vendor_reviews_\(vendorId)_\(tenantId.uuidString)")
        await RepositoryCache.shared.remove("vendor_review_stats_\(vendorId)_\(tenantId.uuidString)")
        await RepositoryCache.shared.remove("vendor_payment_summary_\(vendorId)_\(tenantId.uuidString)")
        await RepositoryCache.shared.remove("vendor_contract_summary_\(vendorId)_\(tenantId.uuidString)")
    }

    func fetchVendors() async throws -> [Vendor] {
        let tenantId = try await getTenantId()
        let cacheKey = "vendors_\(tenantId.uuidString)"

        // ✅ Check cache first
        if let cached: [Vendor] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: vendors (\(cached.count) items)")
            return cached
        }

        // Coalesce in-flight requests per-tenant
        if let task = inFlightVendors[tenantId] {
            return try await task.value
        }

        let task = Task<[Vendor], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            let client = try await self.getClient()
            let startTime = Date()
            self.logger.info("Cache miss: fetching vendors from database")
            let vendors: [Vendor] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
            let duration = Date().timeIntervalSince(startTime)
            await RepositoryCache.shared.set(cacheKey, value: vendors, ttl: 60)
            await PerformanceMonitor.shared.recordOperation("fetchVendors", duration: duration)
            self.logger.info("Fetched \(vendors.count) vendors in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchVendors", outcome: .success, duration: duration)
            return vendors
        }

        inFlightVendors[tenantId] = task
        do {
            let result = try await task.value
            inFlightVendors[tenantId] = nil
            return result
        } catch {
            inFlightVendors[tenantId] = nil
            logger.error("Failed to fetch vendors", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchVendors",
                "repository": "LiveVendorRepository"
            ])
            throw VendorError.fetchFailed(underlying: error)
        }
    }

    func fetchVendorStats() async throws -> VendorStats {
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_stats_\(tenantId.uuidString)"
        let startTime = Date()

        // ✅ Check cache first
        if let cached: VendorStats = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: vendor stats")
            return cached
        }

        logger.info("Cache miss: calculating vendor stats")

        // Fetch vendors to calculate stats (already tenant-scoped)
        let vendors = try await fetchVendors()

        let total = vendors.count
        let booked = vendors.filter { $0.isBooked == true }.count
        let available = vendors.filter { $0.isBooked == false }.count
        let archived = vendors.filter { $0.isArchived }.count
        let totalCost = vendors.reduce(0.0) { $0 + ($1.quotedAmount ?? 0) }

        // avgRating is no longer on Vendor model - would need to fetch from review stats
        let averageRating: Double = 0

        let stats = VendorStats(
            total: total,
            booked: booked,
            available: available,
            archived: archived,
            totalCost: totalCost,
            averageRating: averageRating)

        let duration = Date().timeIntervalSince(startTime)

        // ✅ Cache the result
        await RepositoryCache.shared.set(cacheKey, value: stats, ttl: 60)

        // ✅ Record performance
        await PerformanceMonitor.shared.recordOperation("fetchVendorStats", duration: duration)

        logger.info("Calculated vendor stats in \(String(format: "%.2f", duration))s")

        return stats
    }

    func createVendor(_ vendor: Vendor) async throws -> Vendor {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let created: Vendor = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .insert(vendor)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .vendorCreated(tenantId: tenantId, vendorId: created.id))

            let duration = Date().timeIntervalSince(startTime)

            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("createVendor", duration: duration)

            logger.info("Created vendor in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "createVendor", outcome: .success, duration: duration)

            return created
        } catch {
            logger.error("Failed to create vendor", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createVendor",
                "repository": "LiveVendorRepository"
            ])
            throw VendorError.createFailed(underlying: error)
        }
    }

    func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            var updated = vendor
            updated.updatedAt = Date()
            let startTime = Date()

            let result: Vendor = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .update(updated)
                    .eq("id", value: String(vendor.id))
                    .eq("couple_id", value: tenantId)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .vendorUpdated(tenantId: tenantId, vendorId: vendor.id))

            let duration = Date().timeIntervalSince(startTime)

            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("updateVendor", duration: duration)

            logger.info("Updated vendor in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "updateVendor", outcome: .success, duration: duration)

            return result
        } catch {
            logger.error("Failed to update vendor", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateVendor",
                "repository": "LiveVendorRepository",
                "vendorId": String(vendor.id)
            ])
            throw VendorError.updateFailed(underlying: error)
        }
    }

    func deleteVendor(id: Int64) async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .delete()
                    .eq("id", value: String(id))
                    .eq("couple_id", value: tenantId)
                    .execute()
            }

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .vendorDeleted(tenantId: tenantId, vendorId: id))

            let duration = Date().timeIntervalSince(startTime)

            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("deleteVendor", duration: duration)

            logger.info("Deleted vendor in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteVendor", outcome: .success, duration: duration)
        } catch {
            logger.error("Failed to delete vendor", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteVendor",
                "repository": "LiveVendorRepository",
                "vendorId": String(id)
            ])
            throw VendorError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Extended Vendor Data

    func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_reviews_\(vendorId)_\(tenantId.uuidString)"
        let startTime = Date()

        if let cached: [VendorReview] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: vendor reviews")
            return cached
        }

        do {
            let reviews: [VendorReview] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_reviews")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            await RepositoryCache.shared.set(cacheKey, value: reviews, ttl: 300)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(reviews.count) vendor reviews in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchVendorReviews", outcome: .success, duration: duration)

            return reviews
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch vendor reviews after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendorReviews", outcome: .failure(code: nil), duration: duration)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchVendorReviews",
                "repository": "LiveVendorRepository",
                "vendorId": String(vendorId)
            ])
            throw error
        }
    }

    func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats? {
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_review_stats_\(vendorId)_\(tenantId.uuidString)"

        if let cached: VendorReviewStats = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            return cached
        }

        // fetchVendorReviews is already tenant-scoped
        let reviews = try await fetchVendorReviews(vendorId: vendorId)

        guard !reviews.isEmpty else { return nil }

        let avgRating = reviews.map { Double($0.rating) }.reduce(0, +) / Double(reviews.count)
        let reviewCount = reviews.count

        let communicationRatings = reviews.compactMap { $0.communicationRating }
        let avgCommunicationRating = communicationRatings.isEmpty ? nil :
            Double(communicationRatings.reduce(0, +)) / Double(communicationRatings.count)

        let qualityRatings = reviews.compactMap { $0.qualityRating }
        let avgQualityRating = qualityRatings.isEmpty ? nil :
            Double(qualityRatings.reduce(0, +)) / Double(qualityRatings.count)

        let valueRatings = reviews.compactMap { $0.valueRating }
        let avgValueRating = valueRatings.isEmpty ? nil :
            Double(valueRatings.reduce(0, +)) / Double(valueRatings.count)

        let recommendCount = reviews.compactMap { $0.wouldRecommend }.filter { $0 }.count
        let recommendationRate = reviews.compactMap { $0.wouldRecommend }.isEmpty ? nil :
            Double(recommendCount) / Double(reviews.compactMap { $0.wouldRecommend }.count) * 100

        let stats = VendorReviewStats(
            avgRating: avgRating,
            reviewCount: reviewCount,
            avgCommunicationRating: avgCommunicationRating,
            avgQualityRating: avgQualityRating,
            avgValueRating: avgValueRating,
            recommendationRate: recommendationRate
        )

        await RepositoryCache.shared.set(cacheKey, value: stats, ttl: 300)
        return stats
    }

    func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary? {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_payment_summary_\(vendorId)_\(tenantId.uuidString)"
        let startTime = Date()

        if let cached: VendorPaymentSummary = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: vendor payment summary")
            return cached
        }

        struct PaymentSummaryRow: Decodable {
            let vendorId: Int64
            let coupleId: UUID?
            let totalAmount: Double?
            let paidAmount: Double?
            let remainingAmount: Double?
            let nextPaymentDue: Date?
            let finalPaymentDue: Date?

            private enum CodingKeys: String, CodingKey {
                case vendorId = "vendor_id"
                case coupleId = "couple_id"
                case totalAmount = "total_amount"
                case paidAmount = "paid_amount"
                case remainingAmount = "remaining_amount"
                case nextPaymentDue = "next_payment_due"
                case finalPaymentDue = "final_payment_due"
            }
        }

        do {
            let rows: [PaymentSummaryRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_payment_summary")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            guard let row = rows.first else { return nil }

            let summary = VendorPaymentSummary(
                vendorId: row.vendorId,
                totalAmount: row.totalAmount ?? 0,
                paidAmount: row.paidAmount ?? 0,
                remainingAmount: row.remainingAmount ?? 0,
                nextPaymentDue: row.nextPaymentDue,
                finalPaymentDue: row.finalPaymentDue
            )

            await RepositoryCache.shared.set(cacheKey, value: summary, ttl: 60)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched vendor payment summary in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchVendorPaymentSummary", outcome: .success, duration: duration)

            return summary
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch vendor payment summary after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendorPaymentSummary", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract? {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_contract_summary_\(vendorId)_\(tenantId.uuidString)"
        let startTime = Date()

        if let cached: VendorContract = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: vendor contract summary")
            return cached
        }

        struct ContractSummaryRow: Decodable {
            let vendorId: Int64
            let coupleId: UUID?
            let contractSignedDate: Date?
            let contractExpiryDate: Date?
            let contractStatus: String?

            private enum CodingKeys: String, CodingKey {
                case vendorId = "vendor_id"
                case coupleId = "couple_id"
                case contractSignedDate = "contract_signed_date"
                case contractExpiryDate = "contract_expiry_date"
                case contractStatus = "contract_status"
            }
        }

        do {
            let rows: [ContractSummaryRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_contract_summary")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            guard let row = rows.first else { return nil }

            let status = ContractStatus(rawValue: row.contractStatus ?? "none") ?? .none

            let contract = VendorContract(
                vendorId: row.vendorId,
                contractSignedDate: row.contractSignedDate,
                contractExpiryDate: row.contractExpiryDate,
                contractStatus: status
            )

            await RepositoryCache.shared.set(cacheKey, value: contract, ttl: 300)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched vendor contract summary in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchVendorContractSummary", outcome: .success, duration: duration)

            return contract
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch vendor contract summary after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendorContractSummary", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchVendorDetails(id: Int64) async throws -> VendorDetails {
        // Fetch vendor and all related data in parallel
        async let vendorTask = fetchVendors()
        async let reviewStatsTask = fetchVendorReviewStats(vendorId: id)
        async let paymentSummaryTask = fetchVendorPaymentSummary(vendorId: id)
        async let contractTask = fetchVendorContractSummary(vendorId: id)

        let (vendors, reviewStats, paymentSummary, contract) = try await (
            vendorTask,
            reviewStatsTask,
            paymentSummaryTask,
            contractTask
        )

        guard let vendor = vendors.first(where: { $0.id == id }) else {
            throw NSError(
                domain: "VendorRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Vendor not found"]
            )
        }

        var details = VendorDetails(vendor: vendor)
        details.reviewStats = reviewStats
        details.paymentSummary = paymentSummary
        details.contractInfo = contract

        return details
    }

    // MARK: - Vendor Types

    func fetchVendorTypes() async throws -> [VendorType] {
        let client = try getClient()
        let cacheKey = "vendor_types_all"
        let startTime = Date()

        // ✅ Check cache first (long TTL since this is reference data)
        if let cached: [VendorType] = await RepositoryCache.shared.get(cacheKey, maxAge: 3600) {
            logger.info("Cache hit: vendor types (\(cached.count) items)")
            return cached
        }

        logger.info("Cache miss: fetching vendor types from database")

        do {
            let vendorTypes: [VendorType] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_types")
                    .select()
                    .order("vendor_type", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // ✅ Cache the result (1 hour TTL for reference data)
            await RepositoryCache.shared.set(cacheKey, value: vendorTypes, ttl: 3600)

            // ✅ Record performance metrics
            await PerformanceMonitor.shared.recordOperation("fetchVendorTypes", duration: duration)

            logger.info("Fetched \(vendorTypes.count) vendor types in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchVendorTypes", outcome: .success, duration: duration)

            return vendorTypes
        } catch {
            let duration = Date().timeIntervalSince(startTime)

            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("fetchVendorTypes", duration: duration)

            logger.error("Failed to fetch vendor types after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendorTypes", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Bulk Import Operations

    /// Imports multiple vendors from CSV data in a single batch operation
    func importVendors(_ vendors: [VendorImportData]) async throws -> [Vendor] {
        guard !vendors.isEmpty else {
            logger.info("No vendors to import")
            return []
        }

        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            logger.info("Starting import of \(vendors.count) vendors for couple: \(tenantId.uuidString)")

            // Convert VendorImportData to database-compatible format
            // Note: We need to convert to a format that Supabase can insert
            // The database will auto-generate the ID (Int64)
            struct VendorInsertData: Encodable {
                let vendorName: String
                let vendorType: String?
                let vendorCategoryId: String?
                let contactName: String?
                let phoneNumber: String?
                let email: String?
                let website: String?
                let notes: String?
                let quotedAmount: Double?
                let imageUrl: String?
                let isBooked: Bool?
                let dateBooked: Date?
                let budgetCategoryId: UUID?
                let coupleId: UUID
                let isArchived: Bool
                let includeInExport: Bool
                let streetAddress: String?
                let streetAddress2: String?
                let city: String?
                let state: String?
                let postalCode: String?
                let country: String?
                let latitude: Double?
                let longitude: Double?

                private enum CodingKeys: String, CodingKey {
                    case vendorName = "vendor_name"
                    case vendorType = "vendor_type"
                    case vendorCategoryId = "vendor_category_id"
                    case contactName = "contact_name"
                    case phoneNumber = "phone_number"
                    case email
                    case website
                    case notes
                    case quotedAmount = "quoted_amount"
                    case imageUrl = "image_url"
                    case isBooked = "is_booked"
                    case dateBooked = "date_booked"
                    case budgetCategoryId = "budget_category_id"
                    case coupleId = "couple_id"
                    case isArchived = "is_archived"
                    case includeInExport = "include_in_export"
                    case streetAddress = "street_address"
                    case streetAddress2 = "street_address_2"
                    case city
                    case state
                    case postalCode = "postal_code"
                    case country
                    case latitude
                    case longitude
                }
            }

            // Convert import data to insert format
            let insertData = vendors.map { vendor in
                VendorInsertData(
                    vendorName: vendor.vendorName,
                    vendorType: vendor.vendorType,
                    vendorCategoryId: vendor.vendorCategoryId,
                    contactName: vendor.contactName,
                    phoneNumber: vendor.phoneNumber,
                    email: vendor.email,
                    website: vendor.website,
                    notes: vendor.notes,
                    quotedAmount: vendor.quotedAmount,
                    imageUrl: vendor.imageUrl,
                    isBooked: vendor.isBooked,
                    dateBooked: vendor.dateBooked,
                    budgetCategoryId: vendor.budgetCategoryId,
                    coupleId: tenantId,
                    isArchived: vendor.isArchived,
                    includeInExport: vendor.includeInExport,
                    streetAddress: vendor.streetAddress,
                    streetAddress2: vendor.streetAddress2,
                    city: vendor.city,
                    state: vendor.state,
                    postalCode: vendor.postalCode,
                    country: vendor.country,
                    latitude: vendor.latitude,
                    longitude: vendor.longitude
                )
            }

            // Perform batch insert with retry
            let imported: [Vendor] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .upsert(insertData, onConflict: "couple_id,vendor_name_normalized")
                    .select()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Invalidate all vendor-related caches
            await RepositoryCache.shared.remove("vendors_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("vendor_stats_\(tenantId.uuidString)")

            // Record performance metrics
            await PerformanceMonitor.shared.recordOperation("importVendors", duration: duration)

            logger.info("Successfully imported \(imported.count) vendors in \(String(format: "%.2f", duration))s")

            // Track analytics
            AnalyticsService.trackNetwork(operation: "importVendors", outcome: .success, duration: duration)

            return imported
        } catch {
            logger.error("Failed to import vendors", error: error)

            // Capture error with Sentry
            await SentryService.shared.captureError(error, context: [
                "operation": "importVendors",
                "vendorCount": vendors.count
            ])

            throw VendorError.importFailed(underlying: error)
        }
    }
}
