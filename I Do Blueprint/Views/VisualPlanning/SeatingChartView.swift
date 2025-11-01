//
//  SeatingChartView.swift
//  My Wedding Planning App
//
//  Seating chart designer view (placeholder)
//

import SwiftUI

struct SeatingChartView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @State private var showingChartCreator = false
    @State private var selectedChart: SeatingChart?
    @State private var showingChartEditor = false
    @AppStorage("useSeatingChartV2") private var useV2 = true  // V2 enabled by default
    private let logger = AppLogger.ui

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "tablecells")
                        .font(.system(size: 32))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seating Chart Designer")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Plan your reception seating arrangements")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // V2 Toggle
                    Toggle(isOn: $useV2) {
                        HStack(spacing: 4) {
                            Text(useV2 ? "V2" : "V1")
                                .font(.caption.bold())
                            Image(systemName: "sparkles")
                                .font(.caption2)
                        }
                    }
                    .toggleStyle(.button)
                    .tint(useV2 ? .seatingAccentTeal : .gray)
                    .help(useV2 ? "Using V2 editor with illustrated avatars" : "Switch to V2 editor")

                    Button("New Chart") {
                        showingChartCreator = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !visualPlanningStore.seatingCharts.isEmpty {
                    // Chart statistics
                    SeatingChartsStatsView(charts: visualPlanningStore.seatingCharts)
                }
            }
            .padding()

            Divider()

            // Main content
            if visualPlanningStore.seatingCharts.isEmpty {
                emptyStateView
            } else {
                seatingChartsListView
            }
        }
        .sheet(isPresented: $showingChartCreator) {
            SeatingChartCreatorView()
                .environmentObject(visualPlanningStore)
        }
        .sheet(item: $selectedChart) { chart in
            if useV2 {
                SeatingChartEditorViewV2(seatingChart: chart)
                    .environmentObject(visualPlanningStore)
            } else {
                SeatingChartEditorView(seatingChart: chart)
                    .environmentObject(visualPlanningStore)
            }
        }
        .onChange(of: selectedChart) { oldValue, newValue in
            // When editor is dismissed (selectedChart becomes nil), reload charts from database
            if oldValue != nil && newValue == nil {
                                Task {
                    do {
                        try await visualPlanningStore.loadSeatingCharts()
                        logger.info("Charts reloaded successfully")
                    } catch {
                        logger.error("Error reloading charts", error: error)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
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
                    showingChartCreator = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.sm)
            }

            VStack(spacing: 12) {
                Text("What you can do:")
                    .font(.headline)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(
                        icon: "rectangle.3.group",
                        title: "Interactive Table Layout",
                        description: "Drag and arrange tables in your venue")

                    FeatureRow(
                        icon: "person.2",
                        title: "Guest Assignment",
                        description: "Assign guests to tables with smart suggestions")

                    FeatureRow(
                        icon: "chart.pie",
                        title: "Seating Analytics",
                        description: "Track assignments and optimize seating")

                    FeatureRow(
                        icon: "square.and.arrow.up",
                        title: "Export & Share",
                        description: "Print charts or share with vendors")
                }
            }
            .padding(.horizontal, Spacing.huge)

            Spacer()
        }
    }

    // MARK: - Charts List

    private var seatingChartsListView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300), spacing: 16)
            ], spacing: 16) {
                ForEach(visualPlanningStore.seatingCharts) { chart in
                    SeatingChartCard(chart: chart) {
                        selectedChart = chart
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

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

// MARK: - Interactive Seating Stat Card

struct InteractiveSeatingStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    Spacer()
                }

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: .black.opacity(isHovering ? 0.12 : 0.06),
                        radius: isHovering ? 8 : 3,
                        x: 0,
                        y: isHovering ? 4 : 2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isHovering ? 0.4 : 0.3), lineWidth: 1))
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct SeatingStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

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
                            .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 4)
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
                                .fill(AppColors.textSecondary.opacity(0.15))
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

// MARK: - Enhanced Stat Pill

struct EnhancedStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08)))
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(AppColors.textSecondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MoodBoardCreatorView is now implemented in MoodBoardGeneratorView.swift

// ColorPaletteCreatorView is now implemented in ColorPaletteCreatorView.swift

struct MoodBoardDetailView: View {
    let moodBoard: MoodBoard
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2

    var body: some View {
        MoodBoardEditorView(moodBoard: moodBoard)
            .environmentObject(visualPlanningStore)
    }
}

struct ColorPaletteDetailView: View {
    let palette: ColorPalette
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(palette.name)
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                ForEach(palette.colors.prefix(4), id: \.self) { hexColor in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.fromHexString(hexColor) ?? .gray)
                        .frame(width: 80, height: 80)
                }
            }

            Text("Color palette detail view coming soon!")
                .foregroundColor(.secondary)

            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SeatingChartView()
}
