//
//  AcceptInvitationView.swift
//  I Do Blueprint
//
//  UI for accepting collaboration invitations from deep links
//

import SwiftUI

struct AcceptInvitationView: View {
    let token: String
    let coordinator: AppCoordinator
    let details: InvitationDetails?

    @Environment(\.collaborationStore) private var collaborationStore
    @StateObject private var authContext = AuthContext.shared

    @State private var isLoading = true
    @State private var invitationDetails: InvitationDetails?
    @State private var error: String?
    @State private var isAccepting = false
    @State private var acceptSuccess = false
    @State private var acceptedCoupleId: UUID?
    @State private var acceptedCoupleName: String?

    private let logger = AppLogger.auth
    @EnvironmentObject private var appStores: AppStores

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(message: error)
            } else if acceptSuccess {
                successView
            } else if let details = invitationDetails {
                invitationDetailsView(details)
            }
        }
        .frame(width: 500, height: 400)
        .padding(Spacing.xxxl)
        .onAppear {
            if let preloaded = details {
                self.invitationDetails = preloaded
                self.isLoading = false
            }
        }
        .task(id: token) {
            if details == nil {
                await loadInvitation()
            }
        }
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading invitation...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Invitation Error")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Close") {
                    coordinator.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Contact Support") {
                    if let url = URL(string: "mailto:support@idoblueprint.com?subject=Invitation%20Issue") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Success State

    private var successView: some View {
        Group {
            if let coupleId = acceptedCoupleId, let coupleName = acceptedCoupleName {
                InvitationAcceptedSuccessView(
                    coupleName: coupleName,
                    coupleId: coupleId,
                    onSwitchToCouple: {
                        Task {
                            await switchToAcceptedCouple(coupleId: coupleId, coupleName: coupleName)
                        }
                    },
                    onStayHere: {
                        coordinator.dismiss()
                    }
                )
            } else {
                // Fallback if couple info not available
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)

                    Text("Welcome to the Team!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("You've successfully joined the wedding planning team.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Close") {
                        coordinator.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    // MARK: - Invitation Details

    private func invitationDetailsView(_ details: InvitationDetails) -> some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)

                Text("You're Invited!")
                    .font(.title)
                    .fontWeight(.bold)

                if let coupleName = details.coupleName {
                    Text("to collaborate with \(coupleName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("to collaborate on wedding planning")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Invitation Details Card
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Role", value: details.role.roleName.displayName)
                DetailRow(label: "Email", value: details.invitation.email)

                DetailRow(
                    label: "Expires",
                    value: formatExpiryDate(details.invitation.expiresAt),
                    isWarning: isExpiringSoon(details.invitation.expiresAt)
                )
            }
            .padding(Spacing.lg)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button("Decline") {
                    coordinator.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Accept Invitation") {
                    Task {
                        await acceptInvitation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isAccepting || details.invitation.status != .pending)
            }

            if isAccepting {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Accepting...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Helper Views

    private struct DetailRow: View {
        let label: String
        let value: String
        var isWarning: Bool = false

        var body: some View {
            HStack {
                Text(label + ":")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isWarning ? .orange : .primary)
            }
        }
    }

    // MARK: - Actions

    private func loadInvitation() async {
        logger.info("Loading invitation for token")

        // Prevent duplicate loads
        guard isLoading else { return }

        do {
            // Fetch invitation details directly by token
            let details = try await collaborationStore.repository.fetchInvitationByToken(token)

            self.invitationDetails = details
            isLoading = false

            logger.info("Successfully loaded invitation for \(details.invitation.email)")

        } catch CollaborationError.invitationNotFound {
            logger.warning("Invitation not found or already accepted")
            self.error = "Invitation not found or has already been accepted."
            isLoading = false
        } catch CollaborationError.invitationExpired {
            logger.warning("Invitation has expired")
            self.error = "This invitation has expired. Please request a new invitation."
            isLoading = false
        } catch {
            logger.error("Failed to load invitation", error: error)
            self.error = "Failed to load invitation: \(error.localizedDescription)"
            isLoading = false

            await SentryService.shared.captureError(error, context: [
                "operation": "loadInvitation",
                "token_present": "true"
            ])
        }
    }

    private func acceptInvitation() async {
        guard let details = invitationDetails else { return }

        logger.info("Accepting invitation for \(details.invitation.email)")
        isAccepting = true

        do {
            // Update invitation status to accepted and create collaborator record
            let invitationId = details.invitation.id
            _ = try await collaborationStore.repository.acceptInvitation(id: invitationId)

            logger.info("Successfully accepted invitation - collaborator access granted")
            
            // Store couple info for success view
            acceptedCoupleId = details.coupleId
            acceptedCoupleName = details.coupleName ?? "Wedding Planning"
            
            acceptSuccess = true
            isAccepting = false

        } catch {
            logger.error("Failed to accept invitation", error: error)
            self.error = "Failed to accept invitation: \(error.localizedDescription)"
            isAccepting = false

            await SentryService.shared.captureError(error, context: [
                "operation": "acceptInvitation",
                "invitation_id": details.invitation.id.uuidString
            ])
        }
    }
    
    private func switchToAcceptedCouple(coupleId: UUID, coupleName: String) async {
        logger.info("Switching to accepted couple: \(coupleName)")
        
        // Update session manager to switch to the new couple (async call)
        await SessionManager.shared.setTenantId(
            coupleId,
            coupleName: coupleName,
            weddingDate: nil // Will be loaded from settings
        )
        
        // Reset all stores to reload data for new couple
        await MainActor.run {
            appStores.resetAllStores()
        }
        
        logger.info("Switched to couple: \(coupleName)")
        
        // Track couple switch
        await SentryService.shared.trackAction(
            "couple_switched_after_invitation",
            category: "collaboration",
            metadata: [
                "couple_id": coupleId.uuidString,
                "couple_name": coupleName
            ]
        )
        
        // Dismiss the invitation view
        await MainActor.run {
            coordinator.dismiss()
        }
    }

    // MARK: - Helper Methods

    private func formatExpiryDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func isExpiringSoon(_ date: Date) -> Bool {
        let hoursUntilExpiry = date.timeIntervalSinceNow / 3600
        return hoursUntilExpiry < 24 && hoursUntilExpiry > 0
    }
}

// MARK: - Preview

#Preview {
    AcceptInvitationView(
        token: "sample-token",
        coordinator: AppCoordinator.shared,
        details: nil
    )
}
