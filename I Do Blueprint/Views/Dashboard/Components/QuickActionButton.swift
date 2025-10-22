//
//  QuickActionButton.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct DashboardQuickActionButton: View {
    private let logger = AppLogger.ui
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            .linearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: color.opacity(isHovered ? 0.4 : 0.2),
                            radius: isHovered ? 12 : 8,
                            x: 0,
                            y: isHovered ? 6 : 4)

                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isHovered ? color.opacity(0.3) : Color.gray.opacity(0.1),
                        lineWidth: isHovered ? 2 : 1))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        DashboardQuickActionButton(
            icon: "plus.circle.fill",
            title: "Add Task",
            color: .blue) {
            // TODO: Implement action - print("Add Task")
        }

        DashboardQuickActionButton(
            icon: "note.text.badge.plus",
            title: "New Note",
            color: .green) {
            // TODO: Implement action - print("New Note")
        }

        DashboardQuickActionButton(
            icon: "calendar.badge.plus",
            title: "Add Event",
            color: .orange) {
            // TODO: Implement action - print("Add Event")
        }

        DashboardQuickActionButton(
            icon: "person.crop.circle.badge.plus",
            title: "Add Guest",
            color: .purple) {
            // TODO: Implement action - print("Add Guest")
        }
    }
    .padding()
    .frame(width: 800)
}
