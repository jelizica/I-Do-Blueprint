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
    var onWeddingDayTapped: (() -> Void)?

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

                // Wedding Day Timeline button
                if let onWeddingDayTapped {
                    weddingDayButton(action: onWeddingDayTapped)
                }

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

    private func weddingDayButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wedding Day")
                        .font(Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Plan your big day")
                        .font(Typography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                LinearGradient(
                    colors: [TimelineColors.primary, TimelineColors.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: TimelineColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
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
