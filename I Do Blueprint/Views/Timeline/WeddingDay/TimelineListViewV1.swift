//
//  TimelineListViewV1.swift
//  I Do Blueprint
//
//  Wedding Day Timeline - List View
//  Chronological expandable event list with category grouping and status indicators
//

import SwiftUI

struct TimelineListViewV1: View {
    @EnvironmentObject private var store: TimelineStoreV2

    // MARK: - State
    @State private var expandedCategories: Set<WeddingDayEventCategory> = Set(WeddingDayEventCategory.allCases)
    @State private var selectedEvent: WeddingDayEvent?
    @State private var showingEventDetail = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Summary header
                summaryHeader

                // Event list by category
                eventsByCategory
            }
            .padding()
        }
        .background(TimelineColors.auroraStart.opacity(0.3))
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                WeddingDayEventDetailSheet(event: event, onDismiss: {
                    selectedEvent = nil
                    showingEventDetail = false
                })
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: Spacing.lg) {
            // Total events card
            summaryCard(
                title: "Total Events",
                value: "\(store.weddingDayEvents.count)",
                icon: "calendar",
                color: TimelineColors.primary
            )

            // Key events card
            summaryCard(
                title: "Key Events",
                value: "\(store.keyWeddingDayEvents.count)",
                icon: "star.fill",
                color: TimelineColors.statusKeyEvent
            )

            // Pending card
            summaryCard(
                title: "Pending",
                value: "\(store.pendingWeddingDayEvents.count)",
                icon: "clock",
                color: TimelineColors.statusPending
            )

            // Duration card
            summaryCard(
                title: "Total Duration",
                value: formattedDuration(store.totalWeddingDayDuration),
                icon: "timer",
                color: TimelineColors.sage
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(value)
                .font(Typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Events By Category

    private var eventsByCategory: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(WeddingDayEventCategory.allCases, id: \.self) { category in
                let events = store.weddingDayEventsByCategory[category] ?? []

                if !events.isEmpty {
                    categorySection(category: category, events: events)
                }
            }
        }
    }

    private func categorySection(category: WeddingDayEventCategory, events: [WeddingDayEvent]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Category header (expandable)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    // Category icon
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(category.color)
                        .clipShape(Circle())

                    // Category name
                    Text(category.displayName)
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)

                    // Event count badge
                    Text("\(events.count)")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(category.color.opacity(0.8))
                        .clipShape(Capsule())

                    Spacer()

                    // Expand/collapse icon
                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Event list (when expanded)
            if expandedCategories.contains(category) {
                VStack(spacing: Spacing.sm) {
                    ForEach(events.sorted { $0.eventOrder < $1.eventOrder }) { event in
                        eventRow(event: event)
                    }
                }
                .padding(.leading, Spacing.xl)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Event Row

    private func eventRow(event: WeddingDayEvent) -> some View {
        Button {
            selectedEvent = event
            showingEventDetail = true
        } label: {
            HStack(spacing: Spacing.md) {
                // Time indicator
                timeIndicator(event: event)

                // Event content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(event.eventName)
                            .font(Typography.bodyRegular)
                            .fontWeight(event.isHighlighted ? .semibold : .regular)
                            .foregroundColor(AppColors.textPrimary)

                        if event.isMainEvent {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(TimelineColors.primary)
                        }

                        if event.status == .keyEvent {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(TimelineColors.statusKeyEvent)
                        }
                    }

                    if let venueName = event.venueName {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(venueName)
                                .font(Typography.caption)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    // Duration and status
                    HStack(spacing: Spacing.md) {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(event.calculatedDurationMinutes) min")
                                .font(Typography.caption)
                        }
                        .foregroundColor(AppColors.textSecondary)

                        // Status badge
                        statusBadge(status: event.status)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding()
            .background(eventRowBackground(event: event))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(event.isHighlighted ? event.displayColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func timeIndicator(event: WeddingDayEvent) -> some View {
        VStack(spacing: 2) {
            Text(event.timeRangeDisplay)
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(event.displayColor)
        }
        .frame(width: 80, alignment: .leading)
    }

    private func statusBadge(status: WeddingDayEventStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)

            Text(status.displayName)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }

    private func eventRowBackground(event: WeddingDayEvent) -> some View {
        Group {
            if event.isHighlighted {
                LinearGradient(
                    colors: [
                        TimelineColors.cardGradientStart,
                        TimelineColors.cardGradientEnd
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                TimelineColors.glassBackground
            }
        }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        TimelineColors.glassBackground
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TimelineColors.glassBorder, lineWidth: 1)
            )
    }

    // MARK: - Helpers

    private func formattedDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Event Detail Sheet

struct WeddingDayEventDetailSheet: View {
    let event: WeddingDayEvent
    let onDismiss: () -> Void

    @EnvironmentObject private var store: TimelineStoreV2

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(event.eventName)
                        .font(Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)

                    Text(event.category.displayName)
                        .font(Typography.caption)
                        .foregroundColor(event.category.color)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding()
            .background(TimelineColors.glassBackground)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Time and duration
                    detailRow(icon: "clock", title: "Time", value: event.timeRangeDisplay)
                    detailRow(icon: "timer", title: "Duration", value: "\(event.calculatedDurationMinutes) minutes")

                    // Status
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(event.status.color)
                        Text("Status")
                            .font(Typography.subheading)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: event.status.icon)
                            Text(event.status.displayName)
                        }
                        .font(Typography.bodyRegular)
                        .foregroundColor(event.status.color)
                    }

                    // Venue
                    if let venueName = event.venueName {
                        detailRow(icon: "mappin.and.ellipse", title: "Venue", value: venueName)
                    }

                    if let location = event.venueLocation {
                        detailRow(icon: "location", title: "Location", value: location)
                    }

                    // Description
                    if let description = event.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Description")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Text(description)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }

                    // Notes
                    if let notes = event.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Notes")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Text(notes)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }

                    // Dependencies
                    if event.hasDependency, let dependencyEvent = store.dependencyEvent(for: event) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Depends On")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            HStack {
                                Image(systemName: dependencyEvent.category.icon)
                                    .foregroundColor(dependencyEvent.category.color)
                                Text(dependencyEvent.eventName)
                                    .font(Typography.bodyRegular)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                    }

                    // Dependent events
                    let dependents = store.dependentEvents(on: event)
                    if !dependents.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Blocks")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            ForEach(dependents) { dep in
                                HStack {
                                    Image(systemName: dep.category.icon)
                                        .foregroundColor(dep.category.color)
                                    Text(dep.eventName)
                                        .font(Typography.bodyRegular)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
            Text(title)
                .font(Typography.subheading)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineListViewV1()
        .environmentObject(TimelineStoreV2())
        .frame(width: 1000, height: 800)
}
