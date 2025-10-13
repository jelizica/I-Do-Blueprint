//
//  AssignedGuestRow.swift
//  My Wedding Planning App
//
//  Row component for displaying assigned guests in table editor
//

import SwiftUI

struct AssignedGuestRow: View {
    let guest: SeatingGuest
    @Binding var assignment: SeatingAssignment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Seat number badge
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)

                Text("\(assignment.seatNumber ?? 0)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let group = guest.group {
                    Text(group)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Seat number stepper
            HStack(spacing: 4) {
                Button {
                    if let current = assignment.seatNumber, current > 1 {
                        assignment.seatNumber = current - 1
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .disabled((assignment.seatNumber ?? 0) <= 1)

                Button {
                    if let current = assignment.seatNumber {
                        assignment.seatNumber = current + 1
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(.blue)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}
