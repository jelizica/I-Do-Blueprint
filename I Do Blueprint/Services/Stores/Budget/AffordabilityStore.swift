//
//  AffordabilityStore.swift
//  I Do Blueprint
//
//  Extracted from BudgetStoreV2 as part of JES-42
//  Manages affordability calculator scenarios and contributions
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Store for managing affordability calculator functionality
/// Handles scenarios, contributions, gift linking, and budget calculations
@MainActor
class AffordabilityStore: ObservableObject {

    // MARK: - Published State

    @Published var scenarios: [AffordabilityScenario] = []
    @Published var contributions: [ContributionItem] = []
    @Published var selectedScenarioId: UUID?
    @Published var availableGifts: [GiftOrOwed] = []
    @Published var editingGift: GiftOrOwed?

    // Sandbox editing state (unsaved changes)
    @Published var editedWeddingDate: Date?
    @Published var editedCalculationStartDate: Date?
    @Published var editedPartner1Monthly: Double = 0
    @Published var editedPartner2Monthly: Double = 0

    // UI sheet presentation state
    @Published var showAddScenarioSheet = false
    @Published var showAddContributionSheet = false
    @Published var showLinkGiftsSheet = false
    @Published var showEditGiftSheet = false

    @Published var isLoading = false
    @Published var error: BudgetError?

    // MARK: - Dependencies

    @Dependency(\.budgetRepository) var repository
    private let logger = AppLogger.database

    // Reference to payment schedules (needed for alreadyPaid calculation)
    private var paymentSchedulesProvider: () -> [PaymentSchedule]

    // MARK: - Initialization

    init(paymentSchedulesProvider: @escaping () -> [PaymentSchedule] = { [] }) {
        self.paymentSchedulesProvider = paymentSchedulesProvider
    }

    // MARK: - Computed Properties

    var selectedScenario: AffordabilityScenario? {
        guard let id = selectedScenarioId else { return nil }
        return scenarios.first { $0.id == id }
    }

    var hasUnsavedChanges: Bool {
        guard let scenario = selectedScenario else { return false }

        // Check if any values have changed from the selected scenario
        let startDateChanged = editedCalculationStartDate != scenario.calculationStartDate
        let partner1Changed = editedPartner1Monthly != scenario.partner1Monthly
        let partner2Changed = editedPartner2Monthly != scenario.partner2Monthly

        return startDateChanged || partner1Changed || partner2Changed
    }

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
        paymentSchedulesProvider()
            .filter { $0.paid }
            .reduce(0) { $0 + $1.paymentAmount }
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

    // MARK: - Public Methods

    /// Load all affordability scenarios
    func loadScenarios() async {
        do {
            logger.debug("Loading affordability scenarios...")
            scenarios = try await repository.fetchAffordabilityScenarios()
            logger.info("Loaded \(scenarios.count) scenarios")

            // Auto-select primary or first scenario
            if selectedScenarioId == nil {
                selectedScenarioId = scenarios.first(where: { $0.isPrimary })?.id ?? scenarios.first?.id
                logger.debug("Auto-selected scenario: \(selectedScenarioId?.uuidString ?? "none")")
            }

            // Load contributions for selected scenario
            if let scenarioId = selectedScenarioId {
                await loadContributions(scenarioId: scenarioId)
            }
        } catch {
            await handleError(error, operation: "loadScenarios", context: [
                "scenarioCount": scenarios.count
            ])
            self.error = .fetchFailed(underlying: error)
        }
    }

    /// Load contributions for a specific scenario
    func loadContributions(scenarioId: UUID) async {
        do {
            contributions = try await repository.fetchAffordabilityContributions(scenarioId: scenarioId)
        } catch {
            await handleError(error, operation: "loadContributions", context: [
                "scenarioId": scenarioId.uuidString
            ])
            self.error = .fetchFailed(underlying: error)
        }
    }

    /// Load contributions for the currently selected scenario
    func loadContributions() async {
        guard let scenarioId = selectedScenarioId else { return }
        await loadContributions(scenarioId: scenarioId)
    }

    /// Save or update an affordability scenario
    func saveScenario(_ scenario: AffordabilityScenario) async {
        do {
            let saved = try await repository.saveAffordabilityScenario(scenario)
            if let index = scenarios.firstIndex(where: { $0.id == saved.id }) {
                scenarios[index] = saved
            } else {
                scenarios.append(saved)
            }
        } catch {
            await handleError(error, operation: "saveScenario", context: [
                "scenarioId": scenario.id.uuidString,
                "scenarioName": scenario.scenarioName
            ]) { [weak self] in
                await self?.saveScenario(scenario)
            }
            self.error = .createFailed(underlying: error)
        }
    }

    /// Delete an affordability scenario
    func deleteScenario(id: UUID) async {
        do {
            try await repository.deleteAffordabilityScenario(id: id)
            scenarios.removeAll { $0.id == id }
            if selectedScenarioId == id {
                selectedScenarioId = scenarios.first?.id
                if let scenarioId = selectedScenarioId {
                    await loadContributions(scenarioId: scenarioId)
                }
            }
        } catch {
            await handleError(error, operation: "deleteScenario", context: [
                "scenarioId": id.uuidString
            ]) { [weak self] in
                await self?.deleteScenario(id: id)
            }
            self.error = .deleteFailed(underlying: error)
        }
    }

    /// Save or update a contribution
    func saveContribution(_ contribution: ContributionItem) async {
        do {
            let saved = try await repository.saveAffordabilityContribution(contribution)
            if let index = contributions.firstIndex(where: { $0.id == saved.id }) {
                contributions[index] = saved
            } else {
                contributions.append(saved)
            }
        } catch {
            await handleError(error, operation: "saveContribution", context: [
                "contributionId": contribution.id.uuidString
            ]) { [weak self] in
                await self?.saveContribution(contribution)
            }
            self.error = .createFailed(underlying: error)
        }
    }

    /// Delete a contribution
    func deleteContribution(id: UUID, scenarioId: UUID) async {
        do {
            try await repository.deleteAffordabilityContribution(id: id, scenarioId: scenarioId)
            contributions.removeAll { $0.id == id }
        } catch {
            await handleError(error, operation: "deleteContribution", context: [
                "contributionId": id.uuidString,
                "scenarioId": scenarioId.uuidString
            ]) { [weak self] in
                await self?.deleteContribution(id: id, scenarioId: scenarioId)
            }
            self.error = .deleteFailed(underlying: error)
        }
    }

    /// Link gifts to the current scenario
    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async {
        do {
            try await repository.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)
            logger.info("Linked \(giftIds.count) gifts to scenario")
        } catch {
            await handleError(error, operation: "linkGiftsToScenario", context: [
                "giftCount": giftIds.count,
                "scenarioId": scenarioId.uuidString
            ]) { [weak self] in
                await self?.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)
            }
            self.error = .updateFailed(underlying: error)
        }
    }

    /// Unlink a gift from the current scenario
    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async {
        do {
            try await repository.unlinkGiftFromScenario(giftId: giftId, scenarioId: scenarioId)
            logger.info("Unlinked gift from scenario")
        } catch {
            await handleError(error, operation: "unlinkGiftFromScenario", context: [
                "giftId": giftId.uuidString,
                "scenarioId": scenarioId.uuidString
            ]) { [weak self] in
                await self?.unlinkGiftFromScenario(giftId: giftId, scenarioId: scenarioId)
            }
            self.error = .updateFailed(underlying: error)
        }
    }

    // MARK: - Calculator-Specific Methods

    /// Set the wedding date for calculations
    func setWeddingDate(_ dateString: String) {
        AppLogger.ui.info("AffordabilityStore.setWeddingDate called with: '\(dateString)'")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        if let date = dateFormatter.date(from: dateString) {
            editedWeddingDate = date
            AppLogger.ui.info("AffordabilityStore: Successfully parsed date: \(date)")
        } else {
            AppLogger.ui.error("AffordabilityStore: Failed to parse date string: '\(dateString)'")
            editedWeddingDate = nil
        }
    }

    /// Select a scenario and reset editing state
    func selectScenario(_ scenario: AffordabilityScenario) {
        selectedScenarioId = scenario.id
        resetEditingState()
    }

    /// Reset editing state to match selected scenario
    func resetEditingState() {
        guard let scenario = selectedScenario else { return }

        AppLogger.ui.info("AffordabilityStore.resetEditingState called")
        AppLogger.ui.info("AffordabilityStore: editedWeddingDate BEFORE reset: \(String(describing: editedWeddingDate))")

        editedCalculationStartDate = scenario.calculationStartDate
        editedPartner1Monthly = scenario.partner1Monthly
        editedPartner2Monthly = scenario.partner2Monthly

        // NOTE: editedWeddingDate is NOT reset here - it should persist from settings
        AppLogger.ui.info("AffordabilityStore: editedWeddingDate AFTER reset: \(String(describing: editedWeddingDate))")
    }

    /// Save changes to the selected scenario
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
            selectedScenarioId = updated.id
            resetEditingState()

        } catch {
            await handleError(error, operation: "saveChanges", context: [
                "scenarioId": scenario.id.uuidString
            ]) { [weak self] in
                await self?.saveChanges()
            }
            self.error = .updateFailed(underlying: error)
        }
    }

    /// Create a new scenario
    func createScenario(name: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let coupleId = selectedScenario?.coupleId else {
                error = .validationFailed(reason: "No couple ID available")
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
            selectedScenarioId = created.id
            resetEditingState()

        } catch {
            await handleError(error, operation: "createScenario", context: [
                "scenarioName": name
            ]) { [weak self] in
                await self?.createScenario(name: name)
            }
            self.error = .createFailed(underlying: error)
        }
    }

    /// Delete a scenario (cannot delete primary)
    func deleteScenario(_ scenario: AffordabilityScenario) async {
        guard !scenario.isPrimary else {
            error = .validationFailed(reason: "Cannot delete primary scenario")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.deleteAffordabilityScenario(id: scenario.id)
            await loadScenarios()
        } catch {
            await handleError(error, operation: "deleteScenario", context: [
                "scenarioId": scenario.id.uuidString,
                "scenarioName": scenario.scenarioName
            ]) { [weak self] in
                await self?.deleteScenario(scenario)
            }
            self.error = .deleteFailed(underlying: error)
        }
    }

    /// Add a new contribution
    func addContribution(name: String, amount: Double, type: ContributionType, date: Date?) async {
        guard let scenarioId = selectedScenarioId,
              let coupleId = selectedScenario?.coupleId else {
            error = .validationFailed(reason: "No scenario selected")
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
            await handleError(error, operation: "addContribution", context: [
                "contributorName": name,
                "amount": amount,
                "type": type.rawValue
            ]) { [weak self] in
                await self?.addContribution(name: name, amount: amount, type: type, date: date)
            }
            self.error = .createFailed(underlying: error)
        }
    }

    /// Delete a contribution (handles both direct contributions and linked gifts)
    func deleteContribution(_ contribution: ContributionItem) async {
        guard let scenarioId = selectedScenarioId else { return }

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
            await handleError(error, operation: "deleteContribution", context: [
                "contributionId": contribution.id.uuidString
            ]) { [weak self] in
                await self?.deleteContribution(contribution)
            }
            self.error = .deleteFailed(underlying: error)
        }
    }

    /// Load available gifts that can be linked to scenarios
    func loadAvailableGifts() async {
        do {
            let allGifts = try await repository.fetchGiftsAndOwed()
            // Filter out gifts already linked to this scenario
            if let scenarioId = selectedScenarioId {
                availableGifts = allGifts.filter { $0.scenarioId != scenarioId }
            } else {
                availableGifts = allGifts
            }
        } catch {
            await handleError(error, operation: "loadAvailableGifts")
            self.error = .fetchFailed(underlying: error)
        }
    }

    /// Link multiple gifts to the current scenario
    func linkGifts(giftIds: [UUID]) async {
        guard let scenarioId = selectedScenarioId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)
            // Reload contributions to show the newly linked gifts
            await loadContributions(scenarioId: scenarioId)
            // Reload available gifts to remove the linked ones
            await loadAvailableGifts()
        } catch {
            await handleError(error, operation: "linkGifts", context: [
                "giftCount": giftIds.count,
                "scenarioId": scenarioId.uuidString
            ]) { [weak self] in
                await self?.linkGifts(giftIds: giftIds)
            }
            self.error = .updateFailed(underlying: error)
        }
    }

    /// Update a gift
    func updateGift(_ gift: GiftOrOwed) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await repository.updateGiftOrOwed(gift)
            if let scenarioId = selectedScenarioId {
                await loadContributions(scenarioId: scenarioId)
            }
            editingGift = nil
        } catch {
            await handleError(error, operation: "updateGift", context: [
                "giftId": gift.id.uuidString
            ]) { [weak self] in
                await self?.updateGift(gift)
            }
            self.error = .updateFailed(underlying: error)
        }
    }

    /// Start editing a gift
    func startEditingGift(contributionId: UUID) async {
        // Find the gift in gifts_and_owed table
        do {
            let allGifts = try await repository.fetchGiftsAndOwed()
            if let gift = allGifts.first(where: { $0.id == contributionId }) {
                editingGift = gift
            }
        } catch {
            await handleError(error, operation: "startEditingGift", context: [
                "contributionId": contributionId.uuidString
            ])
            self.error = .fetchFailed(underlying: error)
        }
    }

    /// Mark that a field has changed (for tracking unsaved changes)
    func markFieldChanged() {
        // Changes are tracked automatically via hasUnsavedChanges computed property
    }

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        scenarios = []
        contributions = []
        selectedScenarioId = nil
        availableGifts = []
        editingGift = nil
        editedWeddingDate = nil
        editedCalculationStartDate = nil
        editedPartner1Monthly = 0
        editedPartner2Monthly = 0
        paymentSchedulesProvider = { [] }
    }
}
