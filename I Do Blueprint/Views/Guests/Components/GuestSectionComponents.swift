//
//  GuestSectionComponents.swift
//  I Do Blueprint
//
//  Reusable section components for guest detail views
//

import SwiftUI

// MARK: - Quick Info Section

struct QuickInfoSection: View {
    let guest: Guest
    @EnvironmentObject var settingsStore: SettingsStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Quick Info",
                icon: "info.circle.fill",
                color: .blue
            )
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: Spacing.md
            ) {
                if let invitedBy = guest.invitedBy {
                    QuickInfoCard(
                        icon: "person.2.fill",
                        title: "Invited By",
                        value: invitedBy.displayName(with: settingsStore.settings),
                        color: .purple
                    )
                }
                
                if let invitationNumber = guest.invitationNumber {
                    QuickInfoCard(
                        icon: "number",
                        title: "Invitation",
                        value: "#\(invitationNumber)",
                        color: .orange
                    )
                }
                
                if let table = guest.tableAssignment {
                    QuickInfoCard(
                        icon: "tablecells",
                        title: "Table",
                        value: "\(table)",
                        color: .cyan
                    )
                }
                
                QuickInfoCard(
                    icon: guest.plusOneAllowed ? "person.badge.plus" : "person",
                    title: "Plus One",
                    value: guest.plusOneAllowed ? "Yes" : "No",
                    color: guest.plusOneAllowed ? AppColors.Guest.plusOne : .gray
                )
            }
        }
    }
}

struct QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(Typography.numberMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Visual Contact Section

struct VisualContactSection: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Contact",
                icon: "envelope.circle.fill",
                color: .blue
            )
            
            VStack(spacing: Spacing.sm) {
                if let email = guest.email {
                    GuestContactRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        color: .blue
                    )
                }
                
                if let phone = guest.phone {
                    GuestContactRow(
                        icon: "phone.fill",
                        label: "Phone",
                        value: phone,
                        color: .green
                    )
                }
                
                if let addressLine1 = guest.addressLine1 {
                    let fullAddress = [
                        addressLine1,
                        guest.addressLine2,
                        guest.city,
                        guest.state,
                        guest.zipCode
                    ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                    
                    GuestContactRow(
                        icon: "mappin.circle.fill",
                        label: "Address",
                        value: fullAddress,
                        color: .red
                    )
                }
            }
        }
    }
}

struct GuestContactRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(value)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}

// MARK: - Visual Event Details Section

struct VisualEventDetailsSection: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Event Details",
                icon: "calendar.circle.fill",
                color: .purple
            )
            
            VStack(spacing: Spacing.sm) {
                EventDetailCard(
                    icon: "music.note.house.fill",
                    title: "Ceremony",
                    value: guest.attendingCeremony ? "Attending" : "Not Attending",
                    color: guest.attendingCeremony ? .green : .gray
                )
                
                EventDetailCard(
                    icon: "party.popper.fill",
                    title: "Reception",
                    value: guest.attendingReception ? "Attending" : "Not Attending",
                    color: guest.attendingReception ? .green : .gray
                )
                
                if guest.isWeddingParty {
                    EventDetailCard(
                        icon: "star.circle.fill",
                        title: "Wedding Party",
                        value: guest.weddingPartyRole ?? "Member",
                        color: .yellow
                    )
                }
            }
        }
    }
}

struct EventDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(value)
                    .font(Typography.caption)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(color)
                .font(.title3)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}

// MARK: - Visual Preferences Section

struct VisualPreferencesSection: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Preferences",
                icon: "fork.knife.circle.fill",
                color: .brown
            )
            
            VStack(spacing: Spacing.sm) {
                if let mealOption = guest.mealOption, !mealOption.isEmpty {
                    PreferenceCard(
                        icon: "fork.knife",
                        title: "Meal Choice",
                        value: mealOption,
                        color: .brown
                    )
                }
                
                if let dietary = guest.dietaryRestrictions, !dietary.isEmpty {
                    PreferenceCard(
                        icon: "leaf.fill",
                        title: "Dietary Restrictions",
                        value: dietary,
                        color: .green
                    )
                }
            }
        }
    }
}

struct PreferenceCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text(value)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(color.opacity(0.1))
                )
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}

// MARK: - Visual Notes Section

struct VisualNotesSection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Notes",
                icon: "note.text",
                color: .gray
            )
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(notes)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppColors.textSecondary.opacity(0.2),
                                AppColors.textSecondary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Section Header V2

struct SectionHeaderV2: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Decorative line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100, height: 2)
        }
        .padding(.bottom, Spacing.sm)
    }
}
