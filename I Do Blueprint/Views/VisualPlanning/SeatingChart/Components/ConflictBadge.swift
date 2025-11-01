//
//  ConflictBadge.swift
//  My Wedding Planning App
//
//  Badge component for displaying conflict and preference information
//

import SwiftUI

struct ConflictBadge: View {
    let title: String
    let count: Int
    var totalCount: Int?
    let icon: String
    let isGood: Bool
    @State private var isHovering = false
    @State private var showingDetails = false

    private var badgeColor: Color {
        isGood ? .green : .red
    }

    var body: some View {
        Button(action: {
            showingDetails.toggle()
        }) {
            HStack(spacing: 12) {
                // Icon with badge background
                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(badgeColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    if let total = totalCount {
                        Text("\(count)/\(total)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    } else {
                        Text("\(count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isHovering ? 1.0 : 0.5)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: .black.opacity(isHovering ? 0.12 : 0.06),
                        radius: isHovering ? 8 : 3,
                        x: 0,
                        y: isHovering ? 4 : 2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(badgeColor.opacity(isHovering ? 0.4 : 0.2), lineWidth: isHovering ? 2 : 1))
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .popover(isPresented: $showingDetails) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text("Click to view details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 200)
        }
    }
}
