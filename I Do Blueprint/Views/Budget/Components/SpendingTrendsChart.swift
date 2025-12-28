import Charts
import SwiftUI

/// Line chart showing spending trends over time
struct SpendingTrendsChart: View {
    let expenses: [Expense]
    let timeframe: AnalyticsTimeframe

    // Cache the computed monthly spending to avoid repeated timezone lookups and date formatting
    @State private var monthlySpending: [MonthlySpending] = []

    var body: some View {
        Group {
            if monthlySpending.isEmpty {
                ContentUnavailableView(
                    "No Spending Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Record payments to see spending trends"))
            } else {
                Chart(monthlySpending, id: \.month) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.amount))
                        .foregroundStyle(AppColors.Budget.allocated)
                        .symbol(.circle)

                    AreaMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.amount))
                        .foregroundStyle(AppColors.Budget.allocated.opacity(0.3))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            computeMonthlySpending()
        }
        .onChange(of: expenseSignature) { _ in
            computeMonthlySpending()
        }
        .onChange(of: timeframe) { _ in
            computeMonthlySpending()
        }
    }
    
    /// Computed signature that changes when any expense property relevant to the chart changes
    /// This includes: id, amount, approvedAt (used for grouping), and paidAmount (used for totals)
    private var expenseSignature: [ExpenseSignature] {
        expenses.map { expense in
            ExpenseSignature(
                id: expense.id,
                amount: expense.amount,
                approvedAt: expense.approvedAt,
                paidAmount: expense.paidAmount
            )
        }
    }
    
    /// Compute monthly spending data once and cache it
    /// This avoids repeated timezone lookups and date formatting on every render
    private func computeMonthlySpending() {
        // Use user's timezone for month grouping (computed once)
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        
        let groupedExpenses = Dictionary(grouping: expenses) { expense in
            guard let approvedAt = expense.approvedAt else { return "" }
            return DateFormatting.formatDate(approvedAt, format: "yyyy-MM", timezone: userTimezone)
        }

        monthlySpending = groupedExpenses.compactMap { key, expenses in
            guard !key.isEmpty else { return nil }
            let total = expenses.reduce(0) { $0 + $1.paidAmount }
            return MonthlySpending(month: key, amount: total)
        }.sorted { $0.month < $1.month }
    }
}

struct MonthlySpending {
    let month: String
    let amount: Double
}

/// Lightweight signature for detecting expense changes
/// Only includes properties that affect the spending trends chart
private struct ExpenseSignature: Equatable {
    let id: UUID
    let amount: Double
    let approvedAt: Date?
    let paidAmount: Double
}

