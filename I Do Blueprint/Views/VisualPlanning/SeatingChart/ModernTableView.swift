//
//  ModernTableView.swift
//  My Wedding Planning App
//
//  Enhanced table view with avatars and modern design
//

import SwiftUI

struct ModernTableView: View {
    let table: Table
    let guests: [SeatingGuest]
    let assignments: [SeatingAssignment]
    let isSelected: Bool
    let isEditing: Bool
    let scale: CGFloat
    let showAvatars: Bool

    init(
        table: Table,
        guests: [SeatingGuest],
        assignments: [SeatingAssignment],
        isSelected: Bool = false,
        isEditing: Bool = false,
        scale: CGFloat = 1.0,
        showAvatars: Bool = true
    ) {
        self.table = table
        self.guests = guests
        self.assignments = assignments
        self.isSelected = isSelected
        self.isEditing = isEditing
        self.scale = scale
        self.showAvatars = showAvatars
    }

    var body: some View {
        Group {
            switch table.tableShape {
            case .rectangular:
                RectangularTableView(
                    table: table,
                    guests: guests,
                    assignments: assignments,
                    isSelected: isSelected,
                    isEditing: isEditing,
                    scale: scale,
                    showAvatars: showAvatars
                )
            case .round:
                CircularTableView(
                    table: table,
                    guests: guests,
                    assignments: assignments,
                    isSelected: isSelected,
                    isEditing: isEditing,
                    scale: scale,
                    showAvatars: showAvatars
                )
            case .square:
                SquareTableView(
                    table: table,
                    guests: guests,
                    assignments: assignments,
                    isSelected: isSelected,
                    isEditing: isEditing,
                    scale: scale,
                    showAvatars: showAvatars
                )
            case .oval:
                OvalTableView(
                    table: table,
                    guests: guests,
                    assignments: assignments,
                    isSelected: isSelected,
                    isEditing: isEditing,
                    scale: scale,
                    showAvatars: showAvatars
                )
            }
        }
    }
}

// MARK: - Rectangular Table View

struct RectangularTableView: View {
    let table: Table
    let guests: [SeatingGuest]
    let assignments: [SeatingAssignment]
    let isSelected: Bool
    let isEditing: Bool
    let scale: CGFloat
    let showAvatars: Bool

    private let tableWidth: CGFloat = 200
    private let tableHeight: CGFloat = 80

    var body: some View {
        ZStack {
            // Table surface with gradient
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.seatingCream,
                            Color.seatingLightBlue,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: tableWidth * scale, height: tableHeight * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.seatingAccentTeal : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(
                    color: isSelected ? Color.seatingAccentTeal.opacity(0.3) : .black.opacity(0.1),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )

            // Table number
            Text("TABLE \(table.tableNumber)")
                .font(.tableNumber)
                .foregroundColor(.seatingDeepNavy)
                .rotationEffect(.degrees(-table.rotation)) // Counter-rotate to keep horizontal

            // Guests on long sides
            if showAvatars {
                ForEach(assignments) { assignment in
                    if let guest = guests.first(where: { $0.id == assignment.guestId }) {
                        GuestAvatarView(guest: guest, size: 36 * scale)
                            .offset(guestPosition(for: assignment))
                            .rotationEffect(.degrees(-table.rotation)) // Counter-rotate avatars
                    }
                }
            } else {
                // Show seat indicators without avatars
                ForEach(0 ..< table.capacity, id: \.self) { seatIndex in
                    let assignment = assignments.first(where: { $0.seatNumber == seatIndex + 1 })
                    Circle()
                        .fill(assignment != nil ? Color.seatingSuccess : Color.gray.opacity(0.3))
                        .frame(width: 20 * scale, height: 20 * scale)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(seatPosition(for: seatIndex))
                        .rotationEffect(.degrees(-table.rotation))
                }
            }

            // Editing indicator
            if isEditing {
                VStack {
                    Spacer()
                    Text("✎ EDITING")
                        .font(.seatingLabelBold)
                        .foregroundColor(.seatingAccentTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.seatingAccentTeal.opacity(0.15))
                        .cornerRadius(6)
                        .rotationEffect(.degrees(-table.rotation))
                }
                .frame(height: tableHeight * scale)
            }
        }
    }

    private func guestPosition(for assignment: SeatingAssignment) -> CGSize {
        let seatIndex = (assignment.seatNumber ?? 1) - 1
        return seatPosition(for: seatIndex)
    }

    private func seatPosition(for seatIndex: Int) -> CGSize {
        let seatsPerSide = table.capacity / 2
        let spacing = tableWidth / CGFloat(seatsPerSide + 1)

        if seatIndex < seatsPerSide {
            // Top side (left to right)
            let x = -tableWidth / 2 + spacing * CGFloat(seatIndex + 1)
            let y = -(tableHeight / 2 + 40)
            return CGSize(width: x * scale, height: y * scale)
        } else {
            // Bottom side (left to right)
            let sideIndex = seatIndex - seatsPerSide
            let x = -tableWidth / 2 + spacing * CGFloat(sideIndex + 1)
            let y = (tableHeight / 2 + 40)
            return CGSize(width: x * scale, height: y * scale)
        }
    }
}

// MARK: - Circular Table View

struct CircularTableView: View {
    let table: Table
    let guests: [SeatingGuest]
    let assignments: [SeatingAssignment]
    let isSelected: Bool
    let isEditing: Bool
    let scale: CGFloat
    let showAvatars: Bool

    private let radius: CGFloat = 60

    var body: some View {
        ZStack {
            // Table surface
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.seatingCream,
                            Color.seatingLightBlue,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: radius * 2 * scale, height: radius * 2 * scale)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Color.seatingAccentTeal : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(
                    color: isSelected ? Color.seatingAccentTeal.opacity(0.3) : .black.opacity(0.1),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )

            // Table number
            VStack(spacing: 4) {
                Text("\(table.tableNumber)")
                    .font(.tableNumberLarge)
                    .foregroundColor(.seatingDeepNavy)

                if isEditing {
                    Text("✎")
                        .font(.seatingCaption)
                        .foregroundColor(.seatingAccentTeal)
                }
            }
            .rotationEffect(.degrees(-table.rotation))

            // Guests around the circle
            if showAvatars {
                ForEach(assignments) { assignment in
                    if let guest = guests.first(where: { $0.id == assignment.guestId }) {
                        GuestAvatarView(guest: guest, size: 36 * scale)
                            .offset(guestPosition(for: assignment))
                            .rotationEffect(.degrees(-table.rotation))
                    }
                }
            } else {
                ForEach(0 ..< table.capacity, id: \.self) { seatIndex in
                    let assignment = assignments.first(where: { $0.seatNumber == seatIndex + 1 })
                    Circle()
                        .fill(assignment != nil ? Color.seatingSuccess : Color.gray.opacity(0.3))
                        .frame(width: 20 * scale, height: 20 * scale)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(seatPosition(for: seatIndex))
                        .rotationEffect(.degrees(-table.rotation))
                }
            }
        }
    }

    private func guestPosition(for assignment: SeatingAssignment) -> CGSize {
        let seatIndex = (assignment.seatNumber ?? 1) - 1
        return seatPosition(for: seatIndex)
    }

    private func seatPosition(for seatIndex: Int) -> CGSize {
        let angle = (Double(seatIndex) / Double(table.capacity)) * 360.0
        let radians = angle * .pi / 180.0
        let seatRadius = (radius + 40) * scale

        let x = seatRadius * CGFloat(cos(radians))
        let y = seatRadius * CGFloat(sin(radians))

        return CGSize(width: x, height: y)
    }
}

// MARK: - Square Table View

struct SquareTableView: View {
    let table: Table
    let guests: [SeatingGuest]
    let assignments: [SeatingAssignment]
    let isSelected: Bool
    let isEditing: Bool
    let scale: CGFloat
    let showAvatars: Bool

    private let tableSize: CGFloat = 100

    var body: some View {
        ZStack {
            // Table surface
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.seatingCream,
                            Color.seatingLightBlue,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: tableSize * scale, height: tableSize * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.seatingAccentTeal : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(
                    color: isSelected ? Color.seatingAccentTeal.opacity(0.3) : .black.opacity(0.1),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )

            // Table number
            Text("\(table.tableNumber)")
                .font(.tableNumber)
                .foregroundColor(.seatingDeepNavy)
                .rotationEffect(.degrees(-table.rotation))

            // Guests around perimeter
            if showAvatars {
                ForEach(assignments) { assignment in
                    if let guest = guests.first(where: { $0.id == assignment.guestId }) {
                        GuestAvatarView(guest: guest, size: 36 * scale)
                            .offset(guestPosition(for: assignment))
                            .rotationEffect(.degrees(-table.rotation))
                    }
                }
            }
        }
    }

    private func guestPosition(for assignment: SeatingAssignment) -> CGSize {
        let seatIndex = (assignment.seatNumber ?? 1) - 1
        let seatsPerSide = table.capacity / 4
        let offset = (tableSize / 2 + 40) * scale

        if seatIndex < seatsPerSide {
            // Top side
            return CGSize(width: 0, height: -offset)
        } else if seatIndex < seatsPerSide * 2 {
            // Right side
            return CGSize(width: offset, height: 0)
        } else if seatIndex < seatsPerSide * 3 {
            // Bottom side
            return CGSize(width: 0, height: offset)
        } else {
            // Left side
            return CGSize(width: -offset, height: 0)
        }
    }
}

// MARK: - Oval Table View

struct OvalTableView: View {
    let table: Table
    let guests: [SeatingGuest]
    let assignments: [SeatingAssignment]
    let isSelected: Bool
    let isEditing: Bool
    let scale: CGFloat
    let showAvatars: Bool

    private let radiusX: CGFloat = 80
    private let radiusY: CGFloat = 50

    var body: some View {
        ZStack {
            // Table surface
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.seatingCream,
                            Color.seatingLightBlue,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: radiusX * 2 * scale, height: radiusY * 2 * scale)
                .overlay(
                    Ellipse()
                        .stroke(
                            isSelected ? Color.seatingAccentTeal : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(
                    color: isSelected ? Color.seatingAccentTeal.opacity(0.3) : .black.opacity(0.1),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )

            // Table number
            Text("\(table.tableNumber)")
                .font(.tableNumber)
                .foregroundColor(.seatingDeepNavy)
                .rotationEffect(.degrees(-table.rotation))

            // Guests around the oval
            if showAvatars {
                ForEach(assignments) { assignment in
                    if let guest = guests.first(where: { $0.id == assignment.guestId }) {
                        GuestAvatarView(guest: guest, size: 36 * scale)
                            .offset(guestPosition(for: assignment))
                            .rotationEffect(.degrees(-table.rotation))
                    }
                }
            }
        }
    }

    private func guestPosition(for assignment: SeatingAssignment) -> CGSize {
        let seatIndex = (assignment.seatNumber ?? 1) - 1
        let angle = (Double(seatIndex) / Double(table.capacity)) * 360.0
        let radians = angle * .pi / 180.0

        let x = (radiusX + 40) * CGFloat(cos(radians)) * scale
        let y = (radiusY + 40) * CGFloat(sin(radians)) * scale

        return CGSize(width: x, height: y)
    }
}

#Preview {
    let sampleTable = Table(
        tableNumber: 1,
        position: CGPoint(x: 200, y: 200),
        shape: .rectangular,
        capacity: 8
    )

    let sampleGuests = [
        SeatingGuest(firstName: "John", lastName: "Smith", email: "john@example.com", group: "Family"),
        SeatingGuest(firstName: "Jane", lastName: "Doe", email: "jane@example.com", group: "Friends"),
    ]

    let sampleAssignments = [
        SeatingAssignment(guestId: sampleGuests[0].id, tableId: sampleTable.id, seatNumber: 1),
        SeatingAssignment(guestId: sampleGuests[1].id, tableId: sampleTable.id, seatNumber: 2),
    ]

    VStack(spacing: 40) {
        ModernTableView(
            table: sampleTable,
            guests: sampleGuests,
            assignments: sampleAssignments,
            isSelected: true,
            scale: 1.0
        )

        ModernTableView(
            table: Table(tableNumber: 2, position: .zero, shape: .round, capacity: 8),
            guests: sampleGuests,
            assignments: sampleAssignments,
            isSelected: false,
            scale: 1.0
        )
    }
    .padding()
    .background(Color.white)
}
