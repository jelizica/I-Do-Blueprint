//
//  ModernSidebarView.swift
//  My Wedding Planning App
//
//  Enhanced sidebar with guest groups and modern design
//

import SwiftUI

struct ModernSidebarView: View {
    @Binding var chart: SeatingChart
    @Binding var selectedTab: EditorTab
    @Binding var selectedTableId: UUID?

    @State private var searchText = ""
    @State private var showingGroupEditor = false
    @State private var guestGroups: [SeatingGuestGroup] = SeatingGuestGroup.defaultGroups

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchSection

            Divider()

            // Tab selection
            tabSelectionSection

            Divider()

            // Tab content
            ScrollView {
                switch selectedTab {
                case .layout:
                    SidebarLayoutContent(chart: $chart)

                case .tables:
                    SidebarTablesContent(
                        chart: $chart,
                        selectedTableId: $selectedTableId,
                        searchText: searchText
                    )

                case .guests:
                    SidebarGuestsContent(
                        chart: $chart,
                        guestGroups: $guestGroups,
                        showingGroupEditor: $showingGroupEditor,
                        searchText: searchText
                    )

                case .assignments:
                    SidebarAssignmentsContent(chart: $chart)

                case .analytics:
                    SidebarAnalyticsContent(chart: chart)
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 360)
        .background(Color.seatingCream.opacity(0.3))
        .sheet(isPresented: $showingGroupEditor) {
            GuestGroupEditorSheet(groups: $guestGroups)
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.seatingBody)
        }
        .padding(Spacing.md)
        .background(AppColors.textPrimary)
    }

    // MARK: - Tab Selection

    private var tabSelectionSection: some View {
        VStack(spacing: 8) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                ModernTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    count: getTabCount(for: tab)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(Spacing.md)
    }

    private func getTabCount(for tab: EditorTab) -> Int? {
        switch tab {
        case .layout: return nil
        case .tables: return chart.tables.count
        case .guests: return chart.guests.count
        case .assignments: return chart.seatingAssignments.count
        case .analytics: return nil
        }
    }
}

#Preview {
    let sampleChart = SeatingChart(
        tenantId: "sample",
        chartName: "Wedding Reception",
        eventId: nil
    )

    ModernSidebarView(
        chart: .constant(sampleChart),
        selectedTab: .constant(.guests),
        selectedTableId: .constant(nil)
    )
}
