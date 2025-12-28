//
//  AllMilestonesView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/10/25.
//

import SwiftUI

struct AllMilestonesView: View {
    @ObservedObject var store: TimelineStoreV2
    let onSelectMilestone: (Milestone) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appStores) private var appStores
    @State private var selectedFilter: MilestoneFilter = .all
    @State private var sortOrder: MilestoneSortOrder = .dateAscending
    @State private var searchQuery = ""
    @State private var userTimezone: TimeZone = TimeZone(identifier: "America/Los_Angeles") ?? TimeZone.current

    // Cached prototype DateFormatter for month-year parsing (thread confinement via copy per use)
    private static let monthYearFormatterPrototype: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    // Factory to get a formatter configured for a specific timezone by copying the prototype
    private func monthYearFormatter(for timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.monthYearFormatterPrototype.dateFormat
        formatter.locale = Self.monthYearFormatterPrototype.locale
        formatter.calendar = Self.monthYearFormatterPrototype.calendar
        formatter.timeZone = timezone
        return formatter
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                controlsSection

                Divider()

                // Milestones list
                if filteredAndSortedMilestones.isEmpty {
                    emptyStateView
                } else {
                    milestonesListView
                }
            }
            .navigationTitle("All Milestones")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // Trigger new milestone creation
                        dismiss()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                updateTimezone()
            }
            .onChange(of: appStores.settings.settings.global.timezone) { _ in
                updateTimezone()
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Search bar - Using Component Library
            SearchBar(
                text: $searchQuery,
                placeholder: "Search milestones..."
            )

            // Filter and sort controls
            HStack(spacing: 12) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(MilestoneFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                // Sort order button
                Menu {
                    ForEach(MilestoneSortOrder.allCases, id: \.self) { order in
                        Button(action: { sortOrder = order }) {
                            HStack {
                                Text(order.displayName)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.shortName)
                    }
                    .font(.caption)
                }
                .frame(width: 100)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Milestones List

    private var milestonesListView: some View {
        List {
            ForEach(groupedMilestones, id: \.key) { group in
                Section(group.key) {
                    ForEach(group.value) { milestone in
                        MilestoneRow(
                            milestone: milestone,
                            userTimezone: userTimezone,
                            onTap: {
                                onSelectMilestone(milestone)
                            },
                            onToggleCompletion: {
                                Task {
                                    await store.toggleMilestoneCompletion(milestone)
                                }
                            })
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        Group {
            if !searchQuery.isEmpty {
                UnifiedEmptyStateView(config: .searchResults(query: searchQuery))
            } else {
                UnifiedEmptyStateView(
                    config: .custom(
                        icon: "star.circle",
                        title: "No Milestones",
                        message: "Add milestones to track important dates in your wedding planning journey.",
                        actionTitle: nil,
                        onAction: nil
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods
    
    /// Update the cached timezone from settings
    private func updateTimezone() {
        userTimezone = DateFormatting.userTimeZone(from: appStores.settings.settings)
    }

    // MARK: - Computed Properties

    private var filteredAndSortedMilestones: [Milestone] {
        var milestones = store.milestones

        // Apply search filter
        if !searchQuery.isEmpty {
            milestones = milestones.filter {
                $0.milestoneName.localizedCaseInsensitiveContains(searchQuery) ||
                    ($0.description?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        // Apply status filter with timezone-aware date comparisons
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            // Use timezone-aware comparison: milestone is upcoming if it's today or in the future
            milestones = milestones.filter { milestone in
                !milestone.completed && 
                DateFormatting.daysBetween(from: Date(), to: milestone.milestoneDate, in: userTimezone) >= 0
            }
        case .past:
            // Use timezone-aware comparison: milestone is past if it was before today
            milestones = milestones.filter { milestone in
                DateFormatting.daysBetween(from: Date(), to: milestone.milestoneDate, in: userTimezone) < 0
            }
        case .completed:
            milestones = milestones.filter { $0.completed }
        case .incomplete:
            milestones = milestones.filter { !$0.completed }
        }

        // Apply sorting
        switch sortOrder {
        case .dateAscending:
            milestones.sort { $0.milestoneDate < $1.milestoneDate }
        case .dateDescending:
            milestones.sort { $0.milestoneDate > $1.milestoneDate }
        case .nameAscending:
            milestones.sort { $0.milestoneName < $1.milestoneName }
        case .nameDescending:
            milestones.sort { $0.milestoneName > $1.milestoneName }
        }

        return milestones
    }

    private var groupedMilestones: [(key: String, value: [Milestone])] {
        // Use user's timezone for month grouping
        let grouped = Dictionary(grouping: filteredAndSortedMilestones) { milestone in
            DateFormatting.formatDate(milestone.milestoneDate, format: "MMMM yyyy", timezone: userTimezone)
        }

        return grouped.sorted { first, second in
            // Reuse cached formatter settings, only adjust timezone per-use
            let formatter = monthYearFormatter(for: userTimezone)

            guard let firstDate = formatter.date(from: first.key),
                  let secondDate = formatter.date(from: second.key) else {
                return first.key < second.key
            }

            return firstDate < secondDate
        }
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: Milestone
    let userTimezone: TimeZone
    let onTap: () -> Void
    let onToggleCompletion: () -> Void

    private var milestoneColor: Color {
        if let colorString = milestone.color {
            switch colorString.lowercased() {
            case "red": return .red
            case "orange": return .orange
            case "yellow": return .yellow
            case "green": return .green
            case "blue": return .blue
            case "purple": return .purple
            case "pink": return .pink
            default: return .blue
            }
        }
        return .blue
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Completion checkbox
                Button(action: onToggleCompletion) {
                    Image(systemName: milestone.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(milestone.completed ? .green : .gray)
                }
                .buttonStyle(.plain)

                // Color indicator
                Circle()
                    .fill(milestoneColor)
                    .frame(width: 12, height: 12)

                // Milestone info
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.milestoneName)
                        .font(.headline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        Text(formatDate(milestone.milestoneDate))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let daysText = daysUntilText() {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(daysText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let description = milestone.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func daysUntilText() -> String? {
        // Use user's timezone for day calculations
        let days = DateFormatting.daysBetween(from: Date(), to: milestone.milestoneDate, in: userTimezone)

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days == -1 {
            return "Yesterday"
        } else if days > 0 {
            return "in \(days) days"
        } else {
            return "\(abs(days)) days ago"
        }
    }
}

// MARK: - Filter and Sort Options

enum MilestoneFilter: String, CaseIterable {
    case all = "all"
    case upcoming = "upcoming"
    case past = "past"
    case completed = "completed"
    case incomplete = "incomplete"

    var displayName: String {
        switch self {
        case .all: "All"
        case .upcoming: "Upcoming"
        case .past: "Past"
        case .completed: "Completed"
        case .incomplete: "Incomplete"
        }
    }
}

enum MilestoneSortOrder: String, CaseIterable {
    case dateAscending = "dateAscending"
    case dateDescending = "dateDescending"
    case nameAscending = "nameAscending"
    case nameDescending = "nameDescending"

    var displayName: String {
        switch self {
        case .dateAscending: "Date (Earliest First)"
        case .dateDescending: "Date (Latest First)"
        case .nameAscending: "Name (A-Z)"
        case .nameDescending: "Name (Z-A)"
        }
    }

    var shortName: String {
        switch self {
        case .dateAscending: "Date ↑"
        case .dateDescending: "Date ↓"
        case .nameAscending: "Name ↑"
        case .nameDescending: "Name ↓"
        }
    }
}

extension MilestoneRow {
    private func formatDate(_ date: Date) -> String {
        // Use injected timezone for date formatting
        return DateFormatting.formatDateMedium(date, timezone: userTimezone)
    }
}

// MARK: - Preview

#Preview {
    AllMilestonesView(
        store: TimelineStoreV2(),
        onSelectMilestone: { _ in })
}
