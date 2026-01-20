//
//  ExpenseCardView.swift
//  I Do Blueprint
//
//  Glassmorphism expense card matching GuestCardV2 styling exactly
//

import SwiftUI

/// Card view for displaying an expense in grid mode
/// Follows GuestCardV2 structure and styling exactly
struct ExpenseCardView: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var budgetStore: BudgetStoreV2

    // State for linked bills
    @State private var linkedBills: [BillCalculator] = []
    @State private var hasLoadedLinkedBills = false

    private var category: BudgetCategory? {
        budgetStore.categoryStore.categories.first { $0.id == expense.budgetCategoryId }
    }

    /// Category color for the icon badge
    private var categoryColor: Color {
        if let category = category {
            return Color(hex: category.color) ?? AppColors.Budget.allocated
        }
        return AppColors.Budget.allocated
    }

    /// Status color based on payment status
    private var statusColor: Color {
        switch expense.paymentStatus {
        case .paid: return SemanticColors.success
        case .pending: return SemanticColors.warning
        case .partial: return Color.yellow
        case .overdue: return SemanticColors.error
        case .cancelled: return SemanticColors.textTertiary
        case .refunded: return SemanticColors.primaryAction
        }
    }

    /// Display amount: linked bills total if present, otherwise expense amount
    private var displayAmount: Double {
        if !linkedBills.isEmpty {
            return linkedBills.reduce(0) { $0 + $1.grandTotal }
        }
        return expense.amount
    }

    /// Whether amount is from linked bills
    private var hasLinkedBillsAmount: Bool {
        !linkedBills.isEmpty
    }

    var body: some View {
        Button(action: onEdit) {
            // Match GuestCardV2 structure exactly: VStack with Spacing.md
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header: Icon Badge + Status Badge (matches Avatar + Status in GuestCardV2)
                HStack(alignment: .top) {
                    categoryIconBadge

                    Spacer()

                    // Status Badge + Menu
                    HStack(spacing: Spacing.sm) {
                        statusBadge
                        menuButton
                    }
                }

                // Expense Info (matches Guest Info section)
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.expenseName)
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)

                    // Category with color dot (like email in guest card)
                    if let category = category {
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(categoryColor)
                                .frame(width: 8, height: 8)
                            Text(category.categoryName)
                                .font(Typography.caption)
                                .foregroundColor(SemanticColors.textSecondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No category")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                            .lineLimit(1)
                    }

                    // Date (like "Invited by" in guest card)
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(expense.expenseDate, style: .date)
                    }
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
                }

                // Footer: Payment Method + Amount (matches Table + Meal Choice)
                Divider()
                    .background(Color.gray.opacity(0.2))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PAYMENT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(SemanticColors.textSecondary)

                        Text(paymentMethodDisplayName)
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: Spacing.xxs) {
                            if hasLinkedBillsAmount {
                                Image(systemName: "link")
                                    .font(.system(size: 8))
                                    .foregroundColor(AppColors.info)
                            }
                            Text(hasLinkedBillsAmount ? "BILL TOTAL" : "AMOUNT")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(hasLinkedBillsAmount ? AppColors.info : SemanticColors.textSecondary)
                        }

                        Text(formatCurrency(displayAmount))
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                }
            }
            .padding(Spacing.lg)
            .frame(height: 200)
            .modifier(GlassPanelStyle(cornerRadius: 16, padding: 0))
        }
        .buttonStyle(.plain)
        .task {
            await loadLinkedBills()
        }
        .onChange(of: budgetStore.expenseStore.refreshTrigger) { _, _ in
            // Bill calculator amounts changed - refresh linked bills to show updated totals
            Task {
                hasLoadedLinkedBills = false  // Reset flag to allow re-fetch
                await loadLinkedBills()
            }
        }
    }

    // MARK: - Category Icon Badge (matches Avatar in GuestCardV2)

    private var categoryIconBadge: some View {
        Circle()
            .fill(categoryColor.opacity(0.15))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: categoryIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(categoryColor)
            )
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// Icon based on category name
    private var categoryIcon: String {
        guard let categoryName = category?.categoryName.lowercased() else {
            return "dollarsign.circle.fill"
        }

        if categoryName.contains("venue") || categoryName.contains("location") { return "building.columns.fill" }
        if categoryName.contains("cater") || categoryName.contains("food") || categoryName.contains("bar") { return "fork.knife" }
        if categoryName.contains("photo") { return "camera.fill" }
        if categoryName.contains("video") { return "video.fill" }
        if categoryName.contains("flor") || categoryName.contains("flower") || categoryName.contains("decor") { return "leaf.fill" }
        if categoryName.contains("music") || categoryName.contains("dj") || categoryName.contains("band") || categoryName.contains("entertainment") { return "music.note" }
        if categoryName.contains("dress") || categoryName.contains("attire") || categoryName.contains("suit") || categoryName.contains("groom") || categoryName.contains("bride") { return "tshirt.fill" }
        if categoryName.contains("cake") || categoryName.contains("baker") || categoryName.contains("dessert") { return "birthday.cake.fill" }
        if categoryName.contains("hair") || categoryName.contains("makeup") || categoryName.contains("beauty") { return "sparkles" }
        if categoryName.contains("plan") || categoryName.contains("coordinator") { return "list.clipboard.fill" }
        if categoryName.contains("transport") || categoryName.contains("limo") || categoryName.contains("car") { return "car.fill" }
        if categoryName.contains("invite") || categoryName.contains("stationery") || categoryName.contains("paper") { return "envelope.fill" }
        if categoryName.contains("favor") || categoryName.contains("gift") { return "gift.fill" }
        if categoryName.contains("ring") || categoryName.contains("jewel") { return "sparkle" }
        if categoryName.contains("offici") || categoryName.contains("ceremony") { return "heart.fill" }
        if categoryName.contains("honeymoon") || categoryName.contains("travel") { return "airplane" }
        if categoryName.contains("alter") { return "scissors" }

        return "creditcard.fill"
    }

    // MARK: - Status Badge (matches RSVP badge in GuestCardV2)

    private var statusBadge: some View {
        Text(expense.paymentStatus.displayName)
            .font(Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(statusColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(12)
    }

    // MARK: - Menu Button

    private var menuButton: some View {
        Menu {
            Button("Edit", action: onEdit)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var paymentMethodDisplayName: String {
        switch (expense.paymentMethod ?? "credit_card").lowercased() {
        case "credit_card": return "Credit"
        case "debit_card": return "Debit"
        case "cash": return "Cash"
        case "check": return "Check"
        case "bank_transfer": return "Transfer"
        case "venmo": return "Venmo"
        case "paypal": return "PayPal"
        default: return (expense.paymentMethod ?? "Card").capitalized
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func loadLinkedBills() async {
        // Only skip if we already successfully loaded bills with actual data
        guard !hasLoadedLinkedBills || linkedBills.isEmpty else { return }

        do {
            let links = try await budgetStore.repository.fetchBillCalculatorLinksForExpense(expenseId: expense.id)

            // Early exit if no links exist
            guard !links.isEmpty else {
                hasLoadedLinkedBills = true
                return
            }

            let billIds = Set(links.map { $0.billCalculatorId })

            // Ensure bill calculator store is loaded before filtering
            let billStore = AppStores.shared.billCalculator

            // Wait for bill store to be ready (either trigger load or wait for in-progress)
            // IMPORTANT: Always wait if loading is in progress, regardless of who started it
            var waitCount = 0
            while billStore.loadingState.isLoading && waitCount < 100 { // Max 5 seconds
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                waitCount += 1
            }

            // If still idle or has error after waiting, trigger load
            if billStore.loadingState.isIdle || billStore.loadingState.hasError {
                await billStore.loadCalculators()
            }

            // If load finished successfully, get the bills
            let filteredBills = billStore.calculators.filter { billIds.contains($0.id) }
            linkedBills = filteredBills

            // Only mark as loaded if we successfully got the bills we expected
            // or if the store has loaded data (meaning there really are no matching bills)
            if !filteredBills.isEmpty || billStore.loadingState.data != nil {
                hasLoadedLinkedBills = true
            }
        } catch {
            AppLogger.ui.debug("Failed to load linked bills for expense card: \(error)")
        }
    }
}
