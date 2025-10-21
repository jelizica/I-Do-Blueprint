//
//  MoneyOwedCharts.swift
//  I Do Blueprint
//
//  Chart components for money owed view
//

import Charts
import SwiftUI

// MARK: - Money Owed Charts Section

struct MoneyOwedChartsSection: View {
    let priorityData: [PriorityData]
    let upcomingDueDates: [DueDateData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Owed by Priority")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(priorityData, id: \.priority) { data in
                    BarMark(
                        x: .value("Priority", data.priority.rawValue),
                        y: .value("Amount", data.amount))
                        .foregroundStyle(data.color)
                        .cornerRadius(4)
                }
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(amount, specifier: "%.0f")")
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Timeline chart for due dates
            if !upcomingDueDates.isEmpty {
                Text("Upcoming Due Dates")
                    .font(.headline)
                    .padding(.horizontal)

                Chart {
                    ForEach(upcomingDueDates, id: \.date) { data in
                        PointMark(
                        x: .value("Date", data.date),
                        y: .value("Amount", data.amount))
                        .foregroundStyle(data.isOverdue ? AppColors.Budget.overBudget : AppColors.Budget.pending)
                        .symbolSize(data.amount * 0.5)
                    }
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
