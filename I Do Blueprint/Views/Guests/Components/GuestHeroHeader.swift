//
//  GuestHeroHeader.swift
//  I Do Blueprint
//
//  Hero header component for guest detail view
//

import SwiftUI

struct HeroHeaderView: View {
    let guest: Guest
    var onEdit: (() -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [
                    guest.rsvpStatus.color.opacity(0.3),
                    guest.rsvpStatus.color.opacity(0.1),
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
            
            // Decorative pattern overlay
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height: CGFloat = 280
                    
                    // Diagonal lines pattern
                    for i in stride(from: -100, to: Int(width) + 100, by: 30) {
                        path.move(to: CGPoint(x: CGFloat(i), y: 0))
                        path.addLine(to: CGPoint(x: CGFloat(i) + 100, y: height))
                    }
                }
                .stroke(guest.rsvpStatus.color.opacity(0.05), lineWidth: 1)
            }
            .frame(height: 280)
            
            // Profile content
            VStack(spacing: Spacing.lg) {
                // Avatar with decorative ring
                ZStack {
                    // Outer decorative ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    guest.rsvpStatus.color.opacity(0.5),
                                    guest.rsvpStatus.color.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 128, height: 128)
                    
                    // Avatar circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    guest.rsvpStatus.color.opacity(0.3),
                                    guest.rsvpStatus.color.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(guest.initials)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(guest.rsvpStatus.color)
                        )
                        .shadow(color: guest.rsvpStatus.color.opacity(0.3), radius: 15, y: 5)
                }
                
                // Name and status
                VStack(spacing: Spacing.sm) {
                    Text(guest.fullName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: guest.rsvpStatus.iconName)
                            .font(.caption)
                        Text(guest.rsvpStatus.displayName)
                            .font(Typography.subheading)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        Capsule()
                            .fill(guest.rsvpStatus.color.opacity(0.15))
                    )
                    .foregroundColor(guest.rsvpStatus.color)
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .overlay(alignment: .topTrailing) {
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 36, height: 36)
                        )
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
    }
}
