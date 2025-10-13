import Foundation
import SwiftUI
import Combine
import Dependencies

@MainActor
class BudgetCalculatorViewModel: ObservableObject {
    @Dependency(\.budgetRepository) var repository

    // Data from repository
    @Published var scenarios: [AffordabilityScenario] = []
    @Published var contributions: [ContributionItem] = []
    @Published var paymentSchedules: [PaymentSchedule] = []
    @Published var budgetSummary: BudgetSummary?
    @Published var availableGifts: [GiftOrOwed] = []

    // Selected scenario
    @Published var selectedScenario: AffordabilityScenario?

    // Sandbox editing state (unsaved changes)
    @Published var editedWeddingDate: Date?
    @Published var editedCalculationStartDate: Date?
    @Published var editedPartner1Monthly: Double = 0
    @Published var editedPartner2Monthly: Double = 0

    // UI state
    @Published var isLoading = false
    @Published var errorMessage: BudgetError?
    @Published var showAddScenarioSheet = false
    @Published var showAddContributionSheet = false
    @Published var showLinkGiftsSheet = false
    @Published var showEditGiftSheet = false
    @Published var editingGift: GiftOrOwed?

    var hasUnsavedChanges: Bool {
        guard let scenario = selectedScenario else { return false }

        // Check if any values have changed from the selected scenario
        let startDateChanged = editedCalculationStartDate != scenario.calculationStartDate
        let partner1Changed = editedPartner1Monthly != scenario.partner1Monthly
        let partner2Changed = editedPartner2Monthly != scenario.partner2Monthly

        return startDateChanged || partner1Changed || partner2Changed
    }

    // MARK: - Computed Properties

    var totalContributions: Double {
        contributions.reduce(0) { $0 + $1.amount }
    }

    var totalGifts: Double {
        contributions
            .filter { $0.contributionType == .gift }
            .reduce(0) { $0 + $1.amount }
    }

    var totalExternal: Double {
        contributions
            .filter { $0.contributionType == .external }
            .reduce(0) { $0 + $1.amount }
    }

    // Money already saved from calculation start date to today
    var totalSaved: Double {
        guard let startDate = editedCalculationStartDate ?? selectedScenario?.calculationStartDate else {
            return 0
        }

        // Calculate months from start date until today
        let monthsElapsed = Calendar.current.dateComponents([.month], from: startDate, to: Date()).month ?? 0
        guard monthsElapsed > 0 else { return 0 }

        let monthlyTotal = editedPartner1Monthly + editedPartner2Monthly
        return monthlyTotal * Double(monthsElapsed)
    }

    // Money that will be saved from today until wedding date
    var projectedSavings: Double {
        guard let weddingDate = editedWeddingDate else {
            return 0
        }

        // Calculate months from today until wedding
        let monthsRemaining = Calendar.current.dateComponents([.month], from: Date(), to: weddingDate).month ?? 0
        guard monthsRemaining > 0 else { return 0 }

        let monthlyTotal = editedPartner1Monthly + editedPartner2Monthly
        return monthlyTotal * Double(monthsRemaining)
    }

    var alreadyPaid: Double {
        paymentSchedules
            .filter { $0.paid }
            .reduce(0) { $0 + $1.amount }
    }

    var totalAffordableBudget: Double {
        totalContributions + totalSaved + projectedSavings + alreadyPaid
    }

    var monthsLeft: Int {
        guard let weddingDate = editedWeddingDate else {
            return 0
        }

        // Months from today to wedding date
        return max(0, Calendar.current.dateComponents([.month], from: Date(), to: weddingDate).month ?? 0)
    }

    var progressPercentage: Double {
        guard let startDate = editedCalculationStartDate ?? selectedScenario?.calculationStartDate,
              let weddingDate = editedWeddingDate else {
            return 0
        }

        // Calculate total months from start to wedding
        let totalMonths = Calendar.current.dateComponents([.month], from: startDate, to: weddingDate).month ?? 0
        guard totalMonths > 0 else { return 0 }

        // Calculate months elapsed from start to today
        let monthsElapsed = Calendar.current.dateComponents([.month], from: startDate, to: Date()).month ?? 0

        return min(100, max(0, (Double(monthsElapsed) / Double(totalMonths)) * 100))
    }

    // MARK: - Initialization

    init() {
        Task {
            await loadData()
        }
    }

    func setWeddingDate(_ dateString: String) {
        AppLogger.ui.info("BudgetCalculatorViewModel.setWeddingDate called with: '\(dateString)'")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        if let date = dateFormatter.date(from: dateString) {
            editedWeddingDate = date
            AppLogger.ui.info("BudgetCalculatorViewModel: Successfully parsed date: \(date)")
        } else {
            AppLogger.ui.error("BudgetCalculatorViewModel: Failed to parse date string: '\(dateString)'")
            editedWeddingDate = nil
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load scenarios
            scenarios = try await repository.fetchAffordabilityScenarios()

            // Select primary scenario or first one
            if let primary = scenarios.first(where: { $0.isPrimary }) {
                selectedScenario = primary
            } else if let first = scenarios.first {
                selectedScenario = first
            }

            // Load other data
            async let contributionsLoad = loadContributions()
            async let scheduleLoad = loadPaymentSchedules()
            async let summaryLoad = loadBudgetSummary()

            _ = await (contributionsLoad, scheduleLoad, summaryLoad)

            // Initialize editing state from selected scenario
            resetEditingState()

        } catch {
            errorMessage = .fetchFailed(underlying: error)
        }
    }

    func loadContributions() async {
        guard let scenarioId = selectedScenario?.id else { return }

        do {
            contributions = try await repository.fetchAffordabilityContributions(scenarioId: scenarioId)
        } catch {
            errorMessage = .fetchFailed(underlying: error)
        }
    }

    func loadPaymentSchedules() async {
        do {
            paymentSchedules = try await repository.fetchPaymentSchedules()
        } catch {
            errorMessage = .fetchFailed(underlying: error)
        }
    }

    func loadBudgetSummary() async {
        do {
            budgetSummary = try await repository.fetchBudgetSummary()
        } catch {
            errorMessage = .fetchFailed(underlying: error)
        }
    }

    // MARK: - Scenario Management

    func selectScenario(_ scenario: AffordabilityScenario) {
        selectedScenario = scenario
        resetEditingState()
    }

    func resetEditingState() {
        guard let scenario = selectedScenario else { return }

        AppLogger.ui.info("BudgetCalculatorViewModel.resetEditingState called")
        AppLogger.ui.info("BudgetCalculatorViewModel: editedWeddingDate BEFORE reset: \(String(describing: editedWeddingDate))")

        editedCalculationStartDate = scenario.calculationStartDate
        editedPartner1Monthly = scenario.partner1Monthly
        editedPartner2Monthly = scenario.partner2Monthly

        // NOTE: editedWeddingDate is NOT reset here - it should persist from settings
        AppLogger.ui.info("BudgetCalculatorViewModel: editedWeddingDate AFTER reset: \(String(describing: editedWeddingDate))")
    }

    func saveChanges() async {
        guard var scenario = selectedScenario, hasUnsavedChanges else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Update scenario with new values
            scenario.partner1Monthly = editedPartner1Monthly
            scenario.partner2Monthly = editedPartner2Monthly
            scenario.calculationStartDate = editedCalculationStartDate
            scenario.updatedAt = Date()

            let updated = try await repository.saveAffordabilityScenario(scenario)

            // Update local state
            if let index = scenarios.firstIndex(where: { $0.id == updated.id }) {
                scenarios[index] = updated
            }
            selectedScenario = updated
            resetEditingState()

        } catch {
            errorMessage = .updateFailed(underlying: error)
        }
    }

    func createScenario(name: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let coupleId = selectedScenario?.coupleId else {
                errorMessage = .validationFailed(reason: "No couple ID available")
                return
            }

            let newScenario = AffordabilityScenario(
                scenarioName: name,
                partner1Monthly: 0,
                partner2Monthly: 0,
                calculationStartDate: Date(),
                isPrimary: false,
                coupleId: coupleId
            )

            let created = try await repository.saveAffordabilityScenario(newScenario)
            scenarios.insert(created, at: 0)
            selectedScenario = created
            resetEditingState()

        } catch {
            errorMessage = .createFailed(underlying: error)
        }
    }

    func deleteScenario(_ scenario: AffordabilityScenario) async {
        guard !scenario.isPrimary else {
            errorMessage = .validationFailed(reason: "Cannot delete primary scenario")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.deleteAffordabilityScenario(id: scenario.id)
            await loadData()
        } catch {
            errorMessage = .deleteFailed(underlying: error)
        }
    }

    // MARK: - Contribution Management

    func addContribution(name: String, amount: Double, type: ContributionType, date: Date?) async {
        guard let scenarioId = selectedScenario?.id,
              let coupleId = selectedScenario?.coupleId else {
            errorMessage = .validationFailed(reason: "No scenario selected")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let contribution = ContributionItem(
                scenarioId: scenarioId,
                contributorName: name,
                amount: amount,
                contributionDate: date ?? Date(),
                contributionType: type,
                coupleId: coupleId
            )

            let created = try await repository.saveAffordabilityContribution(contribution)
            contributions.append(created)

        } catch {
            errorMessage = .createFailed(underlying: error)
        }
    }

    func deleteContribution(_ contribution: ContributionItem) async {
        guard let scenarioId = selectedScenario?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Check if this is a linked gift from gifts_and_owed table
            let allGifts = try await repository.fetchGiftsAndOwed()
            let isLinkedGift = allGifts.contains { $0.id == contribution.id && $0.scenarioId == scenarioId }

            if isLinkedGift {
                // This is a linked gift - unlink it instead of deleting
                try await repository.unlinkGiftFromScenario(giftId: contribution.id, scenarioId: scenarioId)
            } else {
                // This is a direct contribution - delete it
                try await repository.deleteAffordabilityContribution(id: contribution.id, scenarioId: scenarioId)
            }

            // Remove from local array
            contributions.removeAll { $0.id == contribution.id }
        } catch {
            errorMessage = .deleteFailed(underlying: error)
        }
    }

    // MARK: - Gift Linking

    func loadAvailableGifts() async {
        do {
            let allGifts = try await repository.fetchGiftsAndOwed()
            // Filter out gifts already linked to this scenario
            if let scenarioId = selectedScenario?.id {
                availableGifts = allGifts.filter { $0.scenarioId != scenarioId }
            } else {
                availableGifts = allGifts
            }
        } catch {
            errorMessage = .fetchFailed(underlying: error)
        }
    }

    func linkGiftsToScenario(giftIds: [UUID]) async {
        guard let scenarioId = selectedScenario?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)
            // Reload contributions to show the newly linked gifts
            await loadContributions()
            // Reload available gifts to remove the linked ones
            await loadAvailableGifts()
        } catch {
            errorMessage = .updateFailed(underlying: error)
        }
    }

    func unlinkGiftFromScenario(giftId: UUID) async {
        guard let scenarioId = selectedScenario?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.unlinkGiftFromScenario(giftId: giftId, scenarioId: scenarioId)
            // Reload contributions to remove the unlinked gift
            await loadContributions()
            // Reload available gifts to add back the unlinked one
            await loadAvailableGifts()
        } catch {
            errorMessage = .updateFailed(underlying: error)
        }
    }

    func updateGift(_ gift: GiftOrOwed) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await repository.updateGiftOrOwed(gift)
            await loadContributions()
            showEditGiftSheet = false
            editingGift = nil
        } catch {
            errorMessage = .updateFailed(underlying: error)
        }
    }

    func startEditingGift(contributionId: UUID) async {
        // Find the gift in gifts_and_owed table
        do {
            let allGifts = try await repository.fetchGiftsAndOwed()
            if let gift = allGifts.first(where: { $0.id == contributionId }) {
                editingGift = gift
                showEditGiftSheet = true
            }
        } catch {
            errorMessage = .fetchFailed(underlying: error)
        }
    }

    func markFieldChanged() {
        // Changes are tracked automatically via hasUnsavedChanges computed property
    }

    func loadScenarios() async {
        // Alias for loadData for compatibility
        await loadData()
    }
}
