//
//  AllMilestonesView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/10/25.
//  Refactored: Decomposed into focused components to reduce complexity
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
                MilestonesControlsSection(
                    searchQuery: $searchQuery,
                    selectedFilter: $selectedFilter,
                    sortOrder: $sortOrder
                )

                Divider()

                // Milestones list
                if filteredAndSortedMilestones.isEmpty {
                    emptyStateView
                } else {
                    MilestonesListView(
                        groupedMilestones: groupedMilestones,
                        userTimezone: userTimezone,
                        onSelectMilestone: onSelectMilestone,
                        onToggleCompletion: { milestone in
                            await store.toggleMilestoneCompletion(milestone)
                        }
                    )
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

// MARK: - Preview

#Preview {
    AllMilestonesView(
        store: TimelineStoreV2(),
        onSelectMilestone: { _ in })
}
