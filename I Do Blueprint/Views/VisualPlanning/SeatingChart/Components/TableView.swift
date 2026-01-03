//
//  TableView.swift
//  My Wedding Planning App
//
//  Table visualization component for seating chart editor
//

import SwiftUI

struct TableView: View {
    let table: Table
    let isSelected: Bool
    let isEditing: Bool
    let scale: CGFloat
    let assignments: [SeatingAssignment]
    let guests: [SeatingGuest]

    var body: some View {
        ZStack {
            // Table shape
            Group {
                switch table.tableShape {
                case .round:
                    Circle()
                        .fill(SemanticColors.textPrimary)
                        .stroke(isSelected ? Color.blue : SemanticColors.textSecondary, lineWidth: 2)
                        .frame(width: 80 * scale, height: 80 * scale)
                case .rectangular:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColors.textPrimary)
                        .stroke(isSelected ? Color.blue : SemanticColors.textSecondary, lineWidth: 2)
                        .frame(width: 120 * scale, height: 60 * scale)
                case .square:
                    Rectangle()
                        .fill(SemanticColors.textPrimary)
                        .stroke(isSelected ? Color.blue : SemanticColors.textSecondary, lineWidth: 2)
                        .frame(width: 80 * scale, height: 80 * scale)
                case .oval:
                    Ellipse()
                        .fill(SemanticColors.textPrimary)
                        .stroke(isSelected ? Color.blue : SemanticColors.textSecondary, lineWidth: 2)
                        .frame(width: 100 * scale, height: 70 * scale)
                }
            }

            // Seat positions around the table
            ForEach(0 ..< table.capacity, id: \.self) { seatIndex in
                let position = table.tableShape == .rectangular
                    ? seatPositionRectangular(for: seatIndex, total: table.capacity, scale: scale)
                    : seatPosition(
                        for: seatAngle(for: seatIndex, total: table.capacity, tableShape: table.tableShape),
                        tableShape: table.tableShape,
                        scale: scale)

                let assignment = assignments.first(where: { $0.tableId == table.id && $0.seatNumber == seatIndex + 1 })
                let guest = assignment.flatMap { a in guests.first(where: { $0.id == a.guestId }) }

                ZStack {
                    Circle()
                        .fill(guest != nil ? Color.blue : SemanticColors.textSecondary.opacity(Opacity.light))
                        .frame(width: 20 * scale, height: 20 * scale)
                        .overlay(
                            Circle()
                                .stroke(SemanticColors.textSecondary, lineWidth: 1))

                    if let guest {
                        Text(guest.initials)
                            .font(.system(size: 8 * scale, weight: .semibold))
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                }
                .offset(x: position.x, y: position.y)
            }

            // Table info - counter-rotate to keep text horizontal
            VStack(spacing: 2) {
                Text("Table \(table.tableNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("\(table.capacity) seats")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if isEditing {
                    Text("✎ Editing")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .rotationEffect(.degrees(-table.rotation)) // Counter-rotate text
        }
    }

    // Calculate the angle for each seat position around the table
    private func seatAngle(for index: Int, total: Int, tableShape: TableShape) -> Double {
        switch tableShape {
        case .round, .oval:
            // Distribute evenly around the circle/oval
            return (Double(index) / Double(total)) * 360.0
        case .rectangular:
            // Not used for rectangular - seats positioned along long sides
            return 0
        case .square:
            // Distribute evenly around the perimeter
            let perimeter = 360.0
            let anglePerSeat = perimeter / Double(total)
            return Double(index) * anglePerSeat
        }
    }

    // Calculate the x,y position for a seat at the given angle
    private func seatPosition(for angle: Double, tableShape: TableShape, scale: CGFloat) -> CGPoint {
        let radians = angle * .pi / 180.0
        let seatOffset: CGFloat = 12 * scale // Distance from edge of table

        switch tableShape {
        case .round:
            let radius = (40 * scale) + seatOffset
            return CGPoint(
                x: radius * CGFloat(cos(radians)),
                y: radius * CGFloat(sin(radians)))
        case .oval:
            let radiusX = (50 * scale) + seatOffset
            let radiusY = (35 * scale) + seatOffset
            return CGPoint(
                x: radiusX * CGFloat(cos(radians)),
                y: radiusY * CGFloat(sin(radians)))
        case .rectangular:
            // Not used - see seatPositionRectangular
            return .zero
        case .square:
            let radius = (40 * scale) + seatOffset
            return CGPoint(
                x: radius * CGFloat(cos(radians)),
                y: radius * CGFloat(sin(radians)))
        }
    }

    // Calculate seat position for rectangular tables (along long sides only)
    private func seatPositionRectangular(for index: Int, total: Int, scale: CGFloat) -> CGPoint {
        let tableWidth: CGFloat = 120 * scale
        let seatOffset: CGFloat = 12 * scale

        let seatsPerSide = total / 2
        let spacing = tableWidth / CGFloat(seatsPerSide + 1)

        if index < seatsPerSide {
            // Top side (left to right)
            let x = -tableWidth / 2 + spacing * CGFloat(index + 1)
            let y = -(30 * scale) - seatOffset
            return CGPoint(x: x, y: y)
        } else {
            // Bottom side (left to right)
            let sideIndex = index - seatsPerSide
            let x = -tableWidth / 2 + spacing * CGFloat(sideIndex + 1)
            let y = (30 * scale) + seatOffset
            return CGPoint(x: x, y: y)
        }
    }
}
