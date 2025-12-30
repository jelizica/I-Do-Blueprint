//
//  EventCard.swift
//  I Do Blueprint
//
//  Extracted from TimelineViewV2.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Card displaying a single timeline event
struct EventCard: View {
    let item: TimelineItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.itemType.iconName)
                    .foregroundColor(Color(hex: item.itemType.color))
                
                Spacer()
                
                if item.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text(item.itemDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .frame(width: 180)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}
