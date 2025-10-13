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
    private let supabase: SupabaseClient
    private let cache: RepositoryCache
    private let logger = AppLogger.repository

    // SessionManager for tenant scoping
    private let sessionManager: SessionManager

    init(supabase: SupabaseClient, sessionManager: SessionManager = .shared) {
        self.supabase = supabase
        self.sessionManager = sessionManager
        cache = RepositoryCache()
    }

    // Convenience initializer using SupabaseManager
    init() {
        supabase = SupabaseManager.shared.client
        sessionManager = .shared
        cache = RepositoryCache()
    }

    // Helper to get tenant ID, throws if not set
    private func getTenantId() async throws -> UUID {
        try await MainActor.run {
            try sessionManager.requireTenantId()
        }
    }

    // Helper to invalidate all vendor-related caches for a specific vendor
    private func invalidateVendorSpecificCaches(vendorId: Int64, tenantId: UUID) async {
        await cache.remove("vendor_reviews_\(vendorId)_\(tenantId.uuidString)")
        await cache.remove("vendor_review_stats_\(vendorId)_\(tenantId.uuidString)")
        await cache.remove("vendor_payment_summary_\(vendorId)_\(tenantId.uuidString)")
        await cache.remove("vendor_contract_summary_\(vendorId)_\(tenantId.uuidString)")
    }

    func fetchVendors() async throws -> [Vendor] {
        let tenantId = try await getTenantId()
        let cacheKey = "vendors_\(tenantId.uuidString)"
        let startTime = Date()

        // Check cache first
        if let cached: [Vendor] = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit for vendors")
            return cached
        }

        // Fetch from Supabase with retry and timeout - scoped by tenant
        do {
            let vendors: [Vendor] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("vendorInformation")
                    .select()
                    .eq("couple_id", value: tenantId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            // Cache the result
            await cache.set(cacheKey, value: vendors)

            // Emit metrics
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(vendors.count) vendors in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchVendors", outcome: .success, duration: duration)

            return vendors
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch vendors after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendors", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchVendorStats() async throws -> VendorStats {
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_stats_\(tenantId.uuidString)"

        // Check cache first
        if let cached: VendorStats = await cache.get(cacheKey, maxAge: 60) {
            return cached
        }

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

        // Cache the result
        await cache.set(cacheKey, value: stats)

        return stats
    }

    func createVendor(_ vendor: Vendor) async throws -> Vendor {
        let tenantId = try await getTenantId()
        let startTime = Date()

        do {
            let created: Vendor = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("vendorInformation")
                    .insert(vendor)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate tenant-scoped cache and vendor-specific caches
            await cache.remove("vendors_\(tenantId.uuidString)")
            await cache.remove("vendor_stats_\(tenantId.uuidString)")
            await invalidateVendorSpecificCaches(vendorId: created.id, tenantId: tenantId)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created vendor in \(duration)s")
            AnalyticsService.trackNetwork(operation: "createVendor", outcome: .success, duration: duration)

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to create vendor after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "createVendor", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        let tenantId = try await getTenantId()
        var updated = vendor
        updated.updatedAt = Date()
        let startTime = Date()

        do {
            let result: Vendor = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("vendorInformation")
                    .update(updated)
                    .eq("id", value: String(vendor.id))
                    .eq("couple_id", value: tenantId.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate tenant-scoped cache and vendor-specific caches
            await cache.remove("vendors_\(tenantId.uuidString)")
            await cache.remove("vendor_stats_\(tenantId.uuidString)")
            await invalidateVendorSpecificCaches(vendorId: vendor.id, tenantId: tenantId)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated vendor in \(duration)s")
            AnalyticsService.trackNetwork(operation: "updateVendor", outcome: .success, duration: duration)

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update vendor after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "updateVendor", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func deleteVendor(id: Int64) async throws {
        let tenantId = try await getTenantId()
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("vendorInformation")
                    .delete()
                    .eq("id", value: String(id))
                    .eq("couple_id", value: tenantId.uuidString)
                    .execute()
            }

            // Invalidate tenant-scoped cache and vendor-specific caches
            await cache.remove("vendors_\(tenantId.uuidString)")
            await cache.remove("vendor_stats_\(tenantId.uuidString)")
            await invalidateVendorSpecificCaches(vendorId: id, tenantId: tenantId)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted vendor in \(duration)s")
            AnalyticsService.trackNetwork(operation: "deleteVendor", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete vendor after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteVendor", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Extended Vendor Data

    func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview] {
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_reviews_\(vendorId)_\(tenantId.uuidString)"
        let startTime = Date()

        if let cached: [VendorReview] = await cache.get(cacheKey, maxAge: 300) {
            logger.debug("Cache hit for vendor reviews")
            return cached
        }

        do {
            let reviews: [VendorReview] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("vendor_reviews")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .eq("couple_id", value: tenantId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            await cache.set(cacheKey, value: reviews)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(reviews.count) vendor reviews in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchVendorReviews", outcome: .success, duration: duration)

            return reviews
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch vendor reviews after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendorReviews", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats? {
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_review_stats_\(vendorId)_\(tenantId.uuidString)"

        if let cached: VendorReviewStats = await cache.get(cacheKey, maxAge: 300) {
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

        await cache.set(cacheKey, value: stats)
        return stats
    }

    func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary? {
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_payment_summary_\(vendorId)_\(tenantId.uuidString)"
        let startTime = Date()

        if let cached: VendorPaymentSummary = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit for vendor payment summary")
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
                try await self.supabase
                    .from("vendor_payment_summary")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .eq("couple_id", value: tenantId.uuidString)
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

            await cache.set(cacheKey, value: summary)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched vendor payment summary in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchVendorPaymentSummary", outcome: .success, duration: duration)

            return summary
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch vendor payment summary after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendorPaymentSummary", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract? {
        let tenantId = try await getTenantId()
        let cacheKey = "vendor_contract_summary_\(vendorId)_\(tenantId.uuidString)"
        let startTime = Date()

        if let cached: VendorContract = await cache.get(cacheKey, maxAge: 300) {
            logger.debug("Cache hit for vendor contract summary")
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
                try await self.supabase
                    .from("vendor_contract_summary")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .eq("couple_id", value: tenantId.uuidString)
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

            await cache.set(cacheKey, value: contract)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched vendor contract summary in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchVendorContractSummary", outcome: .success, duration: duration)

            return contract
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch vendor contract summary after \(duration)s", error: error)
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
}
