//
//  CollaborationMainView.swift
//  I Do Blueprint
//
//  Main view for collaboration features combining team management and activity feed
//

import SwiftUI

struct CollaborationMainView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: CollaborationSection = .team

    enum CollaborationSection: String, CaseIterable {
        case team = "Team"
        case activity = "Activity"

        var icon: String {
            switch self {
            case .team: return "person.2.fill"
            case .activity: return "clock.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with section picker
                HStack {
                    Text("Team Management")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textPrimary)

                    Spacer()

                    // Section picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(CollaborationSection.allCases, id: \.self) { section in
                            Label(section.rawValue, systemImage: section.icon)
                                .tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
                .padding()

                Divider()

                // Content
                Group {
                    switch selectedSection {
                    case .team:
                        CollaboratorListView()
                    case .activity:
                        ActivityFeedView()
                    }
                }
            }
            .frame(minWidth: 800, minHeight: 600)
            .background(SemanticColors.backgroundPrimary)
            .navigationTitle("Team Management")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CollaborationMainView()
}
