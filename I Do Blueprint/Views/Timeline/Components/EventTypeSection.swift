//
//  EventTypeSection.swift
//  I Do Blueprint
//
//  Extracted from TimelineViewV2.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Section displaying events of a specific type
struct EventTypeSection: View {
    let type: TimelineItemType
    let items: [TimelineItem]
    let onSelect: (TimelineItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: type.color) ?? .blue)
                    .frame(width: 12, height: 12)
                
                Text(type.displayName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        EventCard(item: item)
                            .onTapGesture {
                                onSelect(item)
                            }
                    }
                }
            }
        }
    }
}
