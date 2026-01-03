//
//  GuestDetailHeader.swift
//  I Do Blueprint
//
//  Gradient header with avatar for guest detail modal
//

import SwiftUI

struct GuestDetailHeader: View {
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
                    SemanticColors.error
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: Spacing.md) {
                // Close Button
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SemanticColors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(SemanticColors.textPrimary.opacity(Opacity.light))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
                
                // Avatar with Multiavatar
                Group {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(SemanticColors.textPrimary.opacity(Opacity.light), lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(SemanticColors.textPrimary.opacity(Opacity.light))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(SemanticColors.textPrimary)
                            )
                    }
                }
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")
                
                // Name
                Text(guest.fullName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(SemanticColors.textPrimary)
                
                // Relationship
                Text("\(invitedByText) • \(relationshipText)")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textPrimary.opacity(Opacity.strong))
                
                Spacer()
            }
        }
        .frame(height: 200)
        .cornerRadius(CornerRadius.lg, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Avatar Loading
    
    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 160, height: 160) // 2x for retina
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
