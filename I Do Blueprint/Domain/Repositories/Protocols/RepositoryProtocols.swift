import Foundation

// MARK: - Repository Protocols

// These define the contract for data operations across the app

/// Protocol for budget-related data operations
protocol BudgetRepositoryProtocol: Sendable {
    // Read operations
    func fetchBudgetSummary() async throws -> BudgetSummary?
    func fetchCategories() async throws -> [BudgetCategory]
    func fetchExpenses() async throws -> [Expense]
    func fetchPaymentSchedules() async throws -> [PaymentSchedule]
    func fetchGiftsAndOwed() async throws -> [GiftOrOwed]

    // Category operations
    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory
    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory
    func deleteCategory(id: UUID) async throws

    // Expense operations
    func createExpense(_ expense: Expense) async throws -> Expense
    func updateExpense(_ expense: Expense) async throws -> Expense
    func deleteExpense(id: UUID) async throws

    // Payment Schedule operations
    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule
    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule
    func deletePaymentSchedule(id: Int64) async throws

    // Budget Development operations
    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario]
    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem]
    func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem]
    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario
    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario
    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem
    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem
    func deleteBudgetDevelopmentItem(id: String) async throws

    // Tax Rate operations
    func fetchTaxRates() async throws -> [TaxInfo]
    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo
    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo
    func deleteTaxRate(id: Int64) async throws

    // Wedding Event operations
    func fetchWeddingEvents() async throws -> [WeddingEvent]

    // Affordability Scenarios
    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario]
    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario
    func deleteAffordabilityScenario(id: UUID) async throws

    // Affordability Contributions
    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem]
    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem
    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws
    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws
    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws

    // Gift operations
    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed
}

/// Protocol for guest-related data operations
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
    func fetchGuestStats() async throws -> GuestStats
    func createGuest(_ guest: Guest) async throws -> Guest
    func updateGuest(_ guest: Guest) async throws -> Guest
    func deleteGuest(id: UUID) async throws
    func searchGuests(query: String) async throws -> [Guest]
}

/// Protocol for vendor-related data operations
protocol VendorRepositoryProtocol: Sendable {
    func fetchVendors() async throws -> [Vendor]
    func fetchVendorStats() async throws -> VendorStats
    func createVendor(_ vendor: Vendor) async throws -> Vendor
    func updateVendor(_ vendor: Vendor) async throws -> Vendor
    func deleteVendor(id: Int64) async throws

    // Extended vendor data
    func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview]
    func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats?
    func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary?
    func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract?
    func fetchVendorDetails(id: Int64) async throws -> VendorDetails
}

/// Protocol for couple/membership-related data operations
protocol CoupleRepositoryProtocol: Sendable {
    func fetchCouplesForUser(userId: UUID) async throws -> [CoupleMembership]
}

// Note: The actual model structs (BudgetSummary, BudgetCategory, Expense, etc.)
// are still in the main app's Models/Budget.swift file.
// We'll reference them from there to avoid duplication during the transition.
// SettingsRepositoryProtocol is defined in SettingsRepositoryProtocol.swift
