//
//  SidebarRows.swift
//  I Do Blueprint
//
//  Row components for modern sidebar
//

import SwiftUI

// MARK: - Modern Tab Button

struct ModernTabButton: View {
    let tab: EditorTab
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.body)
                    .foregroundColor(isSelected ? .seatingAccentTeal : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(isSelected ? .seatingBodyBold : .seatingBody)
                        .foregroundColor(isSelected ? .primary : .secondary)

                    if let count {
                        Text("\(count) \(count == 1 ? "item" : "items")")
                            .font(.seatingCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.seatingAccentTeal)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.seatingAccentTeal.opacity(0.12) : (isHovering ? Color.gray.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.seatingAccentTeal.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Modern Table Row

struct ModernTableRow: View {
    let table: Table
    let isSelected: Bool
    let assignmentCount: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: shapeIcon)
                    .foregroundColor(isSelected ? .seatingAccentTeal : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Table \(table.tableNumber)")
                        .font(.seatingBodyBold)
                        .foregroundColor(isSelected ? .seatingAccentTeal : .primary)

                    Text("\(assignmentCount)/\(table.capacity) seats")
                        .font(.seatingCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: CGFloat(assignmentCount) / CGFloat(table.capacity))
                        .stroke(
                            assignmentCount == table.capacity ? Color.seatingSuccess : Color.seatingAccentTeal,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.seatingAccentTeal.opacity(0.1) : Color.white)
            )
        }
        .buttonStyle(.plain)
    }

    private var shapeIcon: String {
        switch table.tableShape {
        case .round: return "circle"
        case .rectangular: return "rectangle"
        case .square: return "square"
        case .oval: return "oval"
        }
    }
}

// MARK: - Guest Group Toggle

struct GuestGroupToggle: View {
    @Binding var group: SeatingGuestGroup
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: group.icon)
                .foregroundColor(group.color)
                .frame(width: 24)

            Text(group.name)
                .font(.seatingBody)

            Spacer()

            Text("\(group.guestIds.count)")
                .font(.seatingCaption)
                .foregroundColor(.secondary)

            Toggle("", isOn: $group.isVisible)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: group.color))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Unassigned Guest Row

struct UnassignedGuestRow: View {
    let guest: SeatingGuest

    var body: some View {
        HStack(spacing: 8) {
            GuestAvatarView(guest: guest, size: 32, showBorder: true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.seatingCaption)

                if let group = guest.group {
                    Text(group)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let guest: SeatingGuest
    let table: Table

    var body: some View {
        HStack(spacing: 12) {
            GuestAvatarView(guest: guest, size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.seatingCaption)

                Text("Table \(table.tableNumber)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Zone Row

struct ZoneRow: View {
    let zone: TableZone

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zone.color)
                .frame(width: 12, height: 12)

            Text(zone.name)
                .font(.seatingCaption)

            Spacer()

            Text("\(zone.tableIds.count)")
                .font(.seatingCaption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Layout Style Row

struct LayoutStyleRow: View {
    let style: RectangularLayoutStyle
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .foregroundColor(.seatingAccentTeal)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.rawValue)
                        .font(.seatingCaption)

                    Text(style.description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(8)
            .background(Color.white)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
