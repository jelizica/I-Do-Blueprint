//
//  MilestoneRow.swift
//  I Do Blueprint
//
//  Extracted from AllMilestonesView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Row displaying a single milestone with completion toggle
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
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        // Use injected timezone for date formatting
        return DateFormatting.formatDateMedium(date, timezone: userTimezone)
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
