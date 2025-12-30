//
//  TimelineToolbar.swift
//  I Do Blueprint
//
//  Extracted from TimelineViewV2.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Toolbar buttons for timeline actions
struct TimelineToolbar: View {
    let isLoading: Bool
    let onShowFilters: () -> Void
    let onRefresh: () async -> Void
    let onAddItem: () -> Void
    let onAddMilestone: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onShowFilters) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            
            Button(action: { Task { await onRefresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(isLoading)
            
            Menu {
                Button("Add Timeline Item", action: onAddItem)
                Button("Add Milestone", action: onAddMilestone)
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
