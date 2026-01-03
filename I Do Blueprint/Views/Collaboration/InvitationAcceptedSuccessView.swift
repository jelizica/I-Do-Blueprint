//
//  InvitationAcceptedSuccessView.swift
//  I Do Blueprint
//
//  Success view after accepting invitation with option to switch couples
//

import SwiftUI

struct InvitationAcceptedSuccessView: View {
    let coupleName: String
    let coupleId: UUID
    let onSwitchToCouple: () -> Void
    let onStayHere: () -> Void

    private let logger = AppLogger.ui

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(SemanticColors.statusSuccess)

            // Title
            Text("Welcome to the Team!")
                .font(Typography.title1)
                .foregroundColor(SemanticColors.textPrimary)

            // Message
            VStack(spacing: Spacing.sm) {
                Text("You've successfully joined")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(coupleName)
                    .font(Typography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.primaryAction)
            }

            // Info Card
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("You now have access to this couple's wedding planning data")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("You can switch between couples anytime using the couple switcher")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
            .cornerRadius(8)

            Spacer()

            // Action Buttons
            VStack(spacing: Spacing.md) {
                Button {
                    logger.info("User chose to switch to shared couple: \(coupleName)")
                    onSwitchToCouple()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Switch to \(coupleName)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

                Button {
                    logger.info("User chose to stay on current couple")
                    onStayHere()
                } label: {
                    Text("Stay on Current Couple")
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }
        }
        .frame(width: 500, height: 500)
        .padding(Spacing.xxl)
    }
}

// MARK: - Preview

#Preview("Success View") {
    InvitationAcceptedSuccessView(
        coupleName: "Jessica & Elizabeth",
        coupleId: UUID(),
        onSwitchToCouple: {
            print("Switch to couple")
        },
        onStayHere: {
            print("Stay here")
        }
    )
}
