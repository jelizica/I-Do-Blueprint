//
//  BudgetOverviewCardV4.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Budget overview card showing payments, expenses, and upcoming payments
//

import SwiftUI

struct BudgetOverviewCardV4: View {
    @ObservedObject var store: BudgetStoreV2
    @ObservedObject var vendorStore: VendorStoreV2
    let userTimezone: TimeZone

    private var totalBudget: Double {
        guard let primaryScenario = store.primaryScenario else {
            return 0
        }
        return primaryScenario.totalWithTax
    }

    private var totalPaid: Double {
        return store.payments.totalPaid
    }

    private var totalExpenses: Double {
        guard case .loaded(let budgetData) = store.loadingState else {
            return 0
        }
        return budgetData.expenses.reduce(0) { $0 + $1.amount }
    }

    private var remainingBudget: Double {
        return totalBudget - totalPaid
    }

    private var paymentsThisMonth: [PaymentSchedule] {
        // Use injected timezone to determine "this month"
        var calendar = Calendar.current
        calendar.timeZone = userTimezone
        
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return store.payments.paymentSchedules.filter { payment in
            payment.paymentDate >= startOfMonth && payment.paymentDate <= endOfMonth
        }.sorted { $0.paymentDate < $1.paymentDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Budget Overview")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)

                if let scenario = store.primaryScenario {
                    Text("$\(formatAmount(totalPaid)) of $\(formatAmount(scenario.totalWithTax)) paid")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("No primary scenario")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)

            Divider()

            // Payment vs Expense Breakdown
            VStack(spacing: Spacing.md) {
                // Payments Progress
                BudgetProgressRow(
                    label: "Payments",
                    amount: totalPaid,
                    total: totalBudget,
                    color: AppColors.Budget.allocated
                )

                // Expenses Progress
                BudgetProgressRow(
                    label: "Expenses",
                    amount: totalExpenses,
                    total: totalBudget,
                    color: AppColors.warning
                )

                // Remaining Budget (moved here)
                HStack {
                    Text("Remaining Budget")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Text("$\(formatAmount(remainingBudget))")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundColor(AppColors.success)
                }
                .padding(.top, Spacing.xs)

                // Payments Due This Month
                if !paymentsThisMonth.isEmpty {
                    Divider()
                        .padding(.vertical, Spacing.sm)

                    Text("Payments Due This Month")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)

                    ForEach(paymentsThisMonth.prefix(5)) { payment in
                        PaymentDueRow(payment: payment, vendorStore: vendorStore, userTimezone: userTimezone)
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 430)
        .background(AppColors.cardBackground)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}
