//
//  GuestDetailCompactHeader.swift
//  I Do Blueprint
//
//  Compact horizontal header for guest detail modal when space is limited
//  Used in adaptive layout when window height is below threshold
//

import SwiftUI

struct GuestDetailCompactHeader: View {
    let guest: Guest
    let settings: CoupleSettings
    let onDismiss: () -> Void
    
    @State private var avatarImage: NSImage?
    
    private var invitedByText: String {
        guard let invitedBy = guest.invitedBy else { return "Unknown" }
        return invitedBy.displayName(with: settings)
    }
    
    private var relationshipText: String {
        guest.relationshipToCouple ?? "Guest"
    }
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    AppColors.error.opacity(0.9),
                    AppColors.error
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: Spacing.md) {
                // Avatar (smaller)
                Group {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.textPrimary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Circle()
                            .fill(AppColors.textPrimary.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                            )
                    }
                }
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")
                
                // Name and relationship (vertical stack)
                VStack(alignment: .leading, spacing: 2) {
                    Text(guest.fullName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(invitedByText) • \(relationshipText)")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textPrimary.opacity(0.9))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Close Button
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(AppColors.textPrimary.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .frame(height: 80)
        .cornerRadius(CornerRadius.lg, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Avatar Loading
    
    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 100, height: 100) // 2x for retina
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

// MARK: - Preview

#Preview("Compact Header") {
    let testGuest = Guest(
        id: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        firstName: "Sarah",
        lastName: "Johnson",
        email: "sarah.johnson@email.com",
        phone: nil,
        guestGroupId: nil,
        relationshipToCouple: "Friend",
        invitedBy: .bride1,
        rsvpStatus: .confirmed,
        rsvpDate: nil,
        plusOneAllowed: false,
        plusOneName: nil,
        plusOneAttending: false,
        attendingCeremony: true,
        attendingReception: true,
        attendingRehearsal: false,
        attendingOtherEvents: nil,
        dietaryRestrictions: nil,
        accessibilityNeeds: nil,
        tableAssignment: nil,
        seatNumber: nil,
        preferredContactMethod: nil,
        addressLine1: nil,
        addressLine2: nil,
        city: nil,
        state: nil,
        zipCode: nil,
        country: nil,
        invitationNumber: nil,
        isWeddingParty: false,
        weddingPartyRole: nil,
        preparationNotes: nil,
        coupleId: UUID(),
        mealOption: nil,
        giftReceived: false,
        notes: nil,
        hairDone: false,
        makeupDone: false
    )
    
    GuestDetailCompactHeader(
        guest: testGuest,
        settings: CoupleSettings(
            global: GlobalSettings(
                currency: "USD",
                weddingDate: "2026-08-11",
                isWeddingDateTBD: false,
                timezone: "America/New_York",
                partner1FullName: "Alice",
                partner1Nickname: "",
                partner2FullName: "Bob",
                partner2Nickname: "",
                weddingEvents: []
            ),
            theme: .default,
            budget: .default,
            cashFlow: .default,
            tasks: .default,
            vendors: .default,
            guests: .default,
            documents: .default,
            notifications: .default,
            links: .default
        ),
        onDismiss: {}
    )
    .frame(width: 400)
}
