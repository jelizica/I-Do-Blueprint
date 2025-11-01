//
//  CollaborationCard.swift
//  I Do Blueprint
//
//  Card displaying a single collaboration with actions
//

import SwiftUI

struct CollaborationCard: View {
    let collaboration: UserCollaboration
    let isCurrentWedding: Bool
    let onSwitchTo: () -> Void
    let onLeave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with couple name and role
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(collaboration.coupleName)
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let weddingDate = collaboration.weddingDate {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(collaboration.formattedWeddingDate)
                        }
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Role badge
                roleBadge
            }
            
            Divider()
            
            // Metadata
            HStack(spacing: Spacing.lg) {
                if let invitedBy = collaboration.invitedBy {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                        Text("Invited by \(invitedBy)")
                    }
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                }
                
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(collaboration.relativeInvitationTime)
                }
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
            }
            
            Divider()
            
            // Actions
            HStack(spacing: Spacing.md) {
                if isCurrentWedding {
                    // Show "Currently Viewing" indicator
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text("Currently Viewing")
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    // Show switch button
                    Button(action: onSwitchTo) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Switch to Wedding")
                        }
                        .font(Typography.bodyRegular)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Switch to \(collaboration.coupleName)'s wedding")
                }
                
                Spacer()
                
                Button(action: onLeave) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave")
                    }
                    .font(Typography.bodyRegular)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.error)
                .accessibilityLabel("Leave \(collaboration.coupleName)'s wedding")
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppColors.textPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Role Badge
    
    private var roleBadge: some View {
        Text(collaboration.role.displayName)
            .font(Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(roleColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(roleColor.opacity(0.1))
            .cornerRadius(6)
    }
    
    private var roleColor: Color {
        switch collaboration.role {
        case .owner:
            return AppColors.primary
        case .partner:
            return AppColors.primary.opacity(0.7)
        case .planner:
            return AppColors.success
        case .viewer:
            return AppColors.textSecondary
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Active Collaboration") {
    CollaborationCard(
        collaboration: .makeTest(
            coupleName: "Jessica & Elizabeth",
            role: .partner,
            status: .active
        ),
        isCurrentWedding: false,
        onSwitchTo: { print("Switch") },
        onLeave: { print("Leave") }
    )
    .padding()
}

#Preview("Currently Viewing") {
    CollaborationCard(
        collaboration: .makeTest(
            coupleName: "Sarah & Mike",
            role: .viewer,
            status: .active
        ),
        isCurrentWedding: true,
        onSwitchTo: { print("Switch") },
        onLeave: { print("Leave") }
    )
    .padding()
}
#endif
