//
//  TimelineViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/8/25.
//

import SwiftUI

struct TimelineViewV2: View {
    @EnvironmentObject private var store: TimelineStoreV2
    @State private var showingItemModal = false
    @State private var showingMilestoneModal = false
    @State private var selectedItem: TimelineItem?
    @State private var selectedMilestone: Milestone?
    @State private var showingFilters = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedDate: Date = Date()

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading, store.timelineItems.isEmpty {
                    loadingView
                        .onAppear {
                                                    }
                } else {
                    contentView
                        .onAppear {
                                                    }
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

    // MARK: - Loading View - Using Component Library

    private var loadingView: some View {
        LoadingView(message: "Loading timeline...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showingFilters.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }

            Button(action: { Task { await store.refreshTimeline() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(store.isLoading)

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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    // Header section
                    headerSection

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
                    detailsSection
                }
                .padding()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registration Period")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.secondary.opacity(0.3))

                    Text("Wedding Timeline")
                        .font(.system(size: 24, weight: .semibold))
                }

                Spacer()

                // Stats
                HStack(spacing: 24) {
                    statBadge(
                        title: "Total Events",
                        value: "\(store.filteredItems.count)",
                        icon: "calendar"
                    )
                    .onAppear {
                                            }

                    statBadge(
                        title: "Milestones",
                        value: "\(store.milestones.count)",
                        icon: "star.fill"
                    )

                    statBadge(
                        title: "Completed",
                        value: "\(store.completedItemsCount())",
                        icon: "checkmark.circle.fill"
                    )
                }
            }
        }
        .padding(Spacing.xxl)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }

    // Note: statBadge could be replaced with CompactSummaryCard from component library
    // Keeping as-is for now since it's a simple inline component
    private func statBadge(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(Spacing.md)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Details")
                .font(.title2)
                .fontWeight(.bold)

            // Group events by type
            ForEach(TimelineItemType.allCases, id: \.self) { type in
                if let items = itemsByType(type), !items.isEmpty {
                    EventTypeSection(type: type, items: items) { item in
                        selectedItem = item
                        showingItemModal = true
                    }
                }
            }
        }
        .padding(Spacing.xxl)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }

    private func itemsByType(_ type: TimelineItemType) -> [TimelineItem]? {
        let items = store.filteredItems.filter { $0.itemType == type }
        return items.isEmpty ? nil : items
    }
}

// MARK: - Horizontal Timeline Graph

struct HorizontalTimelineGraph: View {
    let items: [TimelineItem]
    let milestones: [Milestone]
    let onSelectItem: (TimelineItem) -> Void
    let onSelectMilestone: (Milestone) -> Void

    @State private var scrollPosition: CGFloat = 0
    @State private var hoveredId: UUID?

    private var allDates: [Date] {
        let itemDates = items.map { $0.itemDate }
        let milestoneDates = milestones.map { $0.milestoneDate }
        return (itemDates + milestoneDates).sorted()
    }

    private var dateRange: (start: Date, end: Date) {
        guard let first = allDates.first, let last = allDates.last else {
            let now = Date()
            return (now, Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now)
        }

        // Add padding
        let start = Calendar.current.date(byAdding: .month, value: -1, to: first) ?? first
        let end = Calendar.current.date(byAdding: .month, value: 1, to: last) ?? last
        return (start, end)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)

                ZStack(alignment: .top) {
                    // Timeline axis
                    timelineAxis
                        .padding(.top, Spacing.huge)
                        .padding(.horizontal, Spacing.huge)
                        .offset(y: 0)

                    // Event tracks - positioned to connect to the timeline
                    eventTracks
                        .padding(.horizontal, Spacing.huge)
                        .offset(y: 60)
                }
            }
            .frame(width: max(1200, CGFloat(allDates.count) * 120), height: 400)
        }
    }

    // MARK: - Timeline Axis

    private var timelineAxis: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let range = dateRange
            let totalDays = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 1

            ZStack(alignment: .top) {
                // Main timeline line
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 2)
                    .offset(y: 20)

                // Month markers
                ForEach(Array(monthMarkers().enumerated()), id: \.offset) { index, monthData in
                    let position = positionForDate(monthData.date, in: range, width: width, totalDays: totalDays)

                    VStack(spacing: 4) {
                        // Marker dot
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color(NSColor.controlBackgroundColor), lineWidth: 2)
                            )

                        // Month label
                        Text(monthData.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 100)
                    }
                    .position(x: position, y: 20)
                }
            }
        }
        .frame(height: 80)
    }

    private func monthMarkers() -> [(date: Date, label: String)] {
        let range = dateRange
        var markers: [(date: Date, label: String)] = []

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        var currentDate = calendar.date(from: calendar.dateComponents([.year, .month], from: range.start))!

        while currentDate <= range.end {
            markers.append((date: currentDate, label: formatter.string(from: currentDate)))
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }

        return markers
    }

    // MARK: - Event Tracks

    private var eventTracks: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let range = dateRange
            let totalDays = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 1

            ZStack(alignment: .topLeading) {
                // All events positioned on the timeline with connecting lines
                ForEach(items) { item in
                    let position = positionForDate(item.itemDate, in: range, width: width, totalDays: totalDays)

                    VStack(spacing: 0) {
                        // Connecting line from timeline to event
                        Rectangle()
                            .fill(Color(hex: item.itemType.color)?.opacity(0.3) ?? Color.blue.opacity(0.3))
                            .frame(width: 2, height: 50)

                        // Event node
                        EventNode(item: item, isHovered: hoveredId == item.id)
                            .offset(y: -12) // Offset to center the circle on the line
                    }
                    .offset(x: position, y: 0)
                    .onTapGesture {
                        onSelectItem(item)
                    }
                    .onHover { isHovered in
                        hoveredId = isHovered ? item.id : nil
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func positionForDate(_ date: Date, in range: (start: Date, end: Date), width: CGFloat, totalDays: Int) -> CGFloat {
        let daysFromStart = Calendar.current.dateComponents([.day], from: range.start, to: date).day ?? 0
        let percentage = CGFloat(daysFromStart) / CGFloat(totalDays)
        return width * percentage
    }

    private func isMilestone(_ date: Date) -> Bool {
        milestones.contains { Calendar.current.isDate($0.milestoneDate, inSameDayAs: date) }
    }

    private func milestoneForDate(_ date: Date) -> Milestone? {
        milestones.first { Calendar.current.isDate($0.milestoneDate, inSameDayAs: date) }
    }
}

// MARK: - Event Node

struct EventNode: View {
    let item: TimelineItem
    let isHovered: Bool

    var body: some View {
        // Icon - always in the same position
        Circle()
            .fill(Color(hex: item.itemType.color) ?? .blue)
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: item.itemType.iconName)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textPrimary)
            )
            .overlay(
                Circle()
                    .stroke(Color(NSColor.controlBackgroundColor), lineWidth: 2)
            )
            .overlay(
                item.completed ?
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.2))
                    )
                : nil
            )
            .overlay(alignment: .top) {
                // Hover tooltip - displayed below the icon as an overlay
                if isHovered {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: item.itemType.iconName)
                                .font(.caption2)
                                .foregroundColor(Color(hex: item.itemType.color))

                            Text(item.itemType.displayName)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }

                        Text(item.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(2)

                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(item.itemDate, style: .date)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)

                        if let description = item.description, !description.isEmpty {
                            Text(description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }

                        if item.completed {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Completed")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .frame(width: 220)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .offset(y: 32)
                }
            }
    }
}

// MARK: - Event Type Section

struct EventTypeSection: View {
    let type: TimelineItemType
    let items: [TimelineItem]
    let onSelect: (TimelineItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: type.color) ?? .blue)
                    .frame(width: 12, height: 12)

                Text(type.displayName)
                    .font(.headline)

                Spacer()

                Text("\(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        EventCard(item: item)
                            .onTapGesture {
                                onSelect(item)
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Event Card

struct EventCard: View {
    let item: TimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.itemType.iconName)
                    .foregroundColor(Color(hex: item.itemType.color))

                Spacer()

                if item.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            Text(item.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            Text(item.itemDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .frame(width: 180)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    TimelineViewV2()
        .frame(width: 1400, height: 900)
}
