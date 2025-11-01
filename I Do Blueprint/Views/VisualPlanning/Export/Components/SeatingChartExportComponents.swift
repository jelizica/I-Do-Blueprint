//
//  SeatingChartExportComponents.swift
//  I Do Blueprint
//
//  Seating chart export view components
//

import SwiftUI

// MARK: - Seating Chart Export View

struct SeatingChartExportView: View {
    let chart: SeatingChart

    var body: some View {
        ZStack {
            // Background
            AppColors.textPrimary

            // Tables
            ForEach(chart.tables) { table in
                TableExportView(
                    table: table,
                    assignments: chart.seatingAssignments.filter { $0.tableId == table.id },
                    guests: chart.guests)
            }

            // Title overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chart.chartName)
                            .font(.title)
                            .fontWeight(.bold)

                        if let eventId = chart.eventId {
                            Text("Event ID: \(eventId.uuidString)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("\(chart.guests.count) guests • \(chart.tables.count) tables")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.textPrimary)
                            .shadow(color: .black.opacity(0.1), radius: 4))

                    Spacer()
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Table Export View

struct TableExportView: View {
    let table: Table
    let assignments: [SeatingAssignment]
    let guests: [SeatingGuest]

    @ViewBuilder
    var body: some View {
        ZStack {
            // Table shape
            Group {
                switch table.tableShape {
                case .round:
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))

                case .square:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))

                case .rectangular:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))

                case .oval:
                    Ellipse()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(Ellipse().stroke(Color.blue, lineWidth: 2))
                }
            }
            .frame(width: 100, height: 100)

            // Table number and guest count
            VStack(spacing: 2) {
                Text("Table \(table.tableNumber)")
                    .font(.subheadline)
                    .fontWeight(.bold)

                if !assignments.isEmpty {
                    Text("\(assignments.count)/\(table.capacity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .rotationEffect(.degrees(table.rotation))
        .position(table.position)
    }
}

// MARK: - Guest List Export View

struct GuestListExportView: View {
    let chart: SeatingChart

    private var guestsByTable: [Int: [SeatingGuest]] {
        var result: [Int: [SeatingGuest]] = [:]

        for assignment in chart.seatingAssignments {
            guard let guest = chart.guests.first(where: { $0.id == assignment.guestId }),
                  let table = chart.tables.first(where: { $0.id == assignment.tableId }) else { continue }

            if result[table.tableNumber] == nil {
                result[table.tableNumber] = []
            }
            result[table.tableNumber]?.append(guest)
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Guest Seating List")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(chart.chartName)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(AppColors.textSecondary)
                    .frame(height: 1)
            }

            // Summary
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Guests")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(chart.guests.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Assigned")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(chart.seatingAssignments.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tables")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(chart.tables.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            // Tables and guests
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(chart.tables.sorted(by: { $0.tableNumber < $1.tableNumber }), id: \.id) { table in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Table \(table.tableNumber)")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                if let tableName = table.tableName {
                                    Text("(\(tableName))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                let assignedGuests = guestsByTable[table.tableNumber] ?? []
                                Text("\(assignedGuests.count)/\(table.capacity)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(assignedGuests.count == table.capacity ? .green : .orange)
                            }

                            if let guests = guestsByTable[table.tableNumber], !guests.isEmpty {
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2),
                                    spacing: 4) {
                                    ForEach(guests.sorted(by: { $0.lastName < $1.lastName }), id: \.id) { guest in
                                        HStack {
                                            Circle()
                                                .fill(guest.relationship.color)
                                                .frame(width: 8, height: 8)

                                            Text(guest.fullName)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            } else {
                                Text("No guests assigned")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding()
                        .background(AppColors.textSecondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("My Wedding Planning App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.huge)
        .background(AppColors.textPrimary)
    }
}
