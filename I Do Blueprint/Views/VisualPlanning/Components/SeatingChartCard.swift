//
//  SeatingChartCard.swift
//  I Do Blueprint
//
//  Card component for displaying seating chart summary
//

import SwiftUI

struct SeatingChartCard: View {
    let chart: SeatingChart
    let onSelect: () -> Void
    @State private var isHovering = false

    private var assignmentProgress: Double {
        guard !chart.guests.isEmpty else { return 0 }
        return Double(chart.seatingAssignments.count) / Double(chart.guests.count)
    }

    private var progressColor: Color {
        if assignmentProgress < 0.5 { .red } else if assignmentProgress < 0.8 { .orange } else { .green }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Colored accent bar
            Rectangle()
                .fill(progressColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chart.chartName)
                            .font(.headline)
                            .fontWeight(.bold)

                        if let description = chart.chartDescription {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: onSelect) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text("Edit")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1)))
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }

                // Statistics
                HStack(spacing: 12) {
                    EnhancedStatPill(
                        icon: "person.2",
                        value: "\(chart.guests.count)",
                        label: "Guests",
                        color: .blue)

                    EnhancedStatPill(
                        icon: "tablecells",
                        value: "\(chart.tables.count)",
                        label: "Tables",
                        color: .green)

                    EnhancedStatPill(
                        icon: "checkmark.circle",
                        value: "\(chart.seatingAssignments.count)",
                        label: "Assigned",
                        color: .purple)
                }

                // Progress
                HStack(spacing: 16) {
                    // Circular progress indicator
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 4)
                            .frame(width: 50, height: 50)

                        // Progress circle
                        Circle()
                            .trim(from: 0, to: assignmentProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [progressColor, progressColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))

                        // Percentage text
                        Text("\(Int(assignmentProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(progressColor)
                    }

                    // Linear progress bar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assignment Progress")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SemanticColors.textSecondary.opacity(Opacity.light))
                                .frame(height: 8)

                            // Progress bar with gradient
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [progressColor, progressColor.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing))
                                .frame(width: max(0, assignmentProgress * 200), height: 8)
                        }
                    }
                }

                // Last updated
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(
                        "Updated \(RelativeDateTimeFormatter().localizedString(for: chart.updatedAt, relativeTo: Date()))")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.12 : 0.06),
                    radius: isHovering ? 8 : 4,
                    x: 0,
                    y: isHovering ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.textSecondary.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(progressColor.opacity(0.2), lineWidth: isHovering ? 2 : 0))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
