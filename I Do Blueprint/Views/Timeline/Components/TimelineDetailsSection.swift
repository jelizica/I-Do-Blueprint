//
//  TimelineDetailsSection.swift
//  I Do Blueprint
//
//  Extracted from TimelineViewV2.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Details section showing events grouped by type
struct TimelineDetailsSection: View {
    let items: [TimelineItem]
    let onSelectItem: (TimelineItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Details")
                .font(.title2)
                .fontWeight(.bold)
            
            // Group events by type
            ForEach(TimelineItemType.allCases, id: \.self) { type in
                if let typeItems = itemsByType(type), !typeItems.isEmpty {
                    EventTypeSection(type: type, items: typeItems, onSelect: onSelectItem)
                }
            }
        }
        .padding(Spacing.xxl)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func itemsByType(_ type: TimelineItemType) -> [TimelineItem]? {
        let filtered = items.filter { $0.itemType == type }
        return filtered.isEmpty ? nil : filtered
    }
}
