//
//  GuestCardV4.swift
//  I Do Blueprint
//
//  Individual guest card component
//

import SwiftUI

struct GuestCardV4: View {
    let guest: Guest
    let settings: CoupleSettings
    @State private var avatarImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Avatar and Status Badge
            avatarSection

            // Guest Name
            nameSection

            // Email
            emailSection

            // Invited By
            invitedBySection

            Spacer()

            // Table and Meal Section
            detailsSection
        }
        .frame(minWidth: 250, maxWidth: .infinity) // Flexible width with comfortable minimum
        .frame(height: 243) // Keep fixed height
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderLight, lineWidth: 0.5)
        )
        .accessibleListItem(
            label: guest.fullName,
            hint: "Tap to view guest details",
            value: guest.rsvpStatus.displayName
        )
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        ZStack(alignment: .topTrailing) {
            // Avatar Circle with Multiavatar
            Group {
                if let image = avatarImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppColors.cardBackground)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        )
                }
            }
            .task {
                await loadAvatar()
            }
            .accessibilityLabel("Avatar for \(guest.fullName)")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.xxl)
            .padding(.leading, Spacing.xxl)

            // Status Badge
            GuestStatusBadge(status: guest.rsvpStatus)
                .padding(.top, Spacing.xxl)
                .padding(.trailing, Spacing.xxl)
        }
        .frame(height: 72)
    }
    
    // MARK: - Name Section
    
    private var nameSection: some View {
        Text(guest.fullName)
            .font(Typography.heading)
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.sm)
    }
    
    // MARK: - Email Section
    
    @ViewBuilder
    private var emailSection: some View {
        if let email = guest.email, !email.isEmpty {
            Text(email)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.xs)
        }
    }
    
    // MARK: - Invited By Section
    
    @ViewBuilder
    private var invitedBySection: some View {
        if let invitedBy = guest.invitedBy {
            Text(invitedBy.displayName(with: settings))
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.sm)
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderLight)

            // Table Assignment
            HStack {
                Text("Table")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                if let table = guest.tableAssignment {
                    Text("\(table)")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("-")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.sm)

            Divider()
                .background(AppColors.borderLight)

            // Meal Choice
            HStack {
                Text("Meal Choice")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                if let mealOption = guest.mealOption, !mealOption.isEmpty {
                    Text(mealOption)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                } else {
                    Text("Not selected")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 96, height: 96) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarJSService
        }
    }
}

// MARK: - Status Badge

struct GuestStatusBadge: View {
    let status: RSVPStatus
    
    var body: some View {
        Group {
            switch status {
            case .confirmed:
                badge(text: "Confirmed", color: AppColors.success, background: AppColors.successLight)
            case .attending:
                badge(text: "Attending", color: AppColors.success, background: AppColors.successLight)
            case .pending:
                badge(text: "Pending", color: AppColors.warning, background: AppColors.warningLight)
            case .maybe:
                badge(text: "Maybe", color: AppColors.warning, background: AppColors.warningLight)
            case .invited:
                badge(text: "Invited", color: AppColors.warning, background: AppColors.warningLight)
            case .declined:
                badge(text: "Declined", color: AppColors.error, background: AppColors.errorLight)
            case .noResponse:
                badge(text: "No Response", color: AppColors.error, background: AppColors.errorLight)
            default:
                badge(text: status.displayName, color: AppColors.textSecondary, background: AppColors.cardBackground)
            }
        }
    }
    
    private func badge(text: String, color: Color, background: Color) -> some View {
        Text(text)
            .font(Typography.caption)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(background)
            .cornerRadius(9999)
    }
}
