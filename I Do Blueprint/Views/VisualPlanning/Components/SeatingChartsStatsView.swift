//
//  SeatingChartsStatsView.swift
//  I Do Blueprint
//
//  Displays statistics for seating charts
//

import SwiftUI

struct SeatingChartsStatsView: View {
    let charts: [SeatingChart]

    private var totalGuests: Int {
        charts.reduce(0) { $0 + $1.guests.count }
    }

    private var totalTables: Int {
        charts.reduce(0) { $0 + $1.tables.count }
    }

    private var averageAssignment: Double {
        let assignments = charts.map { chart in
            guard !chart.guests.isEmpty else { return 0.0 }
            return Double(chart.seatingAssignments.count) / Double(chart.guests.count)
        }
        return assignments.isEmpty ? 0 : assignments.reduce(0, +) / Double(assignments.count)
    }

    var body: some View {
        HStack(spacing: 12) {
            InteractiveSeatingStatCard(
                title: "Charts",
                value: "\(charts.count)",
                color: .green,
                icon: "tablecells") {
                // Navigation action can be added here
            }

            InteractiveSeatingStatCard(
                title: "Total Guests",
                value: "\(totalGuests)",
                color: .blue,
                icon: "person.3") {
                // Navigation action can be added here
            }

            InteractiveSeatingStatCard(
                title: "Total Tables",
                value: "\(totalTables)",
                color: .orange,
                icon: "rectangle.3.group") {
                // Navigation action can be added here
            }

            InteractiveSeatingStatCard(
                title: "Avg. Assigned",
                value: "\(Int(averageAssignment * 100))%",
                color: .purple,
                icon: "chart.pie") {
                // Navigation action can be added here
            }
        }
    }
}
