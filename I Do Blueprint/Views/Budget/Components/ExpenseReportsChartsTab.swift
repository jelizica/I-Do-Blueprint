import Charts
import SwiftUI

/// Charts tab for expense reports showing vendor and payment status charts
struct ExpenseReportsChartsTab: View {
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
                // Top Vendors Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Vendors by Spending")
                        .font(.headline)

                    Chart(statistics.vendorData.prefix(10), id: \.name) { data in
                        BarMark(
                            x: .value("Amount", data.amount),
                            y: .value("Vendor", data.name))
                            .foregroundStyle(.orange)
                    }
                    .frame(height: 300)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Payment Status Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Status Distribution")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(PaymentStatus.allCases, id: \.self) { status in
                            let count = statistics.statusCounts.count(for: status)
                            let percentage = statistics.transactionCount > 0 ?
                                Double(count) / Double(statistics.transactionCount) * 100 : 0

                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.blue)

                                Text(status.displayName)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                ProgressView(value: percentage / 100)
                                    .frame(width: 60)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
