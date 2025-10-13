//
//  DashboardViewModel.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Combine
import Foundation
import Supabase
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var isLoading = false
    @Published var error: String?
    @Published var weddingDate: Date?
    @Published var daysUntilWedding: Int = 0

    private let api: DashboardAPI
    private let logger = AppLogger.general

    init(api: DashboardAPI = DashboardAPI()) {
        self.api = api
    }

    func load() async {
        // Prevent concurrent loads
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            // Fetch all dashboard metrics in parallel
            summary = try await api.fetchDashboardSummary()
            logger.info("Dashboard loaded successfully")
            logger.debug("Summary: \(String(describing: summary))")
            // Load wedding date separately to calculate countdown
            await loadWeddingInfo()
        } catch {
            self.error = "Failed to load dashboard: \(error.localizedDescription)"
            logger.error("Dashboard load error", error: error)
        }

        isLoading = false
    }

    func refresh() async {
        await load()
    }

    var hasPriorityAlerts: Bool {
        guard let summary else { return false }
        // Check for any high-priority items requiring immediate attention
        return summary.tasks.overdue > 0 ||
            summary.tasks.urgent > 0 ||
            summary.payments.overduePayments > 0 ||
            summary.reminders.dueToday > 0 ||
            summary.timeline.overdueItems > 0
    }

    private func loadWeddingInfo() async {
        do {
            let settings = try await api.fetchWeddingSettings()
            if !settings.weddingDate.isEmpty {
                // Parse ISO 8601 date format from settings
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                weddingDate = formatter.date(from: settings.weddingDate)

                if let weddingDate {
                    // Calculate days remaining until wedding
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day], from: Date(), to: weddingDate)
                    // Ensure countdown never goes negative
                    daysUntilWedding = max(components.day ?? 0, 0)
                }
            }
        } catch {
            // Silently fail - wedding date is optional feature
        }
    }
}

// MARK: - Dashboard API

class DashboardAPI {
    private let supabase: SupabaseClient
    private let logger = AppLogger.api

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    func fetchDashboardSummary() async throws -> DashboardSummary {
        // Get authenticated user's ID from the regular client
        let session = try await SupabaseManager.shared.client.auth.session
        let coupleId = session.user.id.uuidString
        logger.debug("Fetching dashboard for couple_id: \(coupleId)")

        // Fetch all metrics in parallel for better performance
        async let guestMetrics = fetchGuestMetrics(coupleId: coupleId)
        async let vendorMetrics = fetchVendorMetrics(coupleId: coupleId)
        async let budgetMetrics = fetchBudgetMetrics(coupleId: coupleId)
        async let taskMetrics = fetchTaskMetrics(coupleId: coupleId)
        async let documentMetrics = fetchDocumentMetrics(coupleId: coupleId)
        async let timelineMetrics = fetchTimelineMetrics(coupleId: coupleId)
        async let paymentMetrics = fetchPaymentMetrics(coupleId: coupleId)

        let summary = try await DashboardSummary(
            tasks: taskMetrics,
            payments: paymentMetrics,
            reminders: ReminderMetrics(
                total: 0,
                active: 0,
                completed: 0,
                overdue: 0,
                dueToday: 0,
                dueThisWeek: 0,
                recentReminders: []),
            timeline: timelineMetrics,
            guests: guestMetrics,
            vendors: vendorMetrics,
            documents: documentMetrics,
            budget: budgetMetrics,
            gifts: GiftMetrics(
                totalGifts: 0,
                totalValue: 0,
                thankedGifts: 0,
                unthankedGifts: 0,
                recentGifts: []),
            notes: NoteMetrics(
                totalNotes: 0,
                recentNotes: 0,
                notesByType: [:],
                recentNotesList: []))

        logger.debug("Metrics - Guests: \(summary.guests.totalGuests), Tasks: \(summary.tasks.total), Vendors: \(summary.vendors.totalVendors)")
        return summary
    }

    private func fetchGuestMetrics(coupleId: String) async throws -> GuestMetrics {
        struct GuestCount: Decodable {
            let count: Int
        }

        let total: Int = try await supabase
            .from("guest_list")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .execute()
            .count ?? 0

        // Count "attending" and "confirmed" as Yes
        let rsvpAttending: Int = try await supabase
            .from("guest_list")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .eq("rsvp_status", value: "attending")
            .execute()
            .count ?? 0

        let rsvpConfirmed: Int = try await supabase
            .from("guest_list")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .eq("rsvp_status", value: "confirmed")
            .execute()
            .count ?? 0

        let rsvpYes = rsvpAttending + rsvpConfirmed

        // Count "declined" as No
        let rsvpNo: Int = try await supabase
            .from("guest_list")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .eq("rsvp_status", value: "declined")
            .execute()
            .count ?? 0

        // Count "pending" and null as Pending
        let rsvpPending: Int = try await supabase
            .from("guest_list")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .or("rsvp_status.is.null,rsvp_status.eq.pending")
            .execute()
            .count ?? 0

        logger.debug("Guest Metrics - Total: \(total), Yes: \(rsvpYes) (attending: \(rsvpAttending), confirmed: \(rsvpConfirmed)), No: \(rsvpNo), Pending: \(rsvpPending)")

        return GuestMetrics(
            totalGuests: total,
            rsvpYes: rsvpYes,
            rsvpNo: rsvpNo,
            rsvpPending: rsvpPending,
            attended: 0,
            mealSelections: [:],
            recentRsvps: [])
    }

    private func fetchVendorMetrics(coupleId: String) async throws -> VendorMetrics {
        let total: Int = try await supabase
            .from("vendorInformation")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .execute()
            .count ?? 0

        let booked: Int = try await supabase
            .from("vendorInformation")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .eq("is_booked", value: true)
            .execute()
            .count ?? 0

        logger.debug("Vendor Metrics - Total: \(total), Booked: \(booked)")

        return VendorMetrics(
            totalVendors: total,
            activeContracts: booked,
            pendingContracts: 0,
            completedServices: 0,
            totalSpent: 0,
            recentVendors: [])
    }

    private func fetchBudgetMetrics(coupleId: String) async throws -> BudgetMetrics {
        struct BudgetCategory: Decodable {
            let allocated_amount: Double?
            let spent_amount: Double?
        }

        // Get all budget categories and sum on client side
        let categories: [BudgetCategory] = try await supabase
            .from("budget_categories")
            .select("allocated_amount,spent_amount")
            .eq("couple_id", value: coupleId)
            .execute()
            .value

        let totalBudget = categories.reduce(0.0) { $0 + ($1.allocated_amount ?? 0) }
        let spent = categories.reduce(0.0) { $0 + ($1.spent_amount ?? 0) }
        let remaining = totalBudget - spent
        let percentageUsed = totalBudget > 0 ? Int((spent / totalBudget) * 100) : 0

        logger.debug("Budget Metrics - Total: \(totalBudget), Spent: \(spent), Remaining: \(remaining)")

        return BudgetMetrics(
            totalBudget: totalBudget,
            spent: spent,
            remaining: remaining,
            percentageUsed: Double(percentageUsed),
            categories: categories.count,
            overBudgetCategories: 0,
            recentExpenses: [])
    }

    private func fetchTaskMetrics(coupleId: String) async throws -> TaskMetrics {
        let total: Int = try await supabase
            .from("wedding_tasks")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .execute()
            .count ?? 0

        let completed: Int = try await supabase
            .from("wedding_tasks")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .eq("status", value: "completed")
            .execute()
            .count ?? 0

        logger.debug("Task Metrics - Total: \(total), Completed: \(completed)")

        return TaskMetrics(
            total: total,
            completed: completed,
            inProgress: 0,
            notStarted: 0,
            onHold: 0,
            cancelled: 0,
            overdue: 0,
            dueThisWeek: 0,
            highPriority: 0,
            urgent: 0,
            completionRate: total > 0 ? Double((Double(completed) / Double(total)) * 100) : 0,
            recentTasks: [])
    }

    private func fetchDocumentMetrics(coupleId: String) async throws -> DocumentMetrics {
        let total: Int = try await supabase
            .from("documents")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .execute()
            .count ?? 0

        logger.debug("Document Metrics - Total: \(total)")

        return DocumentMetrics(
            totalDocuments: total,
            invoices: 0,
            contracts: 0,
            other: 0,
            recentDocuments: [])
    }

    private func fetchTimelineMetrics(coupleId: String) async throws -> TimelineMetrics {
        let total: Int = try await supabase
            .from("wedding_timeline")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .execute()
            .count ?? 0

        let completed: Int = try await supabase
            .from("wedding_timeline")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .eq("is_completed", value: true)
            .execute()
            .count ?? 0

        logger.debug("Timeline Metrics - Total: \(total), Completed: \(completed)")

        return TimelineMetrics(
            totalItems: total,
            completedItems: completed,
            upcomingItems: 0,
            overdueItems: 0,
            milestones: 0,
            completedMilestones: 0,
            recentItems: [])
    }

    private func fetchPaymentMetrics(coupleId: String) async throws -> PaymentMetrics {
        let total: Int = try await supabase
            .from("paymentPlans")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .execute()
            .count ?? 0

        let paid: Int = try await supabase
            .from("paymentPlans")
            .select("id", head: false, count: .exact)
            .eq("couple_id", value: coupleId)
            .eq("paid", value: true)
            .execute()
            .count ?? 0

        logger.debug("Payment Metrics - Total: \(total), Paid: \(paid)")

        return PaymentMetrics(
            totalPayments: total,
            paidPayments: paid,
            unpaidPayments: total - paid,
            overduePayments: 0,
            upcomingPayments: 0,
            totalAmount: 0,
            paidAmount: 0,
            unpaidAmount: 0,
            overdueAmount: 0,
            recentPayments: [])
    }

    func fetchWeddingSettings() async throws -> GlobalSettings {
        // Nested struct to decode Supabase response structure
        struct SettingsRow: Decodable {
            let settings: CoupleSettings
        }

        // Get authenticated user's ID
        let session = try await supabase.auth.session
        let userId = session.user.id

        // Query couple_settings table for user-specific configuration
        let response: SettingsRow = try await supabase
            .from("couple_settings")
            .select("settings")
            .eq("couple_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Extract global settings from nested structure
        return response.settings.global
    }
}
