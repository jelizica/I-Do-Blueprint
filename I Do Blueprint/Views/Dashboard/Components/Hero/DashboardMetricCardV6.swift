//
//  DashboardMetricCardV6.swift
//  I Do Blueprint
//
//  V6 metric card with native macOS materials and premium visual effects
//  Features:
//  - .regularMaterial background for vibrancy
//  - Gradient border stroke for depth
//  - Multi-layer macOS shadows
//  - Hover elevation with spring animations
//  - NativeIconBadge for consistent icon styling
//

import SwiftUI

struct DashboardMetricCardV6: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    @State private var isHovered = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center) {
                // Native icon badge with V6 styling
                NativeIconBadge(
                    systemName: icon,
                    color: iconColor,
                    size: 48
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : -10)

                Spacer(minLength: Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(value)
                    .font(Typography.numberMedium)
                    .foregroundColor(Color(nsColor: .labelColor))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
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
            withAnimation(.easeOut(duration: 0.4)) {
                hasAppeared = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("\(value), \(subtitle)"))
    }
}

// MARK: - Preview

#Preview("Metric Card V6 - Light") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        HStack(spacing: Spacing.lg) {
            DashboardMetricCardV6(
                icon: "person.2.fill",
                iconColor: AppColors.Guest.confirmed,
                title: "RSVPs",
                value: "45/120",
                subtitle: "75 pending"
            )
            
            DashboardMetricCardV6(
                icon: "briefcase.fill",
                iconColor: AppColors.Vendor.booked,
                title: "Vendors Booked",
                value: "8/12",
                subtitle: "4 pending"
            )
            
            DashboardMetricCardV6(
                icon: "dollarsign.circle.fill",
                iconColor: SemanticColors.success,
                title: "Budget Used",
                value: "65%",
                subtitle: "$15,000 left"
            )
        }
        .padding()
    }
    .frame(width: 1000, height: 200)
    .preferredColorScheme(.light)
}

#Preview("Metric Card V6 - Dark") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        HStack(spacing: Spacing.lg) {
            DashboardMetricCardV6(
                icon: "person.2.fill",
                iconColor: AppColors.Guest.confirmed,
                title: "RSVPs",
                value: "45/120",
                subtitle: "75 pending"
            )
            
            DashboardMetricCardV6(
                icon: "briefcase.fill",
                iconColor: AppColors.Vendor.booked,
                title: "Vendors Booked",
                value: "8/12",
                subtitle: "4 pending"
            )
            
            DashboardMetricCardV6(
                icon: "dollarsign.circle.fill",
                iconColor: SemanticColors.success,
                title: "Budget Used",
                value: "65%",
                subtitle: "$15,000 left"
            )
        }
        .padding()
    }
    .frame(width: 1000, height: 200)
    .preferredColorScheme(.dark)
}
