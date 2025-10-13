//
//  AllMilestonesView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/10/25.
//

import SwiftUI

struct AllMilestonesView: View {
    @ObservedObject var viewModel: TimelineViewModel
    let onSelectMilestone: (Milestone) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: MilestoneFilter = .all
    @State private var sortOrder: MilestoneSortOrder = .dateAscending
    @State private var searchQuery = ""

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
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search milestones...", text: $searchQuery)
                    .textFieldStyle(.plain)

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor)))

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
                            onTap: {
                                onSelectMilestone(milestone)
                            },
                            onToggleCompletion: {
                                Task {
                                    await viewModel.toggleMilestoneCompletion(milestone)
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
        VStack(spacing: 20) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            if !searchQuery.isEmpty {
                Text("No milestones match your search")
                    .font(.title2)
                    .fontWeight(.semibold)

                Button("Clear Search") {
                    searchQuery = ""
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("No Milestones")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add milestones to track important dates")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var filteredAndSortedMilestones: [Milestone] {
        var milestones = viewModel.milestones

        // Apply search filter
        if !searchQuery.isEmpty {
            milestones = milestones.filter {
                $0.milestoneName.localizedCaseInsensitiveContains(searchQuery) ||
                    ($0.description?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            milestones = milestones.filter { !$0.completed && $0.milestoneDate >= Date() }
        case .past:
            milestones = milestones.filter { $0.milestoneDate < Date() }
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
        let grouped = Dictionary(grouping: filteredAndSortedMilestones) { milestone in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: milestone.milestoneDate)
        }

        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"

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
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func daysUntilText() -> String? {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: milestone.milestoneDate)

        guard let days = components.day else { return nil }

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
    case all
    case upcoming
    case past
    case completed
    case incomplete

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
    case dateAscending
    case dateDescending
    case nameAscending
    case nameDescending

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

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

// MARK: - Preview

#Preview {
    AllMilestonesView(
        viewModel: TimelineViewModel(),
        onSelectMilestone: { _ in })
}
