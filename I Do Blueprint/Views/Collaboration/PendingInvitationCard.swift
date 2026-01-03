//
//  PendingInvitationCard.swift
//  I Do Blueprint
//
//  Card displaying a pending invitation with accept/decline actions
//

import SwiftUI

struct PendingInvitationCard: View {
    let invitation: UserCollaboration
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with couple name and role
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.statusWarning)

                        Text(invitation.coupleName)
                            .font(Typography.heading)
                            .foregroundColor(SemanticColors.textPrimary)
                    }

                    if let weddingDate = invitation.weddingDate {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(invitation.formattedWeddingDate)
                        }
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    }
                }

                Spacer()

                // Role badge
                roleBadge
            }

            Divider()

            // Invitation details
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let invitedBy = invitation.invitedBy {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                        Text("\(invitedBy) invited you to collaborate")
                    }
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Invited \(invitation.relativeInvitationTime)")
                }
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
            }

            Divider()

            // Actions
            HStack(spacing: Spacing.md) {
                Button(action: onAccept) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Accept")
                    }
                    .font(Typography.bodyRegular)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SemanticColors.statusSuccess)
                .accessibilityLabel("Accept invitation from \(invitation.coupleName)")

                Button(action: onDecline) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "xmark.circle")
                        Text("Decline")
                    }
                    .font(Typography.bodyRegular)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(SemanticColors.textSecondary)
                .accessibilityLabel("Decline invitation from \(invitation.coupleName)")
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.statusWarning.opacity(Opacity.verySubtle))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.statusWarning.opacity(Opacity.light), lineWidth: 2)
        )
        .cornerRadius(12)
    }

    // MARK: - Role Badge

    private var roleBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text(invitation.role.displayName)
        }
        .font(Typography.caption)
        .fontWeight(.medium)
        .foregroundColor(SemanticColors.statusWarning)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(SemanticColors.statusWarning.opacity(Opacity.subtle))
        .cornerRadius(6)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Pending Invitation") {
    PendingInvitationCard(
        invitation: .makeTest(
            coupleName: "Jessica & Elizabeth",
            role: .planner,
            status: .pending,
            invitedBy: "Jessica Clark"
        ),
        onAccept: { print("Accept") },
        onDecline: { print("Decline") }
    )
    .padding()
}

#Preview("Partner Role") {
    PendingInvitationCard(
        invitation: .makeTest(
            coupleName: "Sarah & Mike",
            role: .partner,
            status: .pending,
            invitedBy: "Sarah Johnson"
        ),
        onAccept: { print("Accept") },
        onDecline: { print("Decline") }
    )
    .padding()
}
#endif
