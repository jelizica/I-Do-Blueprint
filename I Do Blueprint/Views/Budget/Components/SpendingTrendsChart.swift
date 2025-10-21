import Charts
import SwiftUI

/// Line chart showing spending trends over time
struct SpendingTrendsChart: View {
    let expenses: [Expense]
    let timeframe: AnalyticsTimeframe
    
    private var monthlySpending: [MonthlySpending] {
        let groupedExpenses = Dictionary(grouping: expenses) { expense in
            guard let approvedAt = expense.approvedAt else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: approvedAt)
        }
        
        return groupedExpenses.compactMap { key, expenses in
            guard !key.isEmpty else { return nil }
            let total = expenses.reduce(0) { $0 + $1.paidAmount }
            return MonthlySpending(month: key, amount: total)
        }.sorted { $0.month < $1.month }
    }
    
    var body: some View {
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
}

struct MonthlySpending {
    let month: String
    let amount: Double
}

