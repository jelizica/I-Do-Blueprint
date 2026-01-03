//
//  CollaborationSettingsView.swift
//  I Do Blueprint
//
//  Settings section for collaboration features
//

import SwiftUI

struct CollaborationSettingsView: View {
    @Environment(\.appStores) private var appStores
    @StateObject private var collaborationStore = AppStores.shared.collaboration
    @State private var showMyCollaborations = false
    @State private var showTeamManagement = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Collaboration")
                    .font(Typography.title1)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Manage your wedding collaborations and team members")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Divider()

            // My Collaborations Button (opens as sheet)
            Button(action: {
                showMyCollaborations = true
            }) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(SemanticColors.primaryAction)
                        .frame(width: 32, height: 32)
                        .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("My Collaborations")
                            .font(Typography.bodyRegular)
                            .fontWeight(.medium)
                            .foregroundColor(SemanticColors.textPrimary)

                        Text("View and manage all weddings you're collaborating on")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }

                    Spacer()

                    // Badge showing pending invitations
                    if !collaborationStore.pendingUserInvitations.isEmpty {
                        Text("\(collaborationStore.pendingUserInvitations.count)")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.textPrimary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(SemanticColors.statusWarning)
                            .cornerRadius(12)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(Spacing.md)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showMyCollaborations) {
                MyCollaborationsView()
                    .environmentObject(collaborationStore)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }

            // Team Management Button (opens as sheet)
            Button(action: {
                showTeamManagement = true
            }) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "person.2.badge.gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(SemanticColors.statusSuccess)
                        .frame(width: 32, height: 32)
                        .background(SemanticColors.statusSuccess.opacity(Opacity.subtle))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Team Management")
                            .font(Typography.bodyRegular)
                            .fontWeight(.medium)
                            .foregroundColor(SemanticColors.textPrimary)

                        Text("Manage collaborators for your current wedding")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(Spacing.md)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showTeamManagement) {
                CollaborationMainView()
                    .environmentObject(collaborationStore)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }

            Spacer()
        }
        .padding(Spacing.xl)
        .background(SemanticColors.backgroundPrimary)
        .task {
            // Load pending invitations count
            await collaborationStore.loadUserCollaborations()
        }
    }
}

struct FeatureItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    CollaborationSettingsView()
}
