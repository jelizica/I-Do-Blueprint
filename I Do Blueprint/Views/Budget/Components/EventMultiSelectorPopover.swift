//
//  EventMultiSelectorPopover.swift
//  I Do Blueprint
//
//  Popover for selecting multiple wedding events for a budget item
//

import SwiftUI

struct EventMultiSelectorPopover: View {
    let events: [WeddingEventDB]
    let selectedEventIds: [String]
    let onToggleEvent: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if events.isEmpty {
                Text("No events configured")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    Button(action: {
                        onToggleEvent(event.id)
                    }) {
                        HStack {
                            Image(systemName: selectedEventIds.contains(event.id) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedEventIds.contains(event.id) ? .accentColor : .secondary)
                            
                            Text(event.eventName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    if index < events.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(minWidth: 200, maxWidth: 300)
        .padding(.vertical, 8)
    }
}
