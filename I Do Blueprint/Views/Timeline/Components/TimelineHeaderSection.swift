//
//  TimelineHeaderSection.swift
//  I Do Blueprint
//
//  Extracted from TimelineViewV2.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Header section displaying timeline title and statistics
struct TimelineHeaderSection: View {
    let totalEvents: Int
    let milestonesCount: Int
    let completedCount: Int
    
    var body: some View {
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
                    TimelineStatBadge(
                        title: "Total Events",
                        value: "\(totalEvents)",
                        icon: "calendar"
                    )
                    
                    TimelineStatBadge(
                        title: "Milestones",
                        value: "\(milestonesCount)",
                        icon: "star.fill"
                    )
                    
                    TimelineStatBadge(
                        title: "Completed",
                        value: "\(completedCount)",
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
}

// MARK: - Stat Badge

struct TimelineStatBadge: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
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
}
