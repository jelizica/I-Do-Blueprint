//
//  TimelineView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @State private var showingItemModal = false
    @State private var showingMilestoneModal = false
    @State private var showingAllMilestones = false
    @State private var selectedItem: TimelineItem?
    @State private var selectedMilestone: Milestone?
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading, viewModel.timelineItems.isEmpty {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    toolbarButtons
                }
            }
            .sheet(isPresented: $showingItemModal) {
                TimelineItemModal(
                    item: selectedItem,
                    onSave: { data in
                        if let item = selectedItem {
                            await viewModel.updateTimelineItem(item.id, data: data)
                        } else {
                            await viewModel.createTimelineItem(data)
                        }
                        selectedItem = nil
                    },
                    onCancel: {
                        selectedItem = nil
                    })
            }
            .sheet(isPresented: $showingMilestoneModal) {
                MilestoneModal(
                    milestone: selectedMilestone,
                    onSave: { data in
                        if let milestone = selectedMilestone {
                            await viewModel.updateMilestone(milestone.id, data: data)
                        } else {
                            await viewModel.createMilestone(data)
                        }
                        selectedMilestone = nil
                    },
                    onCancel: {
                        selectedMilestone = nil
                    })
            }
            .sheet(isPresented: $showingFilters) {
                TimelineFiltersView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAllMilestones) {
                AllMilestonesView(
                    viewModel: viewModel,
                    onSelectMilestone: { milestone in
                        selectedMilestone = milestone
                        showingAllMilestones = false
                        showingMilestoneModal = true
                    })
            }
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading timeline...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            Picker("View Mode", selection: $viewModel.viewMode) {
                ForEach(TimelineViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Button(action: { showingFilters.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }

            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)

            Menu {
                Button("Add Timeline Item") {
                    selectedItem = nil
                    showingItemModal = true
                }

                Button("Add Milestone") {
                    selectedMilestone = nil
                    showingMilestoneModal = true
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Milestones Section
                if !viewModel.milestones.isEmpty {
                    milestonesSection
                }

                // Timeline Items Section
                if viewModel.viewMode == .grouped {
                    groupedTimelineView
                } else {
                    linearTimelineView
                }
            }
            .padding()
        }
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Milestones")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("View All") {
                    showingAllMilestones = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.upcomingMilestones()) { milestone in
                        MilestoneCard(
                            milestone: milestone,
                            onTap: {
                                selectedMilestone = milestone
                                showingMilestoneModal = true
                            },
                            onToggleCompletion: {
                                Task {
                                    await viewModel.toggleMilestoneCompletion(milestone)
                                }
                            })
                            .frame(width: 280)
                    }
                }
            }
        }
    }

    // MARK: - Grouped Timeline View

    private var groupedTimelineView: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(viewModel.sortedMonthKeys(), id: \.self) { monthKey in
                VStack(alignment: .leading, spacing: 12) {
                    // Month Header
                    Text(monthKey)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)

                    // Items for this month
                    if let items = viewModel.groupedItemsByMonth()[monthKey] {
                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                TimelineItemRow(
                                    item: item,
                                    onTap: {
                                        selectedItem = item
                                        showingItemModal = true
                                    },
                                    onToggleCompletion: {
                                        Task {
                                            await viewModel.toggleItemCompletion(item)
                                        }
                                    })
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Linear Timeline View

    private var linearTimelineView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Events")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 12)

            VStack(spacing: 8) {
                ForEach(viewModel.filteredItems) { item in
                    TimelineItemRow(
                        item: item,
                        onTap: {
                            selectedItem = item
                            showingItemModal = true
                        },
                        onToggleCompletion: {
                            Task {
                                await viewModel.toggleItemCompletion(item)
                            }
                        })
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .frame(width: 1200, height: 800)
}
