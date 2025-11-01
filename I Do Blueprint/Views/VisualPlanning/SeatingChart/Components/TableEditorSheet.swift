//
//  TableEditorSheet.swift
//  My Wedding Planning App
//
//  Sheet view for editing table properties and guest assignments
//

import SwiftUI

struct TableEditorSheet: View {
    @Binding var table: Table
    let guests: [SeatingGuest]
    @Binding var assignments: [SeatingAssignment]
    let onRotate: () -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Table \(table.tableNumber)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(assignments.count) of \(table.capacity) seats filled")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            HStack(spacing: 16) {
                // Left: Table Properties Card
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Card wrapper for Table Properties
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Table Properties")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                VStack(alignment: .leading, spacing: 18) {
                                    // Shape
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Shape")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)

                                        VStack(spacing: 6) {
                                            HStack(spacing: 6) {
                                                Button("Round") {
                                                    table.tableShape = .round
                                                }
                                                .buttonStyle(.bordered)
                                                .controlSize(.small)
                                                .background(table.tableShape == .round ? Color.blue.opacity(0.2) : Color
                                                    .clear)

                                                Button("Rectangular") {
                                                    table.tableShape = .rectangular
                                                }
                                                .buttonStyle(.bordered)
                                                .controlSize(.small)
                                                .background(table.tableShape == .rectangular ? Color.blue
                                                    .opacity(0.2) : Color.clear)
                                            }

                                            HStack(spacing: 6) {
                                                Button("Square") {
                                                    table.tableShape = .square
                                                }
                                                .buttonStyle(.bordered)
                                                .controlSize(.small)
                                                .background(table.tableShape == .square ? Color.blue
                                                    .opacity(0.2) : Color.clear)

                                                Button("Oval") {
                                                    table.tableShape = .oval
                                                }
                                                .buttonStyle(.bordered)
                                                .controlSize(.small)
                                                .background(table.tableShape == .oval ? Color.blue.opacity(0.2) : Color
                                                    .clear)
                                            }
                                        }
                                    }

                                    Divider()

                                    // Capacity
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Capacity")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)

                                        HStack {
                                            Button {
                                                if table.capacity > 2 {
                                                    table.capacity -= 1
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(table.capacity <= 2)

                                            Text("\(table.capacity) seats")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .frame(maxWidth: .infinity)

                                            Button {
                                                if table.capacity < 20 {
                                                    table.capacity += 1
                                                }
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(table.capacity >= 20)
                                        }
                                    }

                                    Divider()

                                    // Rotation
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Rotation")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)

                                        VStack(spacing: 8) {
                                            Button {
                                                onRotate()
                                            } label: {
                                                HStack {
                                                    Image(systemName: "arrow.clockwise")
                                                    Text("Rotate 45°")
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)

                                            Text("\(Int(table.rotation))°")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                            }
                            .padding(Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1))
                        }
                        .padding(Spacing.lg)
                    }
                }
                .frame(width: 320)

                Divider()

                // Right: Seat Assignments
                VStack(spacing: 16) {
                    // Search Card
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search guests...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor)))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                    // Assigned guests card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assigned Guests")
                            .font(.headline)

                        if assignments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)

                                Text("No guests assigned")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.huge)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(assignments.indices, id: \.self) { index in
                                        if let guest = guests.first(where: { $0.id == assignments[index].guestId }) {
                                            AssignedGuestRow(
                                                guest: guest,
                                                assignment: $assignments[index],
                                                onRemove: {
                                                    assignments.remove(at: index)
                                                })
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.sm)
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                    .padding(Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal, Spacing.lg)

                    // Available guests card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Guests")
                            .font(.headline)

                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(availableGuests) { guest in
                                    AvailableGuestRow(
                                        guest: guest,
                                        onAdd: {
                                            // Find next available seat number
                                            let usedSeatNumbers = Set(assignments.compactMap(\.seatNumber))
                                            var nextSeatNumber = 1
                                            while usedSeatNumbers.contains(nextSeatNumber),
                                                  nextSeatNumber <= table.capacity {
                                                nextSeatNumber += 1
                                            }

                                            var assignment = SeatingAssignment(
                                                guestId: guest.id,
                                                tableId: table.id)
                                            assignment.seatNumber = nextSeatNumber
                                            assignments.append(assignment)
                                        })
                                }
                            }
                            .padding(.horizontal, Spacing.sm)
                        }
                    }
                    .padding(Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(minWidth: 950, minHeight: 700)
    }

    private var availableGuests: [SeatingGuest] {
        guests.filter { guest in
            !assignments.contains { $0.guestId == guest.id }
        }.filter { guest in
            searchText.isEmpty || guest.firstName.localizedCaseInsensitiveContains(searchText) || guest.lastName
                .localizedCaseInsensitiveContains(searchText)
        }
    }
}
