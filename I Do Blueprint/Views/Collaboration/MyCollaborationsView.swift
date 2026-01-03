//
//  MyCollaborationsView.swift
//  I Do Blueprint
//
//  View for managing all weddings the user is collaborating on
//

import SwiftUI

struct MyCollaborationsView: View {
    @EnvironmentObject private var collaborationStore: CollaborationStoreV2
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveConfirmation = false
    @State private var collaborationToLeave: UserCollaboration?
    @State private var showError = false
    @State private var errorMessage = ""

    private let logger = AppLogger.ui

    // Get current wedding ID from session
    private var currentWeddingId: UUID? {
        try? SessionManager.shared.getTenantId()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Header
                    headerSection

                    // Pending Invitations Section
                    if !collaborationStore.pendingUserInvitations.isEmpty {
                        pendingInvitationsSection
                    }

                    // Active Collaborations Section
                    activeCollaborationsSection

                    // Empty State
                    let hasNoCollaborations = collaborationStore.userCollaborations.isEmpty
                    let hasNoPending = collaborationStore.pendingUserInvitations.isEmpty
                    let notLoading = !collaborationStore.isLoadingCollaborations
                    if hasNoCollaborations && hasNoPending && notLoading {
                        emptyStateView
                    }
                }
                .padding(Spacing.xl)
            }
            .frame(minWidth: 800, minHeight: 600)
            .background(SemanticColors.backgroundPrimary)
            .navigationTitle("My Collaborations")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await collaborationStore.loadUserCollaborations()
            }
        }
        .alert("Leave Wedding?", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                if let collaboration = collaborationToLeave {
                    Task {
                        do {
                            try await collaborationStore.leaveCollaboration(coupleId: collaboration.coupleId)
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
        } message: {
            if let collaboration = collaborationToLeave {
                Text("Are you sure you want to leave \(collaboration.coupleName)'s wedding? You will lose access to all planning data.")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("My Collaborations")
                .font(Typography.title1)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Manage all weddings you're helping to plan")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    // MARK: - Pending Invitations Section

    private var pendingInvitationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Pending Invitations", systemImage: "envelope.fill")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Text("\(collaborationStore.pendingUserInvitations.count)")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.statusWarning.opacity(Opacity.subtle))
                    .cornerRadius(12)
            }

            ForEach(collaborationStore.pendingUserInvitations) { invitation in
                PendingInvitationCard(
                    invitation: invitation,
                    onAccept: {
                        Task {
                            do {
                                try await collaborationStore.acceptUserInvitation(id: invitation.id)
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    },
                    onDecline: {
                        Task {
                            do {
                                try await collaborationStore.declineInvitation(id: invitation.id)
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                )
            }
        }
    }

    // MARK: - Active Collaborations Section

    private var activeCollaborationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Active Collaborations", systemImage: "person.2.fill")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                if !collaborationStore.userCollaborations.isEmpty {
                    Text("\(collaborationStore.userCollaborations.count)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(SemanticColors.statusSuccess.opacity(Opacity.subtle))
                        .cornerRadius(12)
                }
            }

            if collaborationStore.isLoadingCollaborations {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(Spacing.xl)
            } else {
                ForEach(collaborationStore.userCollaborations) { collaboration in
                    CollaborationCard(
                        collaboration: collaboration,
                        isCurrentWedding: collaboration.coupleId == currentWeddingId,
                        onSwitchTo: {
                            switchToCollaboration(collaboration)
                        },
                        onLeave: {
                            collaborationToLeave = collaboration
                            showLeaveConfirmation = true
                        }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.textSecondary)

            Text("No Collaborations Yet")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            Text("You haven't been invited to collaborate on any weddings yet. When someone invites you, their invitation will appear here.")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func switchToCollaboration(_ collaboration: UserCollaboration) {
        logger.info("Switching to collaboration: \(collaboration.coupleName)")

        Task {
            await SessionManager.shared.setTenantId(
                collaboration.coupleId,
                coupleName: collaboration.coupleName,
                weddingDate: collaboration.weddingDate
            )

            // Reload collaboration data after switching
            // This ensures the view updates with the new context
            await collaborationStore.loadUserCollaborations()

            // Track switch
            SentryService.shared.trackAction(
                "collaboration_switched",
                category: "navigation",
                metadata: [
                    "couple_id": collaboration.coupleId.uuidString,
                    "couple_name": collaboration.coupleName
                ]
            )

            // Close the sheet after switching
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    MyCollaborationsView()
        .environment(\.appStores, AppStores.shared)
}
