//
//  LinkBillsToExpenseModal.swift
//  I Do Blueprint
//
//  Modal view for linking bill calculators to an expense
//  Features: Search, bill list, selection summary, coverage bar
//

import SwiftUI

// MARK: - Link Bills To Expense Modal

struct LinkBillsToExpenseModal: View {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator

    // MARK: - Properties

    let expense: Expense
    let category: BudgetCategory?
    let onDismiss: () -> Void
    let onLinkComplete: () -> Void

    // MARK: - State

    @State private var billCalculators: [BillCalculator] = []
    @State private var linkedBillIds: Set<UUID> = []
    @State private var selectedBillIds: Set<UUID> = []
    @State private var searchText: String = ""
    @State private var hideAlreadyLinked: Bool = false
    @State private var isLoading: Bool = true
    @State private var isLinking: Bool = false
    @State private var linkNotes: String = ""
    @State private var showConfiguration: Bool = false

    // MARK: - Size Constants

    private let minWidth: CGFloat = 500
    private let maxWidth: CGFloat = 560
    private let minHeight: CGFloat = 500
    private let maxHeight: CGFloat = 600
    private let windowChromeBuffer: CGFloat = 40

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.55))
        let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
        return CGSize(width: targetWidth, height: targetHeight)
    }

    // MARK: - Computed Properties

    /// Filtered bill calculators based on search and hide linked toggle
    private var filteredBillCalculators: [BillCalculator] {
        var result = billCalculators

        // Filter by search
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            result = result.filter { calculator in
                calculator.name.lowercased().contains(lowercasedSearch) ||
                (calculator.vendorName?.lowercased().contains(lowercasedSearch) ?? false) ||
                (calculator.eventName?.lowercased().contains(lowercasedSearch) ?? false)
            }
        }

        // Filter out already linked if toggle is on
        if hideAlreadyLinked {
            result = result.filter { !linkedBillIds.contains($0.id) }
        }

        return result
    }

    /// Total amount of selected bills
    private var selectedBillsTotal: Double {
        billCalculators
            .filter { selectedBillIds.contains($0.id) }
            .reduce(0) { $0 + $1.grandTotal }
    }

    /// Coverage percentage (bills / expense)
    private var coveragePercent: Double {
        guard expense.amount > 0 else { return 0 }
        return min(100, (selectedBillsTotal / expense.amount) * 100)
    }

    /// Amount difference between selected bills and expense
    private var amountDifference: Double {
        selectedBillsTotal - expense.amount
    }

    /// Whether selected bills exceed expense amount
    private var exceedsExpense: Bool {
        amountDifference > 0
    }

    /// Uncovered amount (expense - bills)
    private var uncoveredAmount: Double {
        max(0, expense.amount - selectedBillsTotal)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Search and filter section
            searchFilterSection

            // Bills list
            billsListSection

            // Selection summary bar (only when bills selected)
            if !selectedBillIds.isEmpty {
                selectionSummaryBar
            }

            // Link configuration (collapsible)
            linkConfigurationSection

            // Coverage bar
            if !selectedBillIds.isEmpty {
                coverageBarSection
            }

            // Footer
            footerSection
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(SemanticColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .onAppear {
            loadData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                Text("Link Bills to Expense")
                    .font(Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                // Close button
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SemanticColors.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(SemanticColors.backgroundTertiary.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Expense info
            HStack(spacing: Spacing.sm) {
                // Category badge
                if let cat = category {
                    categoryBadge(cat)
                }

                Text(expense.expenseName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                Text(formatCurrency(expense.amount))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Text("Select bill calculators to associate with this expense")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(SemanticColors.backgroundPrimary)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Category Badge

    private func categoryBadge(_ category: BudgetCategory) -> some View {
        let categoryColor = Color.fromHex(category.color)

        return HStack(spacing: Spacing.xs) {
            Image(systemName: categoryIcon(for: category.categoryName))
                .font(.system(size: 10))
            Text(category.categoryName.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
        }
        .foregroundColor(categoryColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(categoryColor.opacity(Opacity.light))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }

    // MARK: - Search Filter Section

    private var searchFilterSection: some View {
        VStack(spacing: Spacing.sm) {
            // Search field
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.textTertiary)

                TextField("Search bills by name, vendor, or event...", text: $searchText)
                    .font(Typography.bodyRegular)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(SemanticColors.backgroundPrimary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )

            // Filter row
            HStack {
                // Hide already linked toggle
                Toggle(isOn: $hideAlreadyLinked) {
                    Text("Hide already linked")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .toggleStyle(.checkbox)

                Spacer()

                // Select all / Clear buttons
                HStack(spacing: Spacing.sm) {
                    Button {
                        selectAllBills()
                    } label: {
                        Text("Select All")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.primaryAction)
                    }
                    .buttonStyle(.plain)

                    Text("•")
                        .foregroundColor(SemanticColors.textTertiary)

                    Button {
                        selectedBillIds.removeAll()
                    } label: {
                        Text("Clear")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(SemanticColors.backgroundSecondary)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Bills List Section

    private var billsListSection: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                    Text("Loading bill calculators...")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, Spacing.xxl)
            } else if filteredBillCalculators.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(filteredBillCalculators) { calculator in
                        LinkBillsItemRowView(
                            billCalculator: calculator,
                            isSelected: selectedBillIds.contains(calculator.id),
                            isLinked: linkedBillIds.contains(calculator.id),
                            onToggle: {
                                toggleSelection(calculator.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(SemanticColors.textTertiary)

            VStack(spacing: Spacing.xs) {
                Text(searchText.isEmpty ? "No bill calculators found" : "No matching bills")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(searchText.isEmpty
                     ? "Create bill calculators to link them to expenses"
                     : "Try adjusting your search or filters")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Selection Summary Bar

    private var selectionSummaryBar: some View {
        HStack {
            HStack(spacing: Spacing.md) {
                Text("\(selectedBillIds.count) \(selectedBillIds.count == 1 ? "bill" : "bills") selected")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("•")
                    .foregroundColor(SemanticColors.textTertiary)

                Text(formatCurrency(selectedBillsTotal))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Spacer()

            // Warning if exceeds expense
            if exceedsExpense {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("Exceeds expense by \(formatCurrency(amountDifference))")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(SemanticColors.statusWarning)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(SemanticColors.primaryAction.opacity(Opacity.verySubtle))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SemanticColors.primaryAction.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - Link Configuration Section

    private var linkConfigurationSection: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showConfiguration.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showConfiguration ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(SemanticColors.textTertiary)

                    Text("LINK CONFIGURATION")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(SemanticColors.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(SemanticColors.backgroundSecondary)

            // Collapsible content
            if showConfiguration {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("NOTES (OPTIONAL)")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(SemanticColors.textTertiary)

                    TextField("Add notes about this link...", text: $linkNotes)
                        .font(Typography.bodyRegular)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(SemanticColors.backgroundPrimary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(SemanticColors.borderLight, lineWidth: 1)
                        )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.md)
                .background(SemanticColors.backgroundSecondary)
            }
        }
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: - Coverage Bar Section

    private var coverageBarSection: some View {
        VStack(spacing: Spacing.sm) {
            // Header row
            HStack {
                Text("Coverage")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                HStack(spacing: Spacing.md) {
                    Text("Expense: \(formatCurrency(expense.amount))")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("•")
                        .foregroundColor(SemanticColors.textTertiary)

                    Text("Bills: \(formatCurrency(selectedBillsTotal))")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SemanticColors.borderLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(coverageBarGradient)
                        .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(coveragePercent / 100)), height: 8)
                }
            }
            .frame(height: 8)

            // Footer row
            HStack {
                Text("\(Int(coveragePercent))% of expense covered")
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)

                Spacer()

                if uncoveredAmount > 0 {
                    Text("\(formatCurrency(uncoveredAmount)) uncovered")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(SemanticColors.textPrimary)
                } else {
                    Text("Fully covered")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(SemanticColors.statusSuccess)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(SemanticColors.backgroundTertiary)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    /// Gradient for coverage bar based on coverage percentage
    private var coverageBarGradient: LinearGradient {
        if coveragePercent >= 100 {
            return LinearGradient(
                colors: [SemanticColors.statusSuccess, SemanticColors.statusSuccess.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [SemanticColors.statusWarning, Color.fromHex("#F59E0B")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: Spacing.md) {
            // Cancel button
            Button {
                onDismiss()
            } label: {
                Text("Cancel")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .frame(maxWidth: 100)
                    .padding(.vertical, Spacing.sm)
                    .background(SemanticColors.backgroundPrimary)
                    .foregroundColor(SemanticColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)

            // Link button
            Button {
                linkSelectedBills()
            } label: {
                HStack(spacing: Spacing.sm) {
                    if isLinking {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                    }
                    Text("Link \(selectedBillIds.count) \(selectedBillIds.count == 1 ? "Bill" : "Bills")")
                        .fontWeight(.semibold)
                }
                .font(Typography.bodyRegular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [SemanticColors.primaryAction, SemanticColors.primaryActionHover],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
            .disabled(selectedBillIds.isEmpty || isLinking)
            .opacity(selectedBillIds.isEmpty ? 0.6 : 1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        Task {
            isLoading = true

            // Load bill calculators
            await AppStores.shared.billCalculator.loadCalculators()
            billCalculators = AppStores.shared.billCalculator.calculators

            // Load existing links for this expense
            do {
                let links = try await budgetStore.repository.fetchBillCalculatorLinksForExpense(expenseId: expense.id)
                linkedBillIds = Set(links.map { $0.billCalculatorId })
            } catch {
                AppLogger.ui.error("Failed to load expense bill links", error: error)
            }

            isLoading = false
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ billId: UUID) {
        if selectedBillIds.contains(billId) {
            selectedBillIds.remove(billId)
        } else {
            selectedBillIds.insert(billId)
        }
    }

    private func selectAllBills() {
        for calculator in filteredBillCalculators {
            if !linkedBillIds.contains(calculator.id) {
                selectedBillIds.insert(calculator.id)
            }
        }
    }

    private func linkSelectedBills() {
        guard !selectedBillIds.isEmpty else { return }

        Task {
            isLinking = true

            do {
                let billIds = Array(selectedBillIds)
                _ = try await budgetStore.repository.linkBillCalculatorsToExpense(
                    expenseId: expense.id,
                    billCalculatorIds: billIds,
                    linkType: .full,
                    notes: linkNotes.isEmpty ? nil : linkNotes
                )

                AppLogger.ui.info("Successfully linked \(billIds.count) bills to expense \(expense.id)")
                onLinkComplete()
            } catch {
                AppLogger.ui.error("Failed to link bills to expense", error: error)
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(operation: "linkBillsToExpense", feature: "expenseTracking")
                )
            }

            isLinking = false
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsStore.settings.global.currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func categoryIcon(for category: String) -> String {
        let lowercased = category.lowercased()
        if lowercased.contains("venue") { return "building.columns" }
        if lowercased.contains("catering") || lowercased.contains("food") { return "fork.knife" }
        if lowercased.contains("photo") { return "camera" }
        if lowercased.contains("flower") || lowercased.contains("floral") { return "leaf" }
        if lowercased.contains("music") || lowercased.contains("band") { return "music.note" }
        if lowercased.contains("dress") || lowercased.contains("attire") { return "tshirt" }
        if lowercased.contains("cake") { return "birthday.cake" }
        if lowercased.contains("video") { return "video" }
        return "tag"
    }
}

// MARK: - Preview

#Preview("Link Bills to Expense Modal") {
    let mockExpense = Expense(
        id: UUID(),
        coupleId: UUID(),
        budgetCategoryId: UUID(),
        vendorId: nil,
        vendorName: "Grand Ballroom Catering",
        expenseName: "Full Catering Service",
        amount: 12500.00,
        expenseDate: Date().addingTimeInterval(86400 * 30),
        paymentMethod: "credit_card",
        paymentStatus: .pending,
        receiptUrl: nil,
        invoiceNumber: nil,
        notes: nil,
        approvalStatus: nil,
        approvedBy: nil,
        approvedAt: nil,
        invoiceDocumentUrl: nil,
        isTestData: true,
        createdAt: Date()
    )

    let mockCategory = BudgetCategory(
        id: UUID(),
        coupleId: UUID(),
        categoryName: "Venue",
        allocatedAmount: 15000,
        spentAmount: 8500,
        priorityLevel: 1,
        isEssential: true,
        forecastedAmount: 14500,
        confidenceLevel: 0.85,
        lockedAllocation: false,
        color: "#FB7185",
        createdAt: Date()
    )

    LinkBillsToExpenseModal(
        expense: mockExpense,
        category: mockCategory,
        onDismiss: {},
        onLinkComplete: {}
    )
    .environmentObject(BudgetStoreV2())
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}
