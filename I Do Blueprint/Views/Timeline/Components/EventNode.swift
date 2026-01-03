//
//  EventNode.swift
//  I Do Blueprint
//
//  Extracted from TimelineViewV2.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Visual node representing a timeline event
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
                    .foregroundColor(SemanticColors.textPrimary)
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
                    EventNodeTooltip(item: item)
                }
            }
    }
}

// MARK: - Event Node Tooltip

struct EventNodeTooltip: View {
    let item: TimelineItem
    
    var body: some View {
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
