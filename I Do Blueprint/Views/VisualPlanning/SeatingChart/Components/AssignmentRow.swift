//
//  AssignmentRow.swift
//  I Do Blueprint
//
//  Display seating assignment with guest and table information
//

import SwiftUI

struct SeatingAssignmentRow: View {
    let assignment: SeatingAssignment
    let guest: SeatingGuest
    let table: Table
    let onEdit: () -> Void
    let onRemove: () -> Void

    @State private var showingRemoveConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Guest avatar
            ZStack {
                Circle()
                    .fill(guest.relationship.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text(guest.initials)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(guest.relationship.color)
            }

            // Guest and table info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(guest.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if guest.isVIP {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.yellow)
                    }
                }

                HStack(spacing: 8) {
                    // Table info
                    HStack(spacing: 4) {
                        Image(systemName: "tablecells")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)

                        Text("Table \(table.tableNumber)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    // Seat number if assigned
                    if let seatNumber = assignment.seatNumber {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Seat \(seatNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Notes indicator
                    if !assignment.notes.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Image(systemName: "note.text")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                            .help(assignment.notes)
                    }
                }
            }

            Spacer()

            // Assignment metadata
            VStack(alignment: .trailing, spacing: 2) {
                Text(assignment.assignedAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(assignment.assignedBy)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Action buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Edit assignment")

                Button(action: { showingRemoveConfirmation = true }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Remove assignment")
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
        .alert("Remove Assignment", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive, action: onRemove)
        } message: {
            Text("Are you sure you want to remove \(guest.fullName) from Table \(table.tableNumber)?")
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        // Basic assignment
        SeatingAssignmentRow(
            assignment: SeatingAssignment(
                guestId: UUID(),
                tableId: UUID(),
                seatNumber: 3
            ),
            guest: SeatingGuest(
                firstName: "Emily",
                lastName: "Davis",
                email: "emily@example.com",
                relationship: .friend,
                group: "Work Friends",
                isVIP: false
            ),
            table: Table(tableNumber: 7, shape: .round, capacity: 8),
            onEdit: { print("Edit tapped") },
            onRemove: { print("Remove tapped") }
        )

        // VIP assignment with notes
        SeatingAssignmentRow(
            assignment: {
                var assignment = SeatingAssignment(
                    guestId: UUID(),
                    tableId: UUID(),
                    seatNumber: 1
                )
                assignment.notes = "Needs to be near the aisle for easy access"
                return assignment
            }(),
            guest: SeatingGuest(
                firstName: "Michael",
                lastName: "Brown",
                email: "michael@example.com",
                relationship: .family,
                group: "Immediate Family",
                isVIP: true
            ),
            table: {
                var table = Table(tableNumber: 1, shape: .rectangular, capacity: 10)
                table.tableName = "Head Table"
                return table
            }(),
            onEdit: { print("Edit tapped") },
            onRemove: { print("Remove tapped") }
        )

        // Assignment without seat number
        SeatingAssignmentRow(
            assignment: SeatingAssignment(
                guestId: UUID(),
                tableId: UUID(),
                seatNumber: nil
            ),
            guest: SeatingGuest(
                firstName: "Jessica",
                lastName: "Wilson",
                email: "jessica@example.com",
                relationship: .brideSide,
                group: "Bride's Friends",
                isVIP: false
            ),
            table: Table(tableNumber: 12, shape: .round, capacity: 6),
            onEdit: { print("Edit tapped") },
            onRemove: { print("Remove tapped") }
        )
    }
    .padding()
    .frame(width: 500)
}
