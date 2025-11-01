//
//  AvailableGuestRow.swift
//  My Wedding Planning App
//
//  Row component for displaying available guests in table editor
//

import SwiftUI

struct AvailableGuestRow: View {
    let guest: SeatingGuest
    let onAdd: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.circle")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.subheadline)

                if let group = guest.group {
                    Text(group)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.sm)
        .background(AppColors.textSecondary.opacity(0.05))
        .cornerRadius(8)
    }
}
