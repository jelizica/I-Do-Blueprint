//
//  LinkExpensesModalV2.swift
//  I Do Blueprint
//
//  Modal for linking expenses to a budget item
//  Layout follows HTML reference: single column with collapsible allocation preview at bottom
//  Styling uses app design system (SemanticColors, Typography, Spacing)
//

import SwiftUI
import Dependencies

// MARK: - Link Expenses Modal V2

struct LinkExpensesModalV2: View {
    // MARK: - Environment & Dependencies

    @EnvironmentObject var budgetStore: BudgetStoreV2
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @Dependency(\.budgetRepository) var budgetRepository
    @Dependency(\.budgetAllocationService) var allocationService

    // MARK: - Properties

    let budgetItem: BudgetOverviewItem
    let categoryName: String
    let categoryColor: Color
    let onComplete: () -> Void
    var onCancel: (() -> Void)?

    // MARK: - State

    @State private var searchText: String = ""
    @State private var selectedExpenseIds: Set<UUID> = []
    @State private var expenses: [Expense] = []
    @State private var isLoading: Bool = true
    @State private var isLinking: Bool = false
    @State private var showAllocationPreview: Bool = false
    @State private var linkedExpenseIds: Set<UUID> = []
    @State private var hideLinkedExpenses: Bool = false
    @State private var errorMessage: String?
    @State private var linkingProgress: (current: Int, total: Int)?

    // MARK: - Computed Properties

    private var activeScenario: BudgetDevelopmentScenario? {
        budgetStore.primaryScenario
    }

    private var activeScenarioId: String? {
        activeScenario?.id.uuidString
    }

    private var filteredExpenses: [Expense] {
        expenses.filter { expense in
            // Filter by search text
            let matchesSearch = searchText.isEmpty ||
                expense.expenseName.localizedCaseInsensitiveContains(searchText) ||
                (expense.vendorName ?? "").localizedCaseInsensitiveContains(searchText)

            // Filter by linked status if toggle is on
            let matchesLinkedFilter = !hideLinkedExpenses || !linkedExpenseIds.contains(expense.id)

            return matchesSearch && matchesLinkedFilter
        }
    }

    private var availableExpenses: [Expense] {
        filteredExpenses.filter { !linkedExpenseIds.contains($0.id) }
    }

    private var selectedExpenses: [Expense] {
        expenses.filter { selectedExpenseIds.contains($0.id) }
    }

    private var totalSelectedAmount: Double {
        selectedExpenses.reduce(0) { $0 + $1.amount }
    }

    private var remainingBudget: Double {
        budgetItem.budgeted - budgetItem.spent
    }

    private var isOverBudget: Bool {
        totalSelectedAmount > remainingBudget && remainingBudget > 0
    }

    private var currentAllocated: Double {
        budgetItem.spent
    }

    private var afterLinking: Double {
        currentAllocated + totalSelectedAmount
    }

    private var utilizationPercentage: Double {
        guard budgetItem.budgeted > 0 else { return 0 }
        return min((afterLinking / budgetItem.budgeted) * 100, 100)
    }

    private var isWithinBudget: Bool {
        afterLinking <= budgetItem.budgeted
    }

    private let logger = AppLogger.ui

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient and chips
            headerSection

            // Search and filter section
            searchFilterSection

            // Selection summary bar (only shown when items selected)
            if !selectedExpenseIds.isEmpty {
                selectionSummaryBar
            }

            // Expense list (full width, scrollable)
            expenseListSection

            // Collapsible Allocation Preview at bottom
            allocationPreviewSection

            // Footer with actions
            footerSection
        }
        .frame(width: 560, height: 560)
        .background(SemanticColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .shadow(color: SemanticColors.shadow, radius: 20, x: 0, y: 10)
        .task {
            await loadExpenses()
        }
        .onChange(of: budgetStore.expenseStore.refreshTrigger) { _, _ in
            // Expense amounts changed (e.g., linked bill calculator updated)
            // Refresh expenses to show updated amounts from database
            Task {
                logger.info("LinkExpensesModal: Refreshing due to expense amount change")
                await loadExpenses()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Gradient header with title and close button
            HStack {
                Text("Link Expenses")
                    .font(Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textOnPrimary)

                Spacer()

                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SemanticColors.textOnPrimary.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        SemanticColors.primaryAction,
                        SemanticColors.primaryActionHover
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // Info chips row (Budget Item + Scenario)
            HStack(spacing: Spacing.sm) {
                // Budget Item chip
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 10))
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("Budget Item:")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(budgetItem.itemName)
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.primaryAction)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(SemanticColors.backgroundPrimary)
                .cornerRadius(CornerRadius.sm)

                // Scenario chip
                if let scenario = activeScenario {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 10))
                            .foregroundColor(SemanticColors.textSecondary)

                        Text("Scenario: \(scenario.scenarioName)")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.backgroundPrimary)
                    .cornerRadius(CornerRadius.sm)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(SemanticColors.backgroundSecondary)
        }
    }

    // MARK: - Search and Filter Section

    private var searchFilterSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                // Search field
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textTertiary)

                    TextField("Search expenses by name, vendor, or category...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(Typography.caption)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(SemanticColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderLight, lineWidth: 1)
                )

                // Filters button
                Button {
                    // TODO: Show filters popover
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12))
                        Text("Filters")
                            .font(Typography.caption)
                    }
                    .foregroundColor(SemanticColors.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.controlBackground)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.borderLight, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // Toggle and linked count row
            HStack {
                // Hide linked toggle
                Toggle(isOn: $hideLinkedExpenses) {
                    Text("Hide already linked expenses")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                Spacer()

                // Currently linked badge
                if !linkedExpenseIds.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Text("Currently linked:")
                            .font(.system(size: 10))
                            .foregroundColor(SemanticColors.textTertiary)

                        Text("\(linkedExpenseIds.count) expenses")
                            .font(.system(size: 10))
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.primaryAction)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(SemanticColors.primaryAction.opacity(Opacity.verySubtle))
                            .cornerRadius(CornerRadius.pill)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(SemanticColors.backgroundTertiary)
    }

    // MARK: - Selection Summary Bar

    private var selectionSummaryBar: some View {
        HStack {
            // Select All button
            Button {
                toggleSelectAll()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Select All")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(SemanticColors.primaryAction)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(SemanticColors.borderLight)
                .frame(width: 1, height: 12)

            // Selection count
            Text("\(selectedExpenseIds.count) expenses selected")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            Spacer()

            // Clear selection button
            Button {
                selectedExpenseIds.removeAll()
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                    Text("Clear Selection")
                        .font(Typography.caption)
                }
                .foregroundColor(SemanticColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xs)
        .background(SemanticColors.primaryAction.opacity(0.05))
    }

    // MARK: - Expense List Section

    private var expenseListSection: some View {
        Group {
            if isLoading {
                loadingView
            } else if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(filteredExpenses) { expense in
                            expenseItemRow(expense: expense)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(SemanticColors.backgroundPrimary)
    }

    @ViewBuilder
    private func expenseItemRow(expense: Expense) -> some View {
        let isSelected = selectedExpenseIds.contains(expense.id)
        let isLinked = linkedExpenseIds.contains(expense.id)

        HStack(spacing: Spacing.sm) {
            // Checkbox
            ZStack {
                if isLinked {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(SemanticColors.statusSuccess)
                } else if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SemanticColors.primaryAction)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(SemanticColors.borderLight, lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(SemanticColors.controlBackground)
                        )
                }
            }
            .frame(width: 20, height: 20)

            // Main content
            VStack(alignment: .leading, spacing: 2) {
                // Top row: Name and amount
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(expense.expenseName)
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(isLinked ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                            .lineLimit(1)

                        if let vendor = expense.vendorName, !vendor.isEmpty {
                            Text(vendor)
                                .font(.system(size: 10))
                                .foregroundColor(SemanticColors.textTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Amount and due date
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(formatCurrency(expense.amount))
                            .font(Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(isLinked ? SemanticColors.textTertiary : SemanticColors.textPrimary)

                        Text("Due: \(formatShortDate(expense.expenseDate))")
                            .font(.system(size: 9))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }

                // Tags row
                HStack(spacing: Spacing.xs) {
                    // Category tag
                    categoryTag(for: expense)

                    // Status tag
                    statusTag(for: expense.paymentStatus)

                    // Date tag
                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.system(size: 8))
                        Text(formatRelativeDate(expense.expenseDate))
                            .font(.system(size: 9))
                    }
                    .foregroundColor(SemanticColors.textTertiary)

                    Spacer()

                    // Linked indicator
                    if isLinked {
                        HStack(spacing: 2) {
                            Image(systemName: "link")
                                .font(.system(size: 8))
                            Text("Linked")
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(SemanticColors.statusSuccess)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 1)
                        .background(SemanticColors.statusSuccess.opacity(Opacity.verySubtle))
                        .cornerRadius(CornerRadius.pill)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            isSelected ? SemanticColors.primaryAction.opacity(Opacity.verySubtle) : SemanticColors.backgroundPrimary
        )
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    isSelected ? SemanticColors.primaryAction : (isLinked ? SemanticColors.statusSuccess.opacity(Opacity.light) : SemanticColors.borderLight),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .opacity(isLinked ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isLinked {
                toggleExpense(expense)
            }
        }
    }

    @ViewBuilder
    private func categoryTag(for expense: Expense) -> some View {
        let (icon, color) = categoryIconAndColor(for: expense.vendorName ?? expense.expenseName)

        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(categoryNameFor(expense: expense))
                .font(.system(size: 9))
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 1)
        .background(color.opacity(Opacity.verySubtle))
        .cornerRadius(CornerRadius.pill)
    }

    @ViewBuilder
    private func statusTag(for status: PaymentStatus) -> some View {
        let (icon, label, color) = statusInfo(for: status)

        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 9))
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 1)
        .background(color.opacity(Opacity.verySubtle))
        .cornerRadius(CornerRadius.pill)
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.0)
            Text("Loading expenses...")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(SemanticColors.textTertiary)

            Text("No expenses found")
                .font(Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Try adjusting your search filter")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }

    // MARK: - Allocation Preview Section (Collapsible at bottom)

    private var allocationPreviewSection: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAllocationPreview.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.primaryAction)

                        Text("Allocation Preview")
                            .font(Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.textPrimary)
                    }

                    Spacer()

                    Image(systemName: showAllocationPreview ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(SemanticColors.textTertiary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .background(SemanticColors.borderLight.opacity(0.3))

            // Expandable content
            if showAllocationPreview {
                VStack(spacing: Spacing.sm) {
                    // Two-column info row
                    HStack(spacing: Spacing.sm) {
                        // Allocation Method card
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Allocation Method")
                                .font(.system(size: 9))
                                .foregroundColor(SemanticColors.textTertiary)

                            HStack(spacing: Spacing.xxs) {
                                Image(systemName: "percent")
                                    .font(.system(size: 10))
                                    .foregroundColor(SemanticColors.primaryAction)
                                Text("Proportional Split")
                                    .font(Typography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(SemanticColors.textPrimary)
                            }
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SemanticColors.backgroundPrimary)
                        .cornerRadius(CornerRadius.sm)

                        // Total Selected card
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Total Selected Expenses")
                                .font(.system(size: 9))
                                .foregroundColor(SemanticColors.textTertiary)

                            Text(formatCurrency(totalSelectedAmount))
                                .font(Typography.bodySmall)
                                .fontWeight(.bold)
                                .foregroundColor(SemanticColors.primaryAction)
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SemanticColors.backgroundPrimary)
                        .cornerRadius(CornerRadius.sm)
                    }

                    // Budget Impact card
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text("Budget Impact")
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(SemanticColors.textPrimary)

                            Spacer()

                            Text("\(categoryName) Budget")
                                .font(.system(size: 9))
                                .foregroundColor(SemanticColors.textTertiary)
                        }

                        // Current Allocated
                        HStack {
                            Text("Current Allocated")
                                .font(.system(size: 10))
                                .foregroundColor(SemanticColors.textSecondary)
                            Spacer()
                            Text(formatCurrency(currentAllocated))
                                .font(Typography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(SemanticColors.textPrimary)
                        }

                        // After Linking
                        HStack {
                            Text("After Linking (+\(selectedExpenseIds.count) expenses)")
                                .font(.system(size: 10))
                                .foregroundColor(SemanticColors.textSecondary)
                            Spacer()
                            Text(formatCurrency(afterLinking))
                                .font(Typography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(SemanticColors.primaryAction)
                        }

                        Divider()

                        // Budget Limit
                        HStack {
                            Text("Budget Limit")
                                .font(.system(size: 10))
                                .foregroundColor(SemanticColors.textSecondary)
                            Spacer()
                            Text(formatCurrency(budgetItem.budgeted))
                                .font(Typography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(SemanticColors.textPrimary)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(SemanticColors.controlBackground)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [SemanticColors.primaryAction, SemanticColors.secondaryAction],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(utilizationPercentage / 100))
                            }
                        }
                        .frame(height: 4)

                        // Status row
                        HStack {
                            Text("\(String(format: "%.1f", utilizationPercentage))% utilized")
                                .font(.system(size: 9))
                                .foregroundColor(SemanticColors.textTertiary)

                            Spacer()

                            HStack(spacing: 2) {
                                Image(systemName: isWithinBudget ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 9))
                                Text(isWithinBudget ? "Within budget" : "Over budget")
                                    .font(.system(size: 9))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(isWithinBudget ? SemanticColors.statusSuccess : SemanticColors.statusWarning)
                        }
                    }
                    .padding(Spacing.sm)
                    .background(SemanticColors.backgroundPrimary)
                    .cornerRadius(CornerRadius.sm)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.primaryAction.opacity(0.03))
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            // Status indicators (left side)
            HStack(spacing: Spacing.sm) {
                // Auto-saved indicator
                HStack(spacing: Spacing.xxs) {
                    Circle()
                        .fill(SemanticColors.statusSuccess)
                        .frame(width: 5, height: 5)
                    Text("Auto-saved")
                        .font(.system(size: 9))
                        .foregroundColor(SemanticColors.textTertiary)
                }

                Rectangle()
                    .fill(SemanticColors.borderLight)
                    .frame(width: 1, height: 10)

                // Last updated
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text("Last updated: just now")
                        .font(.system(size: 9))
                }
                .foregroundColor(SemanticColors.textTertiary)
            }

            Spacer()

            // Error message or progress (center area)
            if let error = errorMessage {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(SemanticColors.statusWarning)
                    Text(error)
                        .font(.system(size: 9))
                        .foregroundColor(SemanticColors.statusWarning)
                        .lineLimit(1)
                }
                .frame(maxWidth: 150)
            } else if let progress = linkingProgress {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("\(progress.current)/\(progress.total)")
                        .font(.system(size: 9))
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }

            // Action buttons (right side)
            HStack(spacing: Spacing.sm) {
                Button("Cancel") {
                    dismiss()
                    // If onCancel callback exists, call it after dismissing
                    // This allows reopening the BudgetItemDetailModal
                    if let onCancel = onCancel {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onCancel()
                        }
                    }
                }
                .buttonStyle(.plain)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderLight, lineWidth: 1)
                )

                Button {
                    Task {
                        await linkSelectedExpenses()
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        if isLinking {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(.white)
                        } else {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                        }
                        Text(linkButtonTitle)
                            .font(Typography.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Group {
                            if selectedExpenseIds.isEmpty || activeScenario == nil {
                                SemanticColors.primaryAction.opacity(0.5)
                            } else {
                                LinearGradient(
                                    colors: [SemanticColors.primaryAction, SemanticColors.secondaryAction],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(selectedExpenseIds.isEmpty || isLinking || activeScenario == nil)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(SemanticColors.backgroundSecondary)
    }

    private var linkButtonTitle: String {
        if activeScenario == nil {
            return "No Scenario"
        } else if selectedExpenseIds.isEmpty {
            return "Link Expenses"
        } else if selectedExpenseIds.count == 1 {
            return "Link 1 Expense"
        } else {
            return "Link \(selectedExpenseIds.count) Expenses"
        }
    }

    // MARK: - Actions

    private func toggleSelectAll() {
        if selectedExpenseIds.count == availableExpenses.count {
            selectedExpenseIds.removeAll()
        } else {
            selectedExpenseIds = Set(availableExpenses.map { $0.id })
        }
    }

    private func toggleExpense(_ expense: Expense) {
        guard !linkedExpenseIds.contains(expense.id) else { return }

        if selectedExpenseIds.contains(expense.id) {
            selectedExpenseIds.remove(expense.id)
        } else {
            selectedExpenseIds.insert(expense.id)
        }
    }

    private func loadExpenses() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all expenses using repository
            let allExpenses = try await budgetRepository.fetchExpenses()

            // Fetch linked expense allocations for current scenario and budget item
            if let scenarioId = activeScenarioId {
                let allocations = try await budgetRepository.fetchExpenseAllocations(
                    scenarioId: scenarioId,
                    budgetItemId: budgetItem.id
                )
                await MainActor.run {
                    linkedExpenseIds = Set(allocations.map { UUID(uuidString: $0.expenseId) }.compactMap { $0 })
                }
            }

            await MainActor.run {
                expenses = allExpenses
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load expenses: \(error.localizedDescription)"
                isLoading = false
            }
            logger.error("LinkExpensesModalV2: Failed to load expenses", error: error)
        }
    }

    private func linkSelectedExpenses() async {
        guard let scenarioId = activeScenarioId,
              !selectedExpenseIds.isEmpty else {
            logger.warning("LinkExpensesModalV2: Guard failed - scenario exists: \(activeScenario != nil), has selected expenses: \(!selectedExpenseIds.isEmpty)")
            return
        }

        await MainActor.run {
            isLinking = true
            errorMessage = nil
            linkingProgress = (current: 0, total: selectedExpenseIds.count)
        }

        var successCount = 0
        var failedExpenses: [(expense: Expense, error: String)] = []

        for (index, expenseId) in selectedExpenseIds.enumerated() {
            guard let expense = expenses.first(where: { $0.id == expenseId }) else {
                logger.warning("LinkExpensesModalV2: Could not find expense with ID: \(expenseId)")
                continue
            }

            do {
                // Proportional link: add to current item and rebalance across all linked items
                try await allocationService.linkExpenseProportionally(
                    expense: expense,
                    to: budgetItem.id,
                    inScenario: scenarioId
                )
                logger.info("LinkExpensesModalV2: Successfully linked expense: \(expense.expenseName)")
                successCount += 1

                await MainActor.run {
                    linkingProgress = (current: index + 1, total: selectedExpenseIds.count)
                }
            } catch {
                logger.error("LinkExpensesModalV2: Failed to create allocation for expense \(expense.expenseName)", error: error)
                failedExpenses.append((expense, error.localizedDescription))
                await MainActor.run {
                    linkingProgress = (current: index + 1, total: selectedExpenseIds.count)
                }
            }
        }

        await MainActor.run {
            if failedExpenses.isEmpty {
                logger.info("LinkExpensesModalV2: All \(successCount) expenses linked successfully!")
                onComplete()
                dismiss()
            } else if successCount == 0 {
                logger.error("LinkExpensesModalV2: All expenses failed to link")
                errorMessage = "Failed to link all expenses: \(failedExpenses.map(\.error).joined(separator: ", "))"
            } else {
                logger.warning("LinkExpensesModalV2: Mixed results - \(successCount) success, \(failedExpenses.count) failed")
                errorMessage = "Linked \(successCount) expenses. Failed: \(failedExpenses.map { "\($0.expense.expenseName)" }.joined(separator: ", "))"
                onComplete()
            }

            isLinking = false
            linkingProgress = nil
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Added \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private func categoryIconAndColor(for name: String) -> (String, Color) {
        let lowercased = name.lowercased()
        if lowercased.contains("venue") {
            return ("mappin.circle.fill", SemanticColors.statusWarning)
        } else if lowercased.contains("catering") || lowercased.contains("food") {
            return ("fork.knife", SemanticColors.secondaryAction)
        } else if lowercased.contains("beverage") || lowercased.contains("bar") {
            return ("wineglass.fill", SemanticColors.secondaryAction)
        } else if lowercased.contains("photo") {
            return ("camera.fill", SemanticColors.accent)
        } else if lowercased.contains("floral") || lowercased.contains("flower") {
            return ("leaf.fill", SemanticColors.statusSuccess)
        } else if lowercased.contains("entertainment") || lowercased.contains("music") || lowercased.contains("dj") {
            return ("music.note", SemanticColors.primaryAction)
        } else if lowercased.contains("cake") || lowercased.contains("dessert") {
            return ("birthday.cake.fill", SemanticColors.statusPending)
        } else if lowercased.contains("stationery") || lowercased.contains("invitation") {
            return ("envelope.fill", SemanticColors.statusInfo)
        } else if lowercased.contains("attire") || lowercased.contains("dress") {
            return ("tshirt.fill", SemanticColors.accent)
        }
        return ("tag.fill", SemanticColors.textSecondary)
    }

    private func categoryNameFor(expense: Expense) -> String {
        let name = (expense.vendorName ?? expense.expenseName).lowercased()
        if name.contains("venue") { return "Venue" }
        if name.contains("catering") || name.contains("food") { return "Catering" }
        if name.contains("beverage") || name.contains("bar") { return "Beverages" }
        if name.contains("photo") { return "Photography" }
        if name.contains("floral") || name.contains("flower") { return "Florals" }
        if name.contains("entertainment") || name.contains("music") || name.contains("dj") { return "Entertainment" }
        if name.contains("cake") || name.contains("dessert") { return "Dessert" }
        if name.contains("stationery") || name.contains("invitation") { return "Stationery" }
        if name.contains("attire") || name.contains("dress") { return "Attire" }
        return categoryName
    }

    private func statusInfo(for status: PaymentStatus) -> (String, String, Color) {
        switch status {
        case .paid:
            return ("checkmark.circle.fill", "Paid", SemanticColors.statusSuccess)
        case .pending:
            return ("clock.fill", "Pending", SemanticColors.statusPending)
        case .partial:
            return ("clock.badge.checkmark.fill", "Partial", SemanticColors.statusPending)
        case .overdue:
            return ("exclamationmark.triangle.fill", "Overdue", SemanticColors.statusWarning)
        case .cancelled:
            return ("xmark.circle.fill", "Cancelled", SemanticColors.textTertiary)
        case .refunded:
            return ("arrow.counterclockwise.circle.fill", "Refunded", SemanticColors.statusInfo)
        }
    }
}

// MARK: - Preview

#Preview("Link Expenses Modal V2") {
    let item = BudgetOverviewItem(
        id: UUID().uuidString,
        itemName: "Photography Package",
        category: "Photography",
        subcategory: "Professional Photos",
        budgeted: 4500,
        spent: 1500,
        effectiveSpent: 1500,
        expenses: [],
        gifts: []
    )

    return LinkExpensesModalV2(
        budgetItem: item,
        categoryName: "Photography",
        categoryColor: Color.fromHex("#a855f7"),
        onComplete: {},
        onCancel: { print("Cancel pressed - would reopen detail modal") }
    )
    .environmentObject(BudgetStoreV2())
}
