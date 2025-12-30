//
//  SeatingChartView.swift
//  My Wedding Planning App
//
//  Seating chart designer view
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
            headerView

            Divider()

            // Main content
            if visualPlanningStore.seatingCharts.isEmpty {
                SeatingChartEmptyState(onCreateChart: { showingChartCreator = true })
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

    // MARK: - Header View

    private var headerView: some View {
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

// MARK: - Supporting Views (Deprecated - kept for compatibility)

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

// MARK: - Detail Views (Deprecated - kept for compatibility)

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
