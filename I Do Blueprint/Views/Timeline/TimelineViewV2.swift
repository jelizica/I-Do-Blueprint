//
//  TimelineViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/8/25.
//  Refactored: Decomposed into focused components to reduce complexity
//

import SwiftUI

struct TimelineViewV2: View {
    @EnvironmentObject private var store: TimelineStoreV2
    @State private var showingItemModal = false
    @State private var showingMilestoneModal = false
    @State private var selectedItem: TimelineItem?
    @State private var selectedMilestone: Milestone?
    @State private var showingFilters = false

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading, store.timelineItems.isEmpty {
                    LoadingView(message: "Loading timeline...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contentView
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    TimelineToolbar(
                        isLoading: store.isLoading,
                        onShowFilters: { showingFilters.toggle() },
                        onRefresh: { await store.refreshTimeline() },
                        onAddItem: {
                            selectedItem = nil
                            showingItemModal = true
                        },
                        onAddMilestone: {
                            selectedMilestone = nil
                            showingMilestoneModal = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showingItemModal) {
                TimelineItemModal(
                    item: selectedItem,
                    onSave: { data in
                        await handleItemSave(data)
                    },
                    onCancel: {
                        selectedItem = nil
                    })
            }
            .sheet(isPresented: $showingMilestoneModal) {
                MilestoneModal(
                    milestone: selectedMilestone,
                    onSave: { data in
                        await handleMilestoneSave(data)
                    },
                    onCancel: {
                        selectedMilestone = nil
                    })
            }
            .sheet(isPresented: $showingFilters) {
                TimelineFiltersView(store: store)
            }
            .task {
                await store.loadTimelineItems()
            }
            .onAppear {
                Task {
                    await store.refreshTimeline()
                }
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    // Header section
                    TimelineHeaderSection(
                        totalEvents: store.filteredItems.count,
                        milestonesCount: store.milestones.count,
                        completedCount: store.completedItemsCount()
                    )

                    // Horizontal Timeline Graph
                    HorizontalTimelineGraph(
                        items: store.filteredItems,
                        milestones: store.milestones,
                        onSelectItem: { item in
                            selectedItem = item
                            showingItemModal = true
                        },
                        onSelectMilestone: { milestone in
                            selectedMilestone = milestone
                            showingMilestoneModal = true
                        }
                    )
                    .frame(height: 400)

                    // Details section for selected period
                    TimelineDetailsSection(
                        items: store.filteredItems,
                        onSelectItem: { item in
                            selectedItem = item
                            showingItemModal = true
                        }
                    )
                }
                .padding()
            }
        }
    }

    // MARK: - Helper Methods

    private func handleItemSave(_ data: TimelineItemInsertData) async {
        if let item = selectedItem {
            var updatedItem = item
            updatedItem.title = data.title
            updatedItem.description = data.description
            updatedItem.itemType = data.itemType
            updatedItem.itemDate = data.itemDate
            updatedItem.endDate = data.endDate
            updatedItem.completed = data.completed
            updatedItem.relatedId = data.relatedId
            await store.updateTimelineItem(updatedItem)
        } else {
            await store.createTimelineItem(data)
        }
        selectedItem = nil
    }

    private func handleMilestoneSave(_ data: MilestoneInsertData) async {
        if let milestone = selectedMilestone {
            var updatedMilestone = milestone
            updatedMilestone.milestoneName = data.milestoneName
            updatedMilestone.description = data.description
            updatedMilestone.milestoneDate = data.milestoneDate
            updatedMilestone.color = data.color
            updatedMilestone.completed = data.completed
            await store.updateMilestone(updatedMilestone)
        } else {
            await store.createMilestone(data)
        }
        selectedMilestone = nil
    }
}

// MARK: - Preview

#Preview {
    TimelineViewV2()
        .frame(width: 1400, height: 900)
}
