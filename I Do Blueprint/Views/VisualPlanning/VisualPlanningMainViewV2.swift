//
//  VisualPlanningMainViewV2.swift
//  I Do Blueprint
//
//  Refactored visual planning main view with extracted components
//  Reduced complexity and nesting by decomposing into focused subviews
//

import SwiftUI

struct VisualPlanningMainViewV2: View {
    @EnvironmentObject private var visualPlanningStore: VisualPlanningStoreV2
    @State private var selectedTab: VisualPlanningTab = .moodBoards
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with gradient and stats
                VisualPlanningHeader(
                    moodBoardCount: visualPlanningStore.moodBoards.count,
                    colorPaletteCount: visualPlanningStore.colorPalettes.count,
                    seatingChartCount: visualPlanningStore.seatingCharts.count,
                    onTabSelect: { tab in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                )
                
                // Tab navigation
                VisualPlanningTabBar(
                    selectedTab: $selectedTab,
                    getTabCount: getTabCount
                )
                
                Divider()
                
                // Main content
                tabContent
                    .environmentObject(visualPlanningStore)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .navigationTitle("")
        }
        .sheet(isPresented: $visualPlanningStore.showingMoodBoardCreator) {
            MoodBoardGeneratorView()
                .environmentObject(visualPlanningStore)
                .transition(.opacity.combined(with: .scale))
        }
        .sheet(isPresented: $visualPlanningStore.showingColorPaletteCreator) {
            ColorPaletteCreatorView()
                .environmentObject(visualPlanningStore)
                .transition(.opacity.combined(with: .scale))
        }
        .task {
            await loadAllData()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .moodBoards:
            MoodBoardListView()
        case .colorPalettes:
            ColorPaletteListView()
        case .stylePreferences:
            StylePreferencesView()
        case .seatingChart:
            SeatingChartView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTabCount(for tab: VisualPlanningTab) -> Int? {
        switch tab {
        case .moodBoards:
            visualPlanningStore.moodBoards.count
        case .colorPalettes:
            visualPlanningStore.colorPalettes.count
        case .seatingChart:
            visualPlanningStore.seatingCharts.count
        case .stylePreferences:
            nil
        }
    }
    
    private func loadAllData() async {
        await visualPlanningStore.loadMoodBoards()
        await visualPlanningStore.loadColorPalettes()
        await visualPlanningStore.loadSeatingCharts()
    }
}

// MARK: - Preview

#Preview {
    VisualPlanningMainViewV2()
        .frame(width: 1200, height: 800)
}
