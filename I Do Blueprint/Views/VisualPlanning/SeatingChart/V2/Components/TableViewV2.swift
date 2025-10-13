//
//  TableViewV2.swift
//  My Wedding Planning App
//
//  Enhanced table view with avatar positioning for Seating Chart V2
//  Supports all table shapes with proper rotation handling
//

import SwiftUI

/// V2 table view with illustrated guest avatars positioned around the table
struct TableViewV2: View {
    let table: Table
    let assignments: [SeatingAssignment]
    let guests: [SeatingGuest]
    let scale: CGFloat
    let showGuestNames: Bool
    let isSelected: Bool
    let onRotate: ((UUID, Double) -> Void)?
    let onDelete: ((UUID) -> Void)?

    @State private var isHovering = false

    init(
        table: Table,
        assignments: [SeatingAssignment],
        guests: [SeatingGuest],
        scale: CGFloat = 1.0,
        showGuestNames: Bool = true,
        isSelected: Bool = false,
        onRotate: ((UUID, Double) -> Void)? = nil,
        onDelete: ((UUID) -> Void)? = nil
    ) {
        self.table = table
        self.assignments = assignments
        self.guests = guests
        self.scale = scale
        self.showGuestNames = showGuestNames
        self.isSelected = isSelected
        self.onRotate = onRotate
        self.onDelete = onDelete
    }

    // MARK: - Computed Properties

    private var tableSize: CGSize {
        let baseSize = GeometryHelpers.standardTableSize(for: table.tableShape, capacity: table.capacity)
        return CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
    }

    private var avatarSize: CGFloat {
        40 * scale
    }

    private var assignedGuests: [UUID: SeatingGuest] {
        var guestMap: [UUID: SeatingGuest] = [:]
        for guest in guests {
            guestMap[guest.id] = guest
        }
        return guestMap
    }

    private var seatPositions: [CGPoint] {
        GeometryHelpers.seatPositions(
            for: table.tableShape,
            capacity: table.capacity,
            tableSize: tableSize,
            avatarSize: avatarSize,
            rotation: table.rotation
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Table shape
            tableShape
                .stroke(borderColor, lineWidth: borderWidth)
                .background(tableShape.fill(tableFillColor))
                .frame(width: tableSize.width, height: tableSize.height)
                .overlay {
                    // Table number label
                    Text("\(table.tableNumber)")
                        .font(.system(size: 16 * scale, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .rotationEffect(.degrees(table.rotation))

            // Guest avatars positioned around the table
            // Seats rotate WITH the table, but avatars counter-rotate to stay upright
            ForEach(Array(seatPositions.enumerated()), id: \.offset) { index, position in
                if let assignment = assignments.first(where: { $0.seatNumber == index }),
                   let guest = assignedGuests[assignment.guestId] {
                    GuestAvatarViewV2(
                        guest: guest,
                        size: avatarSize,
                        showName: showGuestNames
                    )
                    .rotationEffect(.degrees(-table.rotation)) // Counter-rotate to keep text horizontal
                    .offset(x: position.x, y: position.y)
                    .rotationEffect(.degrees(table.rotation)) // Rotate position around table
                } else {
                    // Empty seat indicator
                    emptySeatView
                        .rotationEffect(.degrees(-table.rotation)) // Counter-rotate to keep upright
                        .offset(x: position.x, y: position.y)
                        .rotationEffect(.degrees(table.rotation)) // Rotate position around table
                }
            }

            // Selection indicator
            if isSelected {
                tableShape
                    .stroke(Color.seatingAccentTeal, lineWidth: 3 * scale)
                    .frame(width: tableSize.width + 6, height: tableSize.height + 6)
                    .rotationEffect(.degrees(table.rotation))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            rotationContextMenu
        }
    }

    // MARK: - Rotation Controls

    @ViewBuilder
    private var rotationContextMenu: some View {
        Button("Rotate 90° Clockwise") {
            rotateTable(by: 90)
        }

        Button("Rotate 90° Counter-Clockwise") {
            rotateTable(by: -90)
        }

        Button("Rotate 45° Clockwise") {
            rotateTable(by: 45)
        }

        Button("Rotate 45° Counter-Clockwise") {
            rotateTable(by: -45)
        }

        Divider()

        Button("Reset Rotation") {
            setRotation(to: 0)
        }

        if onDelete != nil {
            Divider()

            Button("Delete Table") {
                deleteTable()
            }
        }
    }

    private func rotateTable(by degrees: Double) {
        guard let onRotate = onRotate else { return }
        let newRotation = (table.rotation + degrees).truncatingRemainder(dividingBy: 360)
        onRotate(table.id, newRotation)
    }

    private func setRotation(to degrees: Double) {
        guard let onRotate = onRotate else { return }
        onRotate(table.id, degrees)
    }

    private func deleteTable() {
        guard let onDelete = onDelete else { return }
        onDelete(table.id)
    }

    // MARK: - Subviews

    private var tableShape: some Shape {
        switch table.tableShape {
        case .round:
            return AnyShape(Circle())
        case .rectangular:
            return AnyShape(RoundedRectangle(cornerRadius: 8 * scale))
        case .square:
            return AnyShape(RoundedRectangle(cornerRadius: 8 * scale))
        case .oval:
            return AnyShape(Ellipse())
        }
    }

    private var emptySeatView: some View {
        Circle()
            .strokeBorder(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2 * scale, dash: [4 * scale, 4 * scale]))
            .frame(width: avatarSize * 0.8, height: avatarSize * 0.8)
            .overlay {
                Image(systemName: "plus")
                    .font(.system(size: avatarSize * 0.3))
                    .foregroundColor(.gray.opacity(0.5))
            }
    }

    // MARK: - Helper Properties

    private var borderColor: Color {
        if isSelected {
            return .seatingAccentTeal
        } else if isHovering {
            return .primary.opacity(0.6)
        } else {
            return .primary.opacity(0.3)
        }
    }

    private var borderWidth: CGFloat {
        isHovering ? 3 * scale : 2 * scale
    }

    private var tableFillColor: Color {
        if isHovering {
            return Color.seatingCream.opacity(0.8)
        } else {
            return Color.seatingCream.opacity(0.6)
        }
    }
}

// MARK: - AnyShape Helper

/// Type-erased shape for dynamic shape rendering
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct TableViewV2_Previews: PreviewProvider {
    static var testGuests: [SeatingGuest] = [
        SeatingGuest(
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@example.com",
            group: "Bride's Friends"
        ),
        SeatingGuest(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            group: "Family",
            isVIP: true
        ),
        SeatingGuest(
            firstName: "Alice",
            lastName: "Johnson",
            email: "alice@example.com"
        )
    ]

    static var testAssignments: [SeatingAssignment] {
        let tableId = UUID()
        return [
            SeatingAssignment(
                guestId: testGuests[0].id,
                tableId: tableId,
                seatNumber: 0
            ),
            SeatingAssignment(
                guestId: testGuests[1].id,
                tableId: tableId,
                seatNumber: 2
            ),
            SeatingAssignment(
                guestId: testGuests[2].id,
                tableId: tableId,
                seatNumber: 4
            )
        ]
    }

    static var previews: some View {
        VStack(spacing: 50) {
            // Round table
            TableViewV2(
                table: Table(
                    tableNumber: 1,
                    position: .zero,
                    shape: .round,
                    capacity: 8
                ),
                assignments: testAssignments,
                guests: testGuests,
                scale: 1.0,
                showGuestNames: true,
                isSelected: false
            )

            // Rectangular table with rotation
            TableViewV2(
                table: Table(
                    tableNumber: 2,
                    position: .zero,
                    shape: .rectangular,
                    capacity: 10
                ),
                assignments: testAssignments,
                guests: testGuests,
                scale: 1.0,
                showGuestNames: true,
                isSelected: true
            )
        }
        .padding()
        .frame(width: 600, height: 800)
        .previewLayout(.sizeThatFits)
    }
}
#endif
