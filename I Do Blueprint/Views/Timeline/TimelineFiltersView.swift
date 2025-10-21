//
//  TimelineFiltersView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TimelineFiltersView: View {
    @ObservedObject var store: TimelineStoreV2
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Item Type Filter
                Section("Item Type") {
                    Picker("Type", selection: $store.filterType) {
                        Text("All Types").tag(TimelineItemType?.none)
                        ForEach(TimelineItemType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: typeIcon(type))
                                Text(type.displayName)
                            }
                            .tag(TimelineItemType?.some(type))
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Completion Filter
                Section("Status") {
                    Toggle("Show Completed", isOn: $store.showCompleted)
                }

                // Actions
                Section {
                    Button("Clear All Filters") {
                        store.clearFilters()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 400)
    }

    private func typeIcon(_ type: TimelineItemType) -> String {
        switch type {
        case .task: "checklist"
        case .milestone: "star.fill"
        case .vendorEvent: "person.2.fill"
        case .payment: "dollarsign.circle.fill"
        case .reminder: "bell.fill"
        case .ceremony: "heart.fill"
        case .other: "circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineFiltersView(store: TimelineStoreV2())
}
