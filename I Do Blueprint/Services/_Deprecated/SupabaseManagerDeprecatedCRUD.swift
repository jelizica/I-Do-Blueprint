//
//  SupabaseManagerDeprecatedCRUD.swift
//  My Wedding Planning App
//
//  DEPRECATED: This file contains deprecated CRUD methods.
//  Use domain repositories instead (LiveGuestRepository, LiveVendorRepository, etc.)
//

#if DEBUG

import Auth
import Combine
import Foundation
import Functions
import PostgREST
import Realtime
import Supabase
import SwiftUI

// MARK: - Database Operations Extension (DEPRECATED - Use Repositories)

extension SupabaseManager {
    // MARK: - Guest Operations (DEPRECATED)

    @available(*, deprecated, message: "Use LiveGuestRepository.fetchGuests() instead")
    func fetchGuests() async throws -> [Guest] {
        let response: [Guest] = try await client
            .from("guest_list")
            .select()
            .order("first_name", ascending: true)
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveGuestRepository.fetchGuestStats() instead")
    func fetchGuestStats() async throws -> GuestStats {
        let guests = try await fetchGuests()

        let totalGuests = guests.count
        let attendingGuests = guests.filter { $0.rsvpStatus == .attending }.count
        let pendingGuests = guests.filter { $0.rsvpStatus == .pending }.count
        let declinedGuests = guests.filter { $0.rsvpStatus == .declined }.count

        let responseRate = totalGuests > 0 ? Double(attendingGuests + declinedGuests) / Double(totalGuests) * 100 : 0

        return GuestStats(
            totalGuests: totalGuests,
            attendingGuests: attendingGuests,
            pendingGuests: pendingGuests,
            declinedGuests: declinedGuests,
            responseRate: responseRate)
    }

    @available(*, deprecated, message: "Use LiveGuestRepository instead")
    func getNextInvitationNumber() async throws -> String {
        // Fetch all guests and find the highest invitation number
        let guests = try await fetchGuests()
        let maxNumber = guests
            .compactMap { guest in
                // Try to parse invitation number as Int
                if let invNum = guest.invitationNumber {
                    return Int(invNum)
                }
                return nil
            }
            .max() ?? 0

        return String(maxNumber + 1)
    }

    @available(*, deprecated, message: "Use LiveGuestRepository.createGuest() instead")
    func createGuest(_ guest: Guest) async throws -> Guest {
        var newGuest = guest

        // Automatically generate invitation number if not provided
        if newGuest.invitationNumber == nil {
            newGuest.invitationNumber = try await getNextInvitationNumber()
        }

        let response: Guest = try await client
            .from("guest_list")
            .insert(newGuest)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveGuestRepository.updateGuest() instead")
    func updateGuest(_ guest: Guest) async throws -> Guest {
        var updatedGuest = guest
        updatedGuest.updatedAt = Date()

        let response: Guest = try await client
            .from("guest_list")
            .update(updatedGuest)
            .eq("id", value: guest.id)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveGuestRepository.deleteGuest() instead")
    func deleteGuest(id: UUID) async throws {
        AppLogger.api.debug("SupabaseManager.deleteGuest called with ID: \(id)")
        try await client
            .from("guest_list")
            .delete()
            .eq("id", value: id)
            .execute()
        AppLogger.api.debug("SupabaseManager.deleteGuest completed successfully")
    }

    @available(*, deprecated, message: "Use LiveGuestRepository.searchGuests() instead")
    func searchGuests(query: String) async throws -> [Guest] {
        let response: [Guest] = try await client
            .from("guest_list")
            .select()
            .or("first_name.ilike.%\(query)%,last_name.ilike.%\(query)%,email.ilike.%\(query)%")
            .order("first_name", ascending: true)
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveGuestRepository.searchGuests() instead")
    func filterGuests(by status: RSVPStatus) async throws -> [Guest] {
        let response: [Guest] = try await client
            .from("guest_list")
            .select()
            .eq("rsvp_status", value: status.rawValue)
            .order("first_name", ascending: true)
            .execute()
            .value

        return response
    }

    // MARK: - Vendor Operations (DEPRECATED)

    @available(*, deprecated, message: "Use LiveVendorRepository.fetchVendors() instead")
    func fetchVendors() async throws -> [Vendor] {
        let response: [Vendor] = try await client
            .from("vendorInformation")
            .select()
            .order("vendor_name", ascending: true)
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveVendorRepository.fetchVendorStats() instead")
    func fetchVendorStats() async throws -> VendorStats {
        let vendors = try await fetchVendors()

        let total = vendors.count
        let booked = vendors.filter { $0.isBooked == true }.count
        let available = vendors.filter { $0.isBooked != true && !$0.isArchived }.count
        let archived = vendors.filter(\.isArchived).count
        let totalCost = vendors.compactMap(\.quotedAmount).reduce(0, +)

        // Calculate average rating (would need vendor_reviews table for real data)
        let averageRating = 0.0 // Placeholder

        return VendorStats(
            total: total,
            booked: booked,
            available: available,
            archived: archived,
            totalCost: totalCost,
            averageRating: averageRating)
    }

    @available(*, deprecated, message: "Use LiveVendorRepository.createVendor() instead")
    func createVendor(_ vendor: Vendor) async throws -> Vendor {
        let response: Vendor = try await client
            .from("vendorInformation")
            .insert(vendor)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveVendorRepository.updateVendor() instead")
    func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        var updatedVendor = vendor
        updatedVendor.updatedAt = Date()

        let response: Vendor = try await client
            .from("vendorInformation")
            .update(updatedVendor)
            .eq("id", value: String(vendor.id))
            .select()
            .single()
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveVendorRepository.deleteVendor() instead")
    func deleteVendor(id: Int64) async throws {
        AppLogger.api.debug("SupabaseManager.deleteVendor called with ID: \(id)")
        try await client
            .from("vendorInformation")
            .delete()
            .eq("id", value: String(id))
            .execute()
        AppLogger.api.debug("SupabaseManager.deleteVendor completed successfully")
    }

    @available(*, deprecated, message: "Use LiveVendorRepository instead")
    func searchVendors(query: String) async throws -> [Vendor] {
        let response: [Vendor] = try await client
            .from("vendorInformation")
            .select()
            .or("vendor_name.ilike.%\(query)%,vendor_type.ilike.%\(query)%,contact_name.ilike.%\(query)%")
            .order("vendor_name", ascending: true)
            .execute()
            .value

        return response
    }

    @available(*, deprecated, message: "Use LiveVendorRepository instead")
    func filterVendors(by status: String) async throws -> [Vendor] {
        let response: [Vendor] = try await client
            .from("vendorInformation")
            .select()
            .eq("is_booked", value: status == "booked")
            .order("vendor_name", ascending: true)
            .execute()
            .value

        return response
    }

    // MARK: - Budget Operations (DEPRECATED)

    @available(*, deprecated, message: "Use LiveBudgetRepository.fetchBudgetSummary() instead")
    func fetchBudgetSummary() async throws -> BudgetSummary? {
        do {
            let response: [BudgetSummary] = try await client
                .from("budget_settings")
                .select()
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            return response.first
        } catch {
            AppLogger.api.error("Failed to fetch budget summary", error: error)
            throw error
        }
    }

    // MARK: - Budget and Financial Operations (DEPRECATED)

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchBudgetCategories() async throws -> [BudgetCategory] {
        do {
            let response: [BudgetCategory] = try await client
                .from("budget_categories")
                .select()
                .order("priority_level", ascending: true)
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to fetch budget categories", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchExpenses() async throws -> [Expense] {
        do {
            let response: [Expense] = try await client
                .from("expenses")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to fetch expenses", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        do {
            let response: [PaymentSchedule] = try await client
                .from("paymentPlans")
                .select()
                .order("payment_date", ascending: true)
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to fetch payment schedules", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchCategoryBenchmarks() async throws -> [CategoryBenchmark] {
        do {
            let response: [CategoryBenchmark] = try await client
                .from("category_benchmarks")
                .select()
                .order("category_name", ascending: true)
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to fetch category benchmarks", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createBudgetSummary(_ summary: BudgetSummary) async throws -> BudgetSummary {
        do {
            let response: BudgetSummary = try await client
                .from("budget_settings")
                .insert(summary)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to create budget summary", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updateBudgetSummary(_ summary: BudgetSummary) async throws -> BudgetSummary {
        do {
            var updatedSummary = summary
            updatedSummary.updatedAt = Date()

            let response: BudgetSummary = try await client
                .from("budget_settings")
                .update(updatedSummary)
                .eq("id", value: summary.id)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to update budget summary", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createBudgetCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        do {
            let response: BudgetCategory = try await client
                .from("budget_categories")
                .insert(category)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to create budget category", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updateBudgetCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        do {
            var updatedCategory = category
            updatedCategory.updatedAt = Date()

            let response: BudgetCategory = try await client
                .from("budget_categories")
                .update(updatedCategory)
                .eq("id", value: category.id)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to update budget category", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func deleteBudgetCategory(id: UUID) async throws {
        do {
            AppLogger.api.debug("SupabaseManager.deleteBudgetCategory called with ID: \(id)")
            try await client
                .from("budget_categories")
                .delete()
                .eq("id", value: id)
                .execute()
            AppLogger.api.debug("SupabaseManager.deleteBudgetCategory completed successfully")
        } catch {
            AppLogger.api.error("Failed to delete budget category", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createExpense(_ expense: Expense) async throws -> Expense {
        do {
            let response: Expense = try await client
                .from("expenses")
                .insert(expense)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to create expense", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updateExpense(_ expense: Expense) async throws -> Expense {
        do {
            var updatedExpense = expense
            updatedExpense.updatedAt = Date()

            let response: Expense = try await client
                .from("expenses")
                .update(updatedExpense)
                .eq("id", value: expense.id)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to update expense", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func deleteExpense(id: UUID) async throws {
        do {
            AppLogger.api.debug("SupabaseManager.deleteExpense called with ID: \(id)")
            try await client
                .from("expenses")
                .delete()
                .eq("id", value: id)
                .execute()
            AppLogger.api.debug("SupabaseManager.deleteExpense completed successfully")
        } catch {
            AppLogger.api.error("Failed to delete expense", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation] {
        let allocations: [ExpenseAllocation] = try await client
            .from("expense_budget_allocations")
            .select()
            .eq("scenario_id", value: scenarioId)
            .eq("budget_item_id", value: budgetItemId)
            .execute()
            .value

        return allocations
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws {
        _ = try await client
            .from("expense_budget_allocations")
            .insert(allocation)
            .execute()
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        do {
            let response: PaymentSchedule = try await client
                .from("paymentPlans")
                .insert(schedule)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to create payment schedule", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        do {
            var updatedSchedule = schedule
            updatedSchedule.updatedAt = Date()

            let response: PaymentSchedule = try await client
                .from("paymentPlans")
                .update(updatedSchedule)
                .eq("id", value: String(schedule.id))
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to update payment schedule", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func deletePaymentSchedule(_ id: Int64) async throws {
        do {
            _ = try await client
                .from("paymentPlans")
                .delete()
                .eq("id", value: String(id))
                .execute()
        } catch {
            AppLogger.api.error("Failed to delete payment schedule", error: error)
            throw error
        }
    }

    // MARK: - Gifts and Owed Items Operations (DEPRECATED)

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        do {
            let response: [GiftOrOwed] = try await client
                .from("gifts_and_owed")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            AppLogger.api.info("Successfully fetched \(response.count) gifts and owed items")
            return response
        } catch {
            AppLogger.api.error("Failed to fetch gifts and owed items", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createGiftOrOwed(_ giftOrOwed: GiftOrOwed) async throws -> GiftOrOwed {
        do {
            var newItem = giftOrOwed
            newItem.createdAt = Date()
            newItem.updatedAt = Date()

            var insertData: [String: AnyEncodable] = [
                "couple_id": AnyEncodable(newItem.coupleId.uuidString),
                "title": AnyEncodable(newItem.title),
                "amount": AnyEncodable(newItem.amount),
                "type": AnyEncodable(newItem.type.rawValue),
                "status": AnyEncodable(newItem.status.rawValue),
                "created_at": AnyEncodable(newItem.createdAt.toISOString())
            ]

            if let description = newItem.description {
                insertData["description"] = AnyEncodable(description)
            }
            if let fromPerson = newItem.fromPerson {
                insertData["from_person"] = AnyEncodable(fromPerson)
            }
            if let expectedDate = newItem.expectedDate {
                insertData["expected_date"] = AnyEncodable(expectedDate.toISOString())
            }
            if let receivedDate = newItem.receivedDate {
                insertData["received_date"] = AnyEncodable(receivedDate.toISOString())
            }
            if let updatedAt = newItem.updatedAt {
                insertData["updated_at"] = AnyEncodable(updatedAt.toISOString())
            }

            let response: [GiftOrOwed] = try await client
                .from("gifts_and_owed")
                .insert(insertData)
                .select()
                .execute()
                .value

            guard let createdItem = response.first else {
                throw NSError(
                    domain: "SupabaseClient",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "No gift/owed item returned after creation"])
            }

            AppLogger.api.info("Successfully created gift/owed item with ID: \(createdItem.id)")
            return createdItem
        } catch {
            AppLogger.api.error("Failed to create gift/owed item", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updateGiftOrOwed(_ giftOrOwed: GiftOrOwed) async throws -> GiftOrOwed {
        do {
            var updatedItem = giftOrOwed
            updatedItem.updatedAt = Date()

            var updateData: [String: AnyEncodable] = [
                "title": AnyEncodable(updatedItem.title),
                "amount": AnyEncodable(updatedItem.amount),
                "type": AnyEncodable(updatedItem.type.rawValue),
                "status": AnyEncodable(updatedItem.status.rawValue)
            ]

            if let description = updatedItem.description {
                updateData["description"] = AnyEncodable(description)
            }
            if let fromPerson = updatedItem.fromPerson {
                updateData["from_person"] = AnyEncodable(fromPerson)
            }
            if let expectedDate = updatedItem.expectedDate {
                updateData["expected_date"] = AnyEncodable(expectedDate.toISOString())
            }
            if let receivedDate = updatedItem.receivedDate {
                updateData["received_date"] = AnyEncodable(receivedDate.toISOString())
            }
            if let updatedAt = updatedItem.updatedAt {
                updateData["updated_at"] = AnyEncodable(updatedAt.toISOString())
            }

            let response: [GiftOrOwed] = try await client
                .from("gifts_and_owed")
                .update(updateData)
                .eq("id", value: updatedItem.id.uuidString)
                .select()
                .execute()
                .value

            guard let updated = response.first else {
                throw NSError(
                    domain: "SupabaseClient",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "No gift/owed item returned after update"])
            }

            AppLogger.api.info("Successfully updated gift/owed item with ID: \(updated.id)")
            return updated
        } catch {
            AppLogger.api.error("Failed to update gift/owed item", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func deleteGiftOrOwed(_ id: UUID) async throws {
        do {
            _ = try await client
                .from("gifts_and_owed")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            AppLogger.api.info("Successfully deleted gift/owed item with ID: \(id)")
        } catch {
            AppLogger.api.error("Failed to delete gift/owed item", error: error)
            throw error
        }
    }

    // MARK: - Budget Development Operations (DEPRECATED)

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario] {
        do {
            let response: [SavedScenario] = try await client
                .from("budget_development_scenarios")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to fetch budget development scenarios", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchBudgetDevelopmentItems(scenarioId: String? = nil) async throws -> [BudgetItem] {
        do {
            let response: [BudgetItem] = if let scenarioId, !scenarioId.isEmpty {
                try await client
                    .from("budget_development_items")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            } else {
                try await client
                    .from("budget_development_items")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            let convertedResponse = response.map { item in
                var convertedItem = item
                convertedItem
                    .taxRate = round(item.taxRate * 100 * 100) / 100
                return convertedItem
            }

            return convertedResponse
        } catch {
            AppLogger.api.error("Failed to fetch budget development items", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem] {
        do {
            guard !scenarioId.isEmpty else {
                AppLogger.api.warning("Empty scenarioId provided, returning empty array")
                return []
            }

            let budgetItems = try await fetchBudgetDevelopmentItems(scenarioId: scenarioId)

            struct AllocationData: Codable {
                let budgetItemId: String
                let allocatedAmount: Double

                private enum CodingKeys: String, CodingKey {
                    case budgetItemId = "budget_item_id"
                    case allocatedAmount = "allocated_amount"
                }
            }

            let allocations: [AllocationData] = try await client
                .from("expense_budget_allocations")
                .select("budget_item_id, allocated_amount")
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value

            AppLogger.api.debug("Found \(allocations.count) expense allocations for scenario \(scenarioId)")

            var spentAmounts: [String: Double] = [:]
            for allocation in allocations {
                let itemId = allocation.budgetItemId
                let amount = allocation.allocatedAmount
                spentAmounts[itemId, default: 0] += amount
                AppLogger.api.debug("Item \(itemId) has allocation of $\(amount)")
            }

            AppLogger.api.debug("Total unique items with spending: \(spentAmounts.count)")

            struct ExpenseAllocationWithDetails: Codable {
                let budgetItemId: String
                let expenseId: String
                let allocatedAmount: Double
                let expenses: ExpenseDetails?

                private enum CodingKeys: String, CodingKey {
                    case budgetItemId = "budget_item_id"
                    case expenseId = "expense_id"
                    case allocatedAmount = "allocated_amount"
                    case expenses
                }

                struct ExpenseDetails: Codable {
                    let expenseName: String

                    private enum CodingKeys: String, CodingKey {
                        case expenseName = "expense_name"
                    }
                }
            }

            let expenseAllocations: [ExpenseAllocationWithDetails] = try await client
                .from("expense_budget_allocations")
                .select("budget_item_id, expense_id, allocated_amount, expenses(expense_name)")
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value

            var expensesByItem: [String: [ExpenseLink]] = [:]
            for allocation in expenseAllocations {
                let expenseLink = ExpenseLink(
                    id: allocation.expenseId,
                    title: allocation.expenses?.expenseName ?? "Unknown Expense",
                    amount: allocation.allocatedAmount)
                expensesByItem[allocation.budgetItemId, default: []].append(expenseLink)
            }

            AppLogger.api.debug("Found expenses for \(expensesByItem.count) budget items")

            struct BudgetItemWithGift: Codable {
                let id: String
                let linkedGiftOwedId: String?
                let gifts_and_owed: GiftDetails?

                private enum CodingKeys: String, CodingKey {
                    case id
                    case linkedGiftOwedId = "linked_gift_owed_id"
                    case gifts_and_owed
                }

                struct GiftDetails: Codable {
                    let id: String
                    let title: String
                    let amount: Double
                }
            }

            let budgetItemsWithGifts: [BudgetItemWithGift] = try await client
                .from("budget_development_items")
                .select("id, linked_gift_owed_id, gifts_and_owed(id, title, amount)")
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value

            var giftsByItem: [String: [GiftLink]] = [:]
            for budgetItemWithGift in budgetItemsWithGifts {
                if budgetItemWithGift.linkedGiftOwedId != nil,
                   let giftDetails = budgetItemWithGift.gifts_and_owed {
                    let giftLink = GiftLink(
                        id: giftDetails.id,
                        title: giftDetails.title,
                        amount: giftDetails.amount)
                    giftsByItem[budgetItemWithGift.id] = [giftLink]
                }
            }
            AppLogger.api.debug("Found gifts for \(giftsByItem.count) budget items")

            let budgetOverviewItems = budgetItems.map { item in
                let actualSpent = spentAmounts[item.id] ?? 0
                let linkedExpenses = expensesByItem[item.id] ?? []
                let linkedGifts = giftsByItem[item.id] ?? []
                AppLogger.api.debug(
                    "Item '\(item.itemName)' has \(linkedExpenses.count) linked expenses and \(linkedGifts.count) linked gifts")
                return BudgetOverviewItem(
                    id: item.id,
                    itemName: item.itemName,
                    category: item.category,
                    subcategory: item.subcategory ?? "",
                    budgeted: item.vendorEstimateWithTax,
                    spent: actualSpent,
                    effectiveSpent: actualSpent,
                    expenses: linkedExpenses,
                    gifts: linkedGifts)
            }

            return budgetOverviewItems
        } catch {
            AppLogger.api.error("Failed to fetch budget development items with spent amounts", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        do {
            let response: SavedScenario = try await client
                .from("budget_development_scenarios")
                .insert(scenario)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to create budget development scenario", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        do {
            let response: SavedScenario = try await client
                .from("budget_development_scenarios")
                .update(scenario)
                .eq("id", value: scenario.id)
                .select()
                .single()
                .execute()
                .value

            return response
        } catch {
            AppLogger.api.error("Failed to update budget development scenario", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        do {
            var itemForDB = item
            itemForDB.taxRate = item.taxRate / 100

            let response: BudgetItem = try await client
                .from("budget_development_items")
                .insert(itemForDB)
                .select()
                .single()
                .execute()
                .value

            var convertedResponse = response
            convertedResponse.taxRate = round(response.taxRate * 100 * 100) / 100

            return convertedResponse
        } catch {
            AppLogger.api.error("Failed to create budget development item", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        do {
            var itemForDB = item
            itemForDB.taxRate = item.taxRate / 100

            let response: BudgetItem = try await client
                .from("budget_development_items")
                .update(itemForDB)
                .eq("id", value: item.id)
                .select()
                .single()
                .execute()
                .value

            var convertedResponse = response
            convertedResponse.taxRate = round(response.taxRate * 100 * 100) / 100

            return convertedResponse
        } catch {
            AppLogger.api.error("Failed to update budget development item", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func deleteBudgetDevelopmentItem(id: String) async throws {
        do {
            AppLogger.api.debug("SupabaseManager.deleteBudgetDevelopmentItem called with ID: \(id)")
            try await client
                .from("budget_development_items")
                .delete()
                .eq("id", value: id)
                .execute()
            AppLogger.api.debug("SupabaseManager.deleteBudgetDevelopmentItem completed successfully")
        } catch {
            AppLogger.api.error("Failed to delete budget development item", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func unlinkExpenseFromBudgetItem(expenseId: String, budgetItemId: String) async throws {
        do {
            AppLogger.api.debug("Unlinking expense \(expenseId) from budget item \(budgetItemId)")

            try await client
                .from("expense_budget_allocations")
                .delete()
                .eq("expense_id", value: expenseId)
                .eq("budget_item_id", value: budgetItemId)
                .execute()

            AppLogger.api.info("Successfully unlinked expense from budget item")
        } catch {
            AppLogger.api.error("Failed to unlink expense", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func unlinkGiftFromBudgetItem(budgetItemId: String) async throws {
        do {
            AppLogger.api.debug("Unlinking gift from budget item \(budgetItemId)")

            try await client
                .from("budget_development_items")
                .update(["linked_gift_owed_id": AnyJSON.null])
                .eq("id", value: budgetItemId)
                .execute()

            AppLogger.api.info("Successfully unlinked gift from budget item")
        } catch {
            AppLogger.api.error("Failed to unlink gift", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func linkGiftToBudgetItem(giftId: String, budgetItemId: String) async throws {
        do {
            AppLogger.api.debug("Linking gift \(giftId) to budget item \(budgetItemId)")

            try await client
                .from("budget_development_items")
                .update(["linked_gift_owed_id": giftId])
                .eq("id", value: budgetItemId)
                .execute()

            AppLogger.api.info("Successfully linked gift to budget item")
        } catch {
            AppLogger.api.error("Failed to link gift", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchGifts() async throws -> [Gift] {
        do {
            AppLogger.api.debug("Fetching gifts from database")
            let gifts: [Gift] = try await client
                .from("gifts_and_owed")
                .select("*")
                .order("created_at", ascending: false)
                .execute()
                .value

            AppLogger.api.info("Successfully fetched \(gifts.count) gifts")
            return gifts
        } catch {
            AppLogger.api.error("Failed to fetch gifts", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchWeddingEvents() async throws -> [WeddingEvent] {
        do {
            AppLogger.api.debug("Fetching wedding events from database...")

            let postgrestResponse = try await client
                .from("wedding_events")
                .select()
                .order("event_date", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                if let date = timeFormatter.date(from: dateString) {
                    return date
                }

                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }

                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
            }

            let response: [WeddingEvent] = try decoder.decode([WeddingEvent].self, from: postgrestResponse.data)

            AppLogger.api.info("Successfully loaded \(response.count) wedding events from database")
            return response
        } catch {
            AppLogger.api.error("Failed to fetch wedding events", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func fetchTaxRates() async throws -> [TaxInfo] {
        do {
            AppLogger.api.debug("Fetching tax rates from database...")

            let response: [TaxInfo] = try await client
                .from("taxInfo")
                .select("id, region, tax_rate")
                .order("region", ascending: true)
                .execute()
                .value

            AppLogger.api.info("Successfully loaded \(response.count) tax rates from database")
            return response
        } catch {
            AppLogger.api.error("Failed to fetch tax rates from database", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        do {
            AppLogger.api.debug("Creating new tax rate: \(taxInfo.region) - \(taxInfo.taxRate)")

            let response: TaxInfo = try await client
                .from("taxInfo")
                .insert(taxInfo)
                .select()
                .single()
                .execute()
                .value

            AppLogger.api.info("Successfully created tax rate with ID: \(response.id)")
            return response
        } catch {
            AppLogger.api.error("Failed to create tax rate", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        do {
            AppLogger.api.debug("Updating tax rate: \(taxInfo.region) - \(taxInfo.taxRate)")

            let response: TaxInfo = try await client
                .from("taxInfo")
                .update(taxInfo)
                .eq("id", value: String(taxInfo.id))
                .select()
                .single()
                .execute()
                .value

            AppLogger.api.info("Successfully updated tax rate")
            return response
        } catch {
            AppLogger.api.error("Failed to update tax rate", error: error)
            throw error
        }
    }

    @available(*, deprecated, message: "Use corresponding Live*Repository instead")
    func deleteTaxRate(id: Int64) async throws {
        do {
            AppLogger.api.debug("Deleting tax rate with ID: \(id)")

            try await client
                .from("taxInfo")
                .delete()
                .eq("id", value: String(id))
                .execute()

            AppLogger.api.info("Successfully deleted tax rate")
        } catch {
            AppLogger.api.error("Failed to delete tax rate", error: error)
            throw error
        }
    }
}

#endif
