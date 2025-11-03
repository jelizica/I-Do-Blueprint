import Charts
import SwiftUI

/// Overview tab for expense reports showing category and monthly charts
struct ExpenseReportsOverviewTab: View {
    @Binding var selectedTab: ReportTab
    let statistics: ExpenseStatistics

    var body: some View {
        VStack(spacing: 20) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                Text("Overview").tag(ReportTab.overview)
                Text("Charts").tag(ReportTab.charts)
                Text("Table").tag(ReportTab.table)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 16) {
                // Category Pie Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expenses by Category")
                        .font(.headline)

                    Chart(statistics.categoryData, id: \.name) { data in
                        SectorMark(
                            angle: .value("Amount", data.amount),
                            innerRadius: .ratio(0.4),
                            angularInset: 2)
                            .foregroundStyle(Color(hex: data.color) ?? AppColors.Budget.allocated)
                            .opacity(0.8)
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Monthly Trend
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Spending Trend")
                        .font(.headline)

                    Chart(statistics.monthlyData, id: \.month) { data in
                        LineMark(
                            x: .value("Month", data.month, unit: .month),
                            y: .value("Amount", data.amount))
                            .foregroundStyle(AppColors.Budget.allocated)
                            .symbol(.circle)

                        AreaMark(
                            x: .value("Month", data.month, unit: .month),
                            y: .value("Amount", data.amount))
                            .foregroundStyle(AppColors.Budget.allocated.opacity(0.3))
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
