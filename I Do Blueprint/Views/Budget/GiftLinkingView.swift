import SwiftUI

struct GiftLinkingView: View {
    @Binding var isPresented: Bool
    let budgetItem: BudgetOverviewItem
    let activeScenario: SavedScenario?
    let onSuccess: () -> Void

    @EnvironmentObject var budgetStore: BudgetStoreV2

    // State for gifts
    @State private var gifts: [Gift] = []
    @State private var filteredGifts: [Gift] = []
    @State private var selectedGift: Gift?
    @State private var linkedGiftIds: Set<UUID> = []

    // Search and filter state
    @State private var searchText = ""
    @State private var typeFilter = "all"
    @State private var statusFilter = "all"

    // Loading and error state
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var availableGifts: [Gift] {
        filteredGifts.filter { !linkedGiftIds.contains($0.id) }
    }

    private var typeFilterOptions: [String] = ["all", "gift_received", "money_owed", "contribution"]
    private var statusFilterOptions: [String] = ["all", "pending", "received", "confirmed"]

    private let logger = AppLogger.ui

    // Public initializer
    init(
        isPresented: Binding<Bool>,
        budgetItem: BudgetOverviewItem,
        activeScenario: SavedScenario?,
        onSuccess: @escaping () -> Void) {
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
                        VStack(spacing: 16) {
                            searchSection
                            filterSection

                            if selectedGift != nil {
                                selectionSummary
                            }

                            giftsList

                            if selectedGift != nil {
                                linkingPreview
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                footerSection
            }
            .frame(width: 700, height: 600)
            .navigationTitle("Link Gift to \(budgetItem.itemName)")
        }
        .onAppear {
            logger.debug("GiftLinkingView appeared - budgetItem: \(budgetItem.itemName), ID: \(budgetItem.id), activeScenario: \(activeScenario?.scenarioName ?? "nil")")
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a gift to link to this budget item")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budgetItem.itemName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("\(budgetItem.category) • \(budgetItem.subcategory)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
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
            .cornerRadius(8)
        }
        .padding()
    }

    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(6)
        .padding(.horizontal)
    }

    private var searchSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search gifts by title, description, or person...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var filterSection: some View {
        VStack(spacing: 12) {
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Gift")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                if let gift = selectedGift {
                    Text(gift.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            Spacer()

            Button("Clear Selection") {
                selectedGift = nil
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private var giftsList: some View {
        LazyVStack(spacing: 8) {
            if availableGifts.isEmpty {
                VStack(spacing: 8) {
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
                .padding(.vertical, 40)
            } else {
                ForEach(availableGifts) { gift in
                    GiftSelectionRowView(
                        gift: gift,
                        isSelected: selectedGift?.id == gift.id,
                        onSelect: { selectedGift = gift })
                }
            }
        }
    }

    private var linkingPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linking Preview")
                .font(.headline)
                .fontWeight(.semibold)

            if let gift = selectedGift {
                VStack(spacing: 8) {
                    HStack {
                        Text("Budget Item:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(budgetItem.itemName)
                    }

                    HStack {
                        Text("Gift:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(gift.title)
                    }

                    HStack {
                        Text("Gift Value:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(formatCurrency(gift.amount))
                            .foregroundStyle(.green)
                    }

                    HStack {
                        Text("Gift Type:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(gift.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    }

                    Divider()

                    HStack {
                        Text("Effect on Budget:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("-\(formatCurrency(min(gift.amount, budgetItem.budgeted)))")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var footerSection: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: linkGift) {
                if isSubmitting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Linking...")
                    }
                } else if activeScenario == nil {
                    Text("Active Scenario Required")
                } else {
                    Text("Link Gift")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedGift == nil || isSubmitting || activeScenario == nil)
        }
        .padding()
    }

    // MARK: - Data Loading and Actions

    private func loadGifts() async {
        isLoading = true
        errorMessage = nil

        do {
            logger.debug("Loading gifts from Supabase")
            gifts = try await SupabaseManager.shared.fetchGifts()
            logger.info("Loaded \(gifts.count) gifts")

            // Get linked gift IDs from all budget items in the scenario to exclude them
            if activeScenario != nil {
                // TODO: Fetch linked gift IDs from scenario - for now, we'll use an empty set
                linkedGiftIds = Set<UUID>()
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
            filtered = filtered.filter { $0.type == typeFilter }
        }

        // Apply status filter
        if statusFilter != "all" {
            filtered = filtered.filter { $0.status == statusFilter }
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

    private func linkGift() {
        logger.debug("LinkGift called")
        guard let scenario = activeScenario,
              let gift = selectedGift else {
            logger.warning("Guard failed - scenario or gift missing")
            return
        }

        logger.debug("Starting gift linking process - gift: \(gift.id), budgetItem: \(budgetItem.id)")
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.linkGiftToBudgetItem(
                    giftId: gift.id.uuidString,
                    budgetItemId: budgetItem.id)
                logger.info("Successfully linked gift to budget item")

                await MainActor.run {
                    onSuccess()
                    isPresented = false
                }
            } catch {
                logger.error("Failed to link gift", error: error)
                await MainActor.run {
                    errorMessage = "Failed to link gift: \(error.localizedDescription)"
                }
            }

            await MainActor.run {
                isSubmitting = false
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Views

struct GiftSelectionRowView: View {
    let gift: Gift
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
                        Label(gift.type.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "tag.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)

                        Label(gift.status.capitalized, systemImage: statusIcon(for: gift.status))
                            .font(.caption2)
                            .foregroundStyle(statusColor(for: gift.status))

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
                        .foregroundStyle(.green)

                    if let date = gift.receivedDate ?? gift.expectedDate {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func statusIcon(for status: String) -> String {
        switch status {
        case "received", "confirmed":
            "checkmark.circle.fill"
        case "pending":
            "clock.fill"
        default:
            "questionmark.circle.fill"
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "received", "confirmed":
            .green
        case "pending":
            .orange
        default:
            .secondary
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
