//
//  SeatingChartEmptyState.swift
//  I Do Blueprint
//
//  Empty state view for seating charts
//

import SwiftUI

struct SeatingChartEmptyState: View {
    let onCreateChart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "tablecells")
                    .font(.system(size: 64))
                    .foregroundColor(.green.opacity(0.6))

                VStack(spacing: 8) {
                    Text("No Seating Charts Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Create your first seating chart to start planning your reception layout")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.huge)
                }

                Button("Create Your First Seating Chart") {
                    onCreateChart()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.sm)
            }

            VStack(spacing: 12) {
                Text("What you can do:")
                    .font(.headline)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 8) {
                    SeatingChartFeatureRow(
                        icon: "rectangle.3.group",
                        title: "Interactive Table Layout",
                        description: "Drag and arrange tables in your venue")

                    SeatingChartFeatureRow(
                        icon: "person.2",
                        title: "Guest Assignment",
                        description: "Assign guests to tables with smart suggestions")

                    SeatingChartFeatureRow(
                        icon: "chart.pie",
                        title: "Seating Analytics",
                        description: "Track assignments and optimize seating")

                    SeatingChartFeatureRow(
                        icon: "square.and.arrow.up",
                        title: "Export & Share",
                        description: "Print charts or share with vendors")
                }
            }
            .padding(.horizontal, Spacing.huge)

            Spacer()
        }
    }
}
