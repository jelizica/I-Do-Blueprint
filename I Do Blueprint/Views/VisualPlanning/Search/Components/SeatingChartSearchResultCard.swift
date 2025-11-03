//
//  SeatingChartSearchResultCard.swift
//  I Do Blueprint
//
//  Search result card for seating charts
//

import SwiftUI

struct SeatingChartSearchResultCard: View {
    private let logger = AppLogger.ui
    let chart: SeatingChart
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Chart preview
                chartPreview
                    .frame(height: 160)
                    .clipped()

                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(chart.chartName)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    // Description
                    if let description = chart.chartDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // Stats row
                    HStack(spacing: 16) {
                        // Tables
                        statItem(icon: "tablecells", value: "\(chart.tables.count)", label: "Tables")

                        // Guests
                        statItem(icon: "person.2", value: "\(chart.guests.count)", label: "Guests")

                        // Assignments
                        statItem(icon: "checkmark.circle", value: "\(chart.seatingAssignments.count)", label: "Assigned")
                    }

                    // Status badges
                    HStack(spacing: 8) {
                        // Venue layout type
                        HStack(spacing: 4) {
                            Image(systemName: venueLayoutIcon)
                                .font(.caption2)
                            Text(chart.venueLayoutType.rawValue.capitalized)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)

                        Spacer()

                        // Finalized badge
                        if chart.isFinalized {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                Text("Finalized")
                                    .font(.caption2)
                            }
                            .foregroundColor(.green)
                        }

                        // Active badge
                        if chart.isActive {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                Text("Active")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                        }
                    }

                    // Progress bar
                    if !chart.guests.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Assignment Progress")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("\(assignmentPercentage)%")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(AppColors.textSecondary.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * CGFloat(assignmentPercentage) / 100.0)
                                }
                            }
                            .frame(height: 4)
                        }
                    }

                    // Date
                    Text(chart.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppColors.textPrimary.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 8 : 4, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Chart Preview

    private var chartPreview: some View {
        ZStack {
            // Background
            Color(NSColor.controlBackgroundColor).opacity(0.5)

            // Simplified table layout visualization
            if !chart.tables.isEmpty {
                GeometryReader { geometry in
                    ForEach(Array(chart.tables.prefix(12).enumerated()), id: \.element.id) { index, table in
                        tablePreview(table, index: index, total: min(chart.tables.count, 12), in: geometry.size)
                    }

                    // Show count if more tables
                    if chart.tables.count > 12 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("+\(chart.tables.count - 12) more")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(AppColors.textPrimary.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding(Spacing.sm)
                            }
                        }
                    }
                }
            } else {
                emptyChartView
            }
        }
    }

    private func tablePreview(_ table: Table, index: Int, total: Int, in size: CGSize) -> some View {
        let columns = min(4, Int(ceil(sqrt(Double(total)))))
        let rows = Int(ceil(Double(total) / Double(columns)))

        let col = index % columns
        let row = index / columns

        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(rows)

        let x = CGFloat(col) * cellWidth + cellWidth / 2
        let y = CGFloat(row) * cellHeight + cellHeight / 2

        let tableSize: CGFloat = min(cellWidth, cellHeight) * 0.6

        return ZStack {
            // Table shape
            Circle()
                .fill(table.isFull ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                .frame(width: tableSize, height: tableSize)

            Circle()
                .stroke(table.isFull ? Color.green : Color.blue, lineWidth: 2)
                .frame(width: tableSize, height: tableSize)

            // Table number
            Text("\(table.tableNumber)")
                .font(.system(size: tableSize * 0.3, weight: .bold))
                .foregroundColor(table.isFull ? .green : .blue)
        }
        .position(x: x, y: y)
    }

    private var emptyChartView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tablecells")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Tables")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Views

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Computed Properties

    private var assignmentPercentage: Int {
        guard !chart.guests.isEmpty else { return 0 }
        return Int((Double(chart.seatingAssignments.count) / Double(chart.guests.count)) * 100)
    }

    private var venueLayoutIcon: String {
        switch chart.venueLayoutType {
        case .round: return "circle"
        case .rectangular: return "rectangle"
        case .uShape: return "u.square"
        case .theater: return "rectangle.grid.3x2"
        case .cocktail: return "circle.grid.cross"
        case .garden: return "leaf"
        }
    }
}

#Preview {
    let sampleChart = SeatingChart(
        tenantId: "sample-tenant",
        chartName: "Reception Seating",
        chartDescription: "Main reception hall seating arrangement",
        isFinalized: false
    )

    SeatingChartSearchResultCard(chart: sampleChart) {
        // TODO: Implement action - print("Selected chart")
    }
    .frame(width: 280, height: 380)
    .padding()
}
