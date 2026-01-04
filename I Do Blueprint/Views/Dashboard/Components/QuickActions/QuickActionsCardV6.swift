//
//  QuickActionsCardV6.swift
//  I Do Blueprint
//
//  V6 quick actions card with native macOS materials and premium visual effects
//  Features:
//  - .regularMaterial background for vibrancy
//  - Gradient border stroke for depth
//  - Multi-layer macOS shadows
//  - Hover elevation with spring animations
//  - NativeDividerStyle for consistent dividers
//

import SwiftUI

struct QuickActionsCardV6: View {
    @State private var isHovered = false
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            Text("Quick Actions")
                .font(Typography.subheading)
                .fontWeight(.semibold)
                .foregroundColor(Color(nsColor: .labelColor))
                .padding(.bottom, Spacing.sm)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : -10)

            // Native gradient divider
            NativeDividerStyle(opacity: 0.4)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)

            // Action buttons
            HStack(spacing: Spacing.lg) {
                DashboardV4QuickActionButtonV6(
                    icon: "envelope.fill",
                    title: "Send Invites",
                    color: QuickActions.guest
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)

                DashboardV4QuickActionButtonV6(
                    icon: "calendar.badge.plus",
                    title: "Add Event",
                    color: QuickActions.event
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)

                DashboardV4QuickActionButtonV6(
                    icon: "dollarsign.circle.fill",
                    title: "Update Budget",
                    color: QuickActions.budget
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)

                DashboardV4QuickActionButtonV6(
                    icon: "person.badge.plus",
                    title: "Find Vendors",
                    color: QuickActions.vendor
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: hasAppeared)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        // V6 styling: .regularMaterial background with gradient border
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
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
        // Hover elevation with spring animation
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
    }
}

// MARK: - V6 Quick Action Button

struct DashboardV4QuickActionButtonV6: View {
    let icon: String
    let title: String
    let color: Color
    
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon with gradient
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(title)
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(Color(nsColor: .labelColor))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        // V6 button styling with material background
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(isHovered ? 0.15 : 0.1),
                            color.opacity(isHovered ? 0.08 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(isHovered ? 0.4 : 0.3),
                            color.opacity(isHovered ? 0.2 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        // Subtle shadow with color glow
        .shadow(color: color.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 6 : 3, x: 0, y: isHovered ? 3 : 2)
        // Hover scale animation
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibleActionButton(
            label: title,
            hint: "Tap to \(title.lowercased())"
        )
    }
}

// MARK: - Preview

#Preview("Quick Actions V6 - Light") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        QuickActionsCardV6()
            .frame(width: 900)
            .padding()
    }
    .frame(width: 1000, height: 300)
    .preferredColorScheme(.light)
}

#Preview("Quick Actions V6 - Dark") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        QuickActionsCardV6()
            .frame(width: 900)
            .padding()
    }
    .frame(width: 1000, height: 300)
    .preferredColorScheme(.dark)
}
