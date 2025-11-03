//
//  ObstacleRow.swift
//  I Do Blueprint
//
//  Display and edit venue obstacles in seating chart editor
//

import SwiftUI

struct ObstacleRow: View {
    let obstacle: VenueObstacle
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Obstacle icon
            ZStack {
                Circle()
                    .fill(obstacle.obstacleType.defaultColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: obstacle.obstacleType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(obstacle.obstacleType.defaultColor)
            }

            // Obstacle info
            VStack(alignment: .leading, spacing: 4) {
                Text(obstacle.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(obstacle.obstacleType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(Int(obstacle.size.width)) × \(Int(obstacle.size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if obstacle.isMovable {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Movable")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Edit obstacle")

                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete obstacle")
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 1)
        )
        .alert("Delete Obstacle", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete '\(obstacle.name)'? This action cannot be undone.")
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ObstacleRow(
            obstacle: VenueObstacle(
                name: "Main Bar",
                position: CGPoint(x: 100, y: 100),
                size: CGSize(width: 200, height: 80),
                type: .bar
            ),
            onEdit: { print("Edit tapped") },
            onDelete: { print("Delete tapped") }
        )

        ObstacleRow(
            obstacle: VenueObstacle(
                name: "Dance Floor",
                position: CGPoint(x: 300, y: 300),
                size: CGSize(width: 250, height: 250),
                type: .danceFloor
            ),
            onEdit: { print("Edit tapped") },
            onDelete: { print("Delete tapped") }
        )

        ObstacleRow(
            obstacle: VenueObstacle(
                name: "Support Column",
                position: CGPoint(x: 150, y: 200),
                size: CGSize(width: 50, height: 50),
                type: .column
            ),
            onEdit: { print("Edit tapped") },
            onDelete: { print("Delete tapped") }
        )
    }
    .padding()
    .frame(width: 400)
}
