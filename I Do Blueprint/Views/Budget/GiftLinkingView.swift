//
//  GiftLinkingView.swift
//  I Do Blueprint
//
//  Modal for linking gifts to a budget item with proportional allocation
//  Updated to support multi-select following the expense linking pattern
//

import SwiftUI
import Supabase
import Dependencies

struct GiftLinkingView: View {
    @Binding var isPresented: Bool
    let budgetItem: BudgetOverviewItem
    let activeScenario: SavedScenario?
    let onSuccess: () -> Void

    @EnvironmentObject var budgetStore: BudgetStoreV2
    @Dependency(\.budgetRepository) var budgetRepository
    @Dependency(\.giftAllocationService) var giftAllocationService

    // State for gifts
    @State private var gifts: [GiftOrOwed] = []
    @State private var filteredGifts: [GiftOrOwed] = []
    @State private var selectedGiftIds: Set<UUID> = []
    @State private var linkedGiftIds: Set<UUID> = []
    @State private var existingAllocations: [GiftAllocation] = []

    // Search and filter state
    @State private var searchText = ""
    @State private var typeFilter = "all"
    @State private var statusFilter = "all"
    @State private var hideLinkedGifts = false

    // Loading and error state
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var linkingProgress: (current: Int, total: Int)?

    private var availableGifts: [GiftOrOwed] {
        let filtered = filteredGifts.filter { gift in
            // If hideLinkedGifts is on, filter out already linked gifts
            !hideLinkedGifts || !linkedGiftIds.contains(gift.id)
        }
        return filtered
    }

    private var selectedGifts: [GiftOrOwed] {
        gifts.filter { selectedGiftIds.contains($0.id) }
    }

    private var totalSelectedAmount: Double {
        selectedGifts.reduce(0) { $0 + $1.amount }
    }

    private var activeScenarioId: String? {
        activeScenario?.id
    }

    private let logger = AppLogger.ui

    // Public initializer
    init(
        isPresented: Binding<Bool>,
        budgetItem: BudgetOverviewItem,
        activeScenario: SavedScenario?,
        onSuccess: @escaping () -> Void
    ) {
        _isPresented = isPresented
        self.budgetItem = budgetItem
        self.activeScenario = activeScenario
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                if let error = errorMessage {
                    errorView(error)
                }

                if isLoading {
                    ProgressView("Loading gifts...")
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            searchSection
                            filterSection

                            if !selectedGiftIds.isEmpty {
                                selectionSummary
                            }

                            giftsList

                            if !selectedGiftIds.isEmpty {
                                allocationPreview
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                footerSection
            }
            .frame(width: 700, height: 650)
            .navigationTitle("Link Gifts to \(budgetItem.itemName)")
        }
        .onAppear {
            Task {
                await loadGifts()
            }
        }
        .onChange(of: searchText) { _, _ in applyFilters() }
        .onChange(of: typeFilter) { _, _ in applyFilters() }
        .onChange(of: statusFilter) { _, _ in applyFilters() }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Select gifts to link to this budget item")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Gifts are allocated proportionally across all linked budget items based on their budgeted amounts.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(budgetItem.itemName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("\(budgetItem.category) • \(budgetItem.subcategory)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Budgeted: \(formatCurrency(budgetItem.budgeted))")
                        .font(.caption)
                        .fontWeight(.medium)
                    if let scenario = activeScenario {
                        Text("Scenario: \(scenario.scenarioName)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(CornerRadius.md)
        }
        .padding()
    }

    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.Budget.overBudget)
            Text(error)
                .font(.caption)
                .foregroundStyle(AppColors.Budget.overBudget)
        }
        .padding()
        .background(AppColors.Budget.overBudget.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
        .padding(.horizontal)
    }

    private var searchSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search gifts by title, description, or person...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Toggle("Hide already linked gifts", isOn: $hideLinkedGifts)
                    .font(.caption)
                    .toggleStyle(.checkbox)
                Spacer()
            }
        }
    }

    private var filterSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Type:")
                    .font(.caption)
                    .fontWeight(.medium)
                Picker("Type", selection: $typeFilter) {
                    Text("All Types").tag("all")
                    Text("Gift Received").tag("gift_received")
                    Text("Money Owed").tag("money_owed")
                    Text("Contribution").tag("contribution")
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Text("Status:")
                    .font(.caption)
                    .fontWeight(.medium)
                Picker("Status", selection: $statusFilter) {
                    Text("All Status").tag("all")
                    Text("Pending").tag("pending")
                    Text("Received").tag("received")
                    Text("Confirmed").tag("confirmed")
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var selectionSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(selectedGiftIds.count) gift\(selectedGiftIds.count == 1 ? "" : "s") selected")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Total: \(formatCurrency(totalSelectedAmount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.Budget.income)
            }

            Spacer()

            Button("Clear Selection") {
                selectedGiftIds.removeAll()
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
        .padding()
        .background(AppColors.Budget.allocated.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    private var giftsList: some View {
        LazyVStack(spacing: Spacing.sm) {
            if availableGifts.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No Available Gifts")
                        .font(.headline)
                        .fontWeight(.medium)
                    Text("All gifts may already be linked to budget items, or try adjusting your filters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.huge)
            } else {
                ForEach(availableGifts) { gift in
                    let hasAllocationsElsewhere = existingAllocations.contains { $0.giftId == gift.id.uuidString }
                    GiftMultiSelectRowView(
                        gift: gift,
                        isSelected: selectedGiftIds.contains(gift.id),
                        isAlreadyLinked: linkedGiftIds.contains(gift.id),
                        hasAllocationsElsewhere: hasAllocationsElsewhere,
                        onToggle: { toggleGiftSelection(gift) }
                    )
                }
            }
        }
    }

    private var allocationPreview: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Allocation Preview")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .help("Gift amounts are distributed proportionally across linked budget items based on their budgeted amounts")
            }

            Text("When linked, these gifts will be proportionally allocated across all budget items they're linked to.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            ForEach(selectedGifts) { gift in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gift.title)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(gift.type.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(gift.amount))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.Budget.income)
                        Text("Full amount to this item")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }

            Divider()

            HStack {
                Text("Total Gift Value:")
                    .fontWeight(.semibold)
                Spacer()
                Text(formatCurrency(totalSelectedAmount))
                    .foregroundStyle(AppColors.Budget.income)
                    .fontWeight(.bold)
            }
            .font(.subheadline)

            // Show note about rebalancing if gifts are already linked elsewhere
            let giftsWithExistingLinks = selectedGifts.filter { gift in
                existingAllocations.contains { $0.giftId == gift.id.uuidString }
            }
            if !giftsWithExistingLinks.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(AppColors.Budget.allocated)
                    Text("Some selected gifts have existing allocations and will be rebalanced proportionally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.sm)
                .background(AppColors.Budget.allocated.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.md)
    }

    private var footerSection: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.plain)

            Spacer()

            if let progress = linkingProgress {
                Text("Linking \(progress.current)/\(progress.total)...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: linkSelectedGifts) {
                if isSubmitting {
                    HStack(spacing: Spacing.xs) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Linking...")
                    }
                } else if activeScenario == nil {
                    Text("Active Scenario Required")
                } else if selectedGiftIds.isEmpty {
                    Text("Select Gifts to Link")
                } else {
                    Text("Link \(selectedGiftIds.count) Gift\(selectedGiftIds.count == 1 ? "" : "s")")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedGiftIds.isEmpty || isSubmitting || activeScenario == nil)
        }
        .padding()
    }

    // MARK: - Actions

    private func toggleGiftSelection(_ gift: GiftOrOwed) {
        if selectedGiftIds.contains(gift.id) {
            selectedGiftIds.remove(gift.id)
        } else {
            selectedGiftIds.insert(gift.id)
        }
    }

    // MARK: - Data Loading and Actions

    private func loadGifts() async {
        isLoading = true
        errorMessage = nil

        do {
            gifts = try await budgetRepository.fetchGiftsAndOwed()
            logger.info("Loaded \(gifts.count) gifts")

            // Get linked gift IDs - gifts already linked to THIS SPECIFIC budget item
            if let scenarioId = activeScenarioId {
                do {
                    // Fetch gift allocations for THIS budget item only (not entire scenario)
                    // This allows a gift to be linked to multiple items
                    let allocationsForThisItem = try await budgetRepository.fetchGiftAllocations(
                        scenarioId: scenarioId,
                        budgetItemId: budgetItem.id
                    )

                    // Mark as "linked" only gifts already allocated to THIS item
                    linkedGiftIds = Set(allocationsForThisItem.compactMap { UUID(uuidString: $0.giftId) })

                    // Also check legacy 1:1 links specifically for this budget item
                    let budgetItems = try await budgetRepository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
                    if let thisItem = budgetItems.first(where: { $0.id == budgetItem.id }),
                       let legacyGiftIdString = thisItem.linkedGiftOwedId,
                       let legacyGiftId = UUID(uuidString: legacyGiftIdString) {
                        linkedGiftIds.insert(legacyGiftId)
                    }

                    // Fetch ALL allocations for scenario to show rebalancing note
                    existingAllocations = try await budgetRepository.fetchGiftAllocationsForScenario(scenarioId: scenarioId)

                    logger.info("Found \(linkedGiftIds.count) gifts already linked to this item, \(existingAllocations.count) total allocations in scenario")
                } catch {
                    logger.error("Failed to fetch linked gift IDs", error: error)
                    linkedGiftIds = Set<UUID>()
                    existingAllocations = []
                }
            }

            applyFilters()
        } catch {
            logger.error("Failed to load gifts", error: error)
            errorMessage = "Failed to load gifts: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func applyFilters() {
        var filtered = gifts

        // Apply type filter
        if typeFilter != "all" {
            filtered = filtered.filter { $0.type.rawValue == typeFilter }
        }

        // Apply status filter
        if statusFilter != "all" {
            filtered = filtered.filter { $0.status.rawValue == statusFilter }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { gift in
                gift.title.localizedCaseInsensitiveContains(searchText) ||
                    gift.description?.localizedCaseInsensitiveContains(searchText) == true ||
                    gift.fromPerson?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        filteredGifts = filtered
    }

    private func linkSelectedGifts() {
        guard let scenarioId = activeScenarioId,
              !selectedGiftIds.isEmpty else {
            logger.warning("Guard failed - scenario or gifts missing")
            return
        }

        isSubmitting = true
        errorMessage = nil
        linkingProgress = (current: 0, total: selectedGiftIds.count)

        Task {
            var successCount = 0
            var failedGifts: [(gift: GiftOrOwed, error: String)] = []

            for (index, giftId) in selectedGiftIds.enumerated() {
                guard let gift = gifts.first(where: { $0.id == giftId }) else {
                    logger.warning("Could not find gift with ID: \(giftId)")
                    continue
                }

                do {
                    // Proportional link: add to current item and rebalance across all linked items
                    try await giftAllocationService.linkGiftProportionally(
                        gift: gift,
                        to: budgetItem.id,
                        inScenario: scenarioId
                    )
                    logger.info("Successfully linked gift: \(gift.title)")
                    successCount += 1

                    await MainActor.run {
                        linkingProgress = (current: index + 1, total: selectedGiftIds.count)
                    }
                } catch {
                    logger.error("Failed to link gift: \(gift.title)", error: error)
                    failedGifts.append((gift: gift, error: error.localizedDescription))
                }
            }

            await MainActor.run {
                isSubmitting = false
                linkingProgress = nil

                if failedGifts.isEmpty {
                    logger.info("Successfully linked all \(successCount) gifts")
                    onSuccess()
                    isPresented = false
                } else {
                    let failedNames = failedGifts.map { $0.gift.title }.joined(separator: ", ")
                    errorMessage = "Failed to link: \(failedNames)"

                    // If some succeeded, still call onSuccess to refresh
                    if successCount > 0 {
                        onSuccess()
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Views

struct GiftMultiSelectRowView: View {
    let gift: GiftOrOwed
    let isSelected: Bool
    let isAlreadyLinked: Bool
    let hasAllocationsElsewhere: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.Budget.allocated : .secondary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(gift.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if isAlreadyLinked {
                            Text("Linked to this item")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.Budget.allocated)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(AppColors.Budget.allocated.opacity(0.15))
                                .cornerRadius(CornerRadius.xs)
                        } else if hasAllocationsElsewhere {
                            Text("Linked elsewhere")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.Budget.income)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(AppColors.Budget.income.opacity(0.15))
                                .cornerRadius(CornerRadius.xs)
                        }
                    }

                    if let description = gift.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: Spacing.sm) {
                        Label(gift.type.displayName, systemImage: gift.type.iconName)
                            .font(.caption2)
                            .foregroundStyle(AppColors.Budget.allocated)

                        Label(gift.status.displayName, systemImage: statusIcon(for: gift.status))
                            .font(.caption2)
                            .foregroundStyle(gift.status.color)

                        if let person = gift.fromPerson {
                            Label(person, systemImage: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(formatCurrency(gift.amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.Budget.income)

                    if let date = gift.receivedDate ?? gift.expectedDate {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? AppColors.Budget.allocated.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? AppColors.Budget.allocated : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func statusIcon(for status: GiftOrOwed.GiftOrOwedStatus) -> String {
        switch status {
        case .received, .confirmed:
            "checkmark.circle.fill"
        case .pending:
            "clock.fill"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Legacy Single-Select Row (Deprecated)

/// Legacy single-select row view - use GiftMultiSelectRowView instead
@available(*, deprecated, message: "Use GiftMultiSelectRowView for proportional allocation")
struct GiftSelectionRowView: View {
    let gift: GiftOrOwed
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gift.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let description = gift.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        Label(gift.type.displayName, systemImage: gift.type.iconName)
                            .font(.caption2)
                            .foregroundStyle(AppColors.Budget.allocated)

                        Label(gift.status.displayName, systemImage: statusIcon(for: gift.status))
                            .font(.caption2)
                            .foregroundStyle(gift.status.color)

                        if let person = gift.fromPerson {
                            Label(person, systemImage: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(gift.amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.Budget.income)

                    if let date = gift.receivedDate ?? gift.expectedDate {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? AppColors.Budget.allocated.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppColors.Budget.allocated : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func statusIcon(for status: GiftOrOwed.GiftOrOwedStatus) -> String {
        switch status {
        case .received, .confirmed:
            "checkmark.circle.fill"
        case .pending:
            "clock.fill"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
