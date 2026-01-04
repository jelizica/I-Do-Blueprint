//
//  GuestResponsesCardV6.swift
//  I Do Blueprint
//
//  Native macOS "Wow Factor" version with premium visual design:
//  - SwiftUI Material backgrounds for vibrancy
//  - Gradient border strokes for depth
//  - Multi-layer macOS-native shadows
//  - Hover elevation with spring animations
//  - Staggered appearance animations
//  - System colors that adapt to light/dark mode
//  - Enhanced stat columns with gradient icons
//

import SwiftUI

struct GuestResponsesCardV6: View {
    @ObservedObject var store: GuestStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator
    
    // Animation state
    @State private var hasAppeared = false
    @State private var isHovered = false
    
    // Sheet presentation state
    @State private var selectedGuestId: UUID?

    var body: some View {
        let totalGuests = store.guests.count
        let attendingCount = store.guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let declinedCount = store.guests.filter { $0.rsvpStatus == .declined }.count
        let pendingCount = store.guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited }.count
        let respondedCount = attendingCount + declinedCount
        let responseRate = totalGuests > 0 ? Double(respondedCount) / Double(totalGuests) : 0
        
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // MARK: - Header Section
            HStack(spacing: Spacing.md) {
                // Native icon badge
                NativeIconBadge(
                    systemName: "person.2.fill",
                    color: AppColors.Guest.confirmed,
                    size: 44
                )
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Guest Responses")
                        .font(Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(nsColor: .labelColor))

                    Text("\(respondedCount) of \(totalGuests) guests responded")
                        .font(Typography.caption)
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                
                Spacer()
                
                // Response rate badge
                if totalGuests > 0 {
                    VStack(spacing: Spacing.xxs) {
                        Text("\(Int(responseRate * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppColors.Guest.confirmed,
                                        AppColors.Guest.confirmed.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Response")
                            .font(Typography.caption2)
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(AppColors.Guest.confirmed.opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : -10)
            
            // Native gradient divider
            NativeDividerStyle(opacity: 0.4)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)
            
            // MARK: - Stats Section
            HStack(spacing: Spacing.lg) {
                NativeStatColumn(
                    value: attendingCount,
                    label: "Attending",
                    color: SemanticColors.success,
                    icon: "checkmark.circle.fill"
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)
                
                NativeStatColumn(
                    value: declinedCount,
                    label: "Declined",
                    color: SemanticColors.error,
                    icon: "xmark.circle.fill"
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.25), value: hasAppeared)
                
                NativeStatColumn(
                    value: pendingCount,
                    label: "Pending",
                    color: SemanticColors.warning,
                    icon: "clock.fill"
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)
            }
            .padding(.vertical, Spacing.sm)
            
            // MARK: - Recent Responses Section
            if !store.guests.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Section divider
                    NativeDividerStyle(opacity: 0.3)
                        .padding(.vertical, Spacing.sm)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: hasAppeared)

                    // Section header
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.Guest.confirmed)
                        
                        Text("Recent Responses")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundColor(Color(nsColor: .labelColor))
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)

                    // Guest rows
                    ForEach(Array(store.guests.prefix(8).enumerated()), id: \.element.id) { index, guest in
                        NativeGuestRow(guest: guest) {
                            selectedGuestId = guest.id
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.45 + Double(index) * 0.04), value: hasAppeared)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: Spacing.md) {
                    NativeDividerStyle(opacity: 0.3)
                        .padding(.vertical, Spacing.sm)
                    
                    VStack(spacing: Spacing.sm) {
                        // Info icon with gradient
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppColors.Guest.confirmed.opacity(0.15),
                                            AppColors.Guest.confirmed.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AppColors.Guest.confirmed,
                                            AppColors.Guest.confirmed.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .shadow(color: AppColors.Guest.confirmed.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Text("No guests added yet")
                            .font(Typography.caption)
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: hasAppeared)
            }
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 407)
        // Native macOS card styling
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.4 : 0.3),
                            Color.white.opacity(isHovered ? 0.15 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        // Multi-layer macOS shadows
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 0.5)
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.05), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        .shadow(color: Color.black.opacity(isHovered ? 0.04 : 0.02), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
        // Hover interaction
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
        .sheet(item: $selectedGuestId) { guestId in
            GuestDetailViewV4(guestId: guestId, guestStore: store)
                .environmentObject(settingsStore)
                .environmentObject(budgetStore)
                .environmentObject(coordinator)
        }
    }
}

// MARK: - Native Stat Column Component

private struct NativeStatColumn: View {
    let value: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Icon and value
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)

                Text("\(value)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text(label)
                .font(Typography.caption)
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Native Guest Row Component

private struct NativeGuestRow: View {
    let guest: Guest
    let action: () -> Void
    @State private var avatarImage: NSImage?
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
            // Avatar with native styling
            avatarView
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")

            Text(guest.fullName)
                .font(Typography.caption)
                .foregroundColor(Color(nsColor: .labelColor))
                .lineLimit(1)

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: statusColor.opacity(0.5), radius: 2, x: 0, y: 0)
                
                Text(statusText)
                    .font(Typography.caption2.weight(.medium))
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(statusColor.opacity(0.1))
            )
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .background(
        RoundedRectangle(cornerRadius: CornerRadius.md)
        .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
        isHovered = hovering
        }
        .accessibleActionButton(
        label: "View details for \(guest.fullName)",
        hint: "Opens guest detail modal",
        isDestructive: false
        )
        }

    private var statusText: String {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return "Attending"
        case .declined:
            return "Declined"
        default:
            return "Pending"
        }
    }

    private var statusColor: Color {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return SemanticColors.success
        case .declined:
            return SemanticColors.error
        default:
            return SemanticColors.warning
        }
    }

    // MARK: - Avatar View

    @ViewBuilder
    private var avatarView: some View {
        if let image = avatarImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        } else {
            // Fallback to initials with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [statusColor.opacity(0.2), statusColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay {
                    Text(guestInitials)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var guestInitials: String {
        let first = guest.firstName.prefix(1).uppercased()
        let last = guest.lastName.prefix(1).uppercased()
        return first + last
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 64, height: 64) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarService
        }
    }
}

// MARK: - Preview

#Preview("Guest Responses V6 - Light") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        GuestResponsesCardV6(
            store: GuestStoreV2()
        )
        .frame(width: 400, height: 500)
        .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Guest Responses V6 - Dark") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        GuestResponsesCardV6(
            store: GuestStoreV2()
        )
        .frame(width: 400, height: 500)
        .padding()
    }
    .preferredColorScheme(.dark)
}
