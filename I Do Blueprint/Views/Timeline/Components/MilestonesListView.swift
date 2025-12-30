//
//  MilestonesListView.swift
//  I Do Blueprint
//
//  Extracted from AllMilestonesView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// List view displaying grouped milestones
struct MilestonesListView: View {
    let groupedMilestones: [(key: String, value: [Milestone])]
    let userTimezone: TimeZone
    let onSelectMilestone: (Milestone) -> Void
    let onToggleCompletion: (Milestone) async -> Void
    
    var body: some View {
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
                                    await onToggleCompletion(milestone)
                                }
                            })
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}
