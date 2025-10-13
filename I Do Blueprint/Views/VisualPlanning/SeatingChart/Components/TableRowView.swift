//
//  TableRowView.swift
//  My Wedding Planning App
//
//  Row component for displaying tables in the tables list
//

import SwiftUI

struct TableRowView: View {
    let table: Table
    let isSelected: Bool
    let assignments: [SeatingAssignment]
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    private var assignedCount: Int {
        assignments.count
    }

    private var shapeIcon: String {
        switch table.tableShape {
        case .round: "circle"
        case .rectangular: "rectangle"
        case .square: "square"
        case .oval: "oval"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Shape icon
            Image(systemName: shapeIcon)
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .secondary)
                .frame(width: 40)

            // Table info
            VStack(alignment: .leading, spacing: 4) {
                Text("Table \(table.tableNumber)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .blue : .primary)

                HStack(spacing: 12) {
                    Label("\(assignedCount)/\(table.capacity)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(table.tableShape.displayName, systemImage: shapeIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: CGFloat(assignedCount) / CGFloat(table.capacity))
                    .stroke(
                        assignedCount == table.capacity ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                Text("\(Int((Double(assignedCount) / Double(table.capacity)) * 100))%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
            }

            // Actions (visible on hover)
            if isHovering {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.12 : 0.06), radius: isHovering ? 6 : 3, x: 0, y: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
