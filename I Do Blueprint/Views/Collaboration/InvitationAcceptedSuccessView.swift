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
                .foregroundColor(AppColors.success)

            // Title
            Text("Welcome to the Team!")
                .font(Typography.title1)
                .foregroundColor(AppColors.textPrimary)

            // Message
            VStack(spacing: Spacing.sm) {
                Text("You've successfully joined")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)

                Text(coupleName)
                    .font(Typography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
            }

            // Info Card
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.primary)

                    Text("You now have access to this couple's wedding planning data")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(AppColors.primary)

                    Text("You can switch between couples anytime using the couple switcher")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(Spacing.md)
            .background(AppColors.primary.opacity(0.1))
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
