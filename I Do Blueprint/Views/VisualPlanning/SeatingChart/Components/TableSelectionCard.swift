//
//  TableSelectionCard.swift
//  I Do Blueprint
//
//  Table selection component with search and availability display
//

import SwiftUI

struct TableSelectionCard: View {
    let tables: [Table]
    let assignments: [SeatingAssignment]
    let currentAssignmentId: UUID
    @Binding var selectedTableId: UUID
    @Binding var searchText: String
    @Binding var seatNumber: String
    
    private var selectedTable: Table? {
        tables.first { $0.id == selectedTableId }
    }
    
    private var filteredTables: [Table] {
        var result = tables

        if !searchText.isEmpty {
            result = result.filter { table in
                String(table.tableNumber).contains(searchText) ||
                (table.tableName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Sort by availability
        result.sort { availableSeats(for: $0) > availableSeats(for: $1) }

        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Table")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                    .accessibleHeading(level: 2)

                Spacer()

                if let table = selectedTable {
                    Text("\(availableSeats(for: table)) / \(table.capacity) available")
                        .font(Typography.bodySmall)
                        .foregroundColor(availableSeats(for: table) > 0 ? SemanticColors.success : SemanticColors.error)
                }
            }

            Divider()

            // Search
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(SemanticColors.textSecondary)
                TextField("Search tables...", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibleFormField(
                        label: "Search tables",
                        hint: "Filter tables by number"
                    )
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(SemanticColors.backgroundSecondary)
            )

            // Table List
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(filteredTables) { table in
                        TableSelectionRow(
                            table: table,
                            availableSeats: availableSeats(for: table),
                            assignedCount: assignedGuestsCount(for: table),
                            isSelected: table.id == selectedTableId,
                            onSelect: {
                                selectedTableId = table.id
                                // Auto-suggest next available seat
                                if seatNumber.isEmpty {
                                    seatNumber = String(nextAvailableSeat(for: table))
                                }
                            }
                        )
                    }

                    if filteredTables.isEmpty {
                        Text("No tables found")
                            .font(Typography.bodySmall)
                            .foregroundColor(SemanticColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.backgroundSecondary)
                .shadow(
                    color: SemanticColors.shadowLight,
                    radius: ShadowStyle.light.radius,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderPrimaryLight, lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func availableSeats(for table: Table) -> Int {
        let assigned = assignedGuestsCount(for: table)
        // Don't count the current assignment being edited
        let adjustment = (table.id == selectedTableId) ? 1 : 0
        return max(0, table.capacity - assigned + adjustment)
    }

    private func assignedGuestsCount(for table: Table) -> Int {
        assignments.filter { $0.tableId == table.id }.count
    }

    private func nextAvailableSeat(for table: Table) -> Int {
        let usedSeats = Set(
            assignments
                .filter { $0.tableId == table.id && $0.id != currentAssignmentId }
                .compactMap(\.seatNumber)
        )

        for seat in 1...table.capacity {
            if !usedSeats.contains(seat) {
                return seat
            }
        }

        return 1
    }
}

// MARK: - Table Selection Row

struct TableSelectionRow: View {
    let table: Table
    let availableSeats: Int
    let assignedCount: Int
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    private var isFull: Bool {
        availableSeats == 0
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Table Icon
                ZStack {
                    Circle()
                        .fill(isFull ? SemanticColors.errorLight : SemanticColors.primaryActionLight)
                        .frame(width: 40, height: 40)

                    Text("\(table.tableNumber)")
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(isFull ? SemanticColors.error : SemanticColors.primaryAction)
                }

                // Table Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Table \(table.tableNumber)")
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textPrimary)

                        if isFull {
                            Text("FULL")
                                .font(Typography.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(SemanticColors.error)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(SemanticColors.errorLight)
                                )
                        }
                    }

                    Text("\(assignedCount) / \(table.capacity) seats • \(availableSeats) available")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(SemanticColors.success)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? SemanticColors.primaryActionLight : (isHovering ? SemanticColors.hover : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? SemanticColors.primaryAction : Color.clear, lineWidth: 2)
            )
            .animation(AnimationStyle.fast, value: isHovering)
            .animation(AnimationStyle.fast, value: isSelected)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .buttonStyle(.plain)
        .opacity(isFull ? 0.6 : 1.0)
        .accessibleActionButton(
            label: "Table \(table.tableNumber), \(availableSeats) seats available",
            hint: isSelected ? "Currently selected" : (isFull ? "This table is full" : "Select this table")
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedId = UUID()
    @Previewable @State var searchText = ""
    @Previewable @State var seatNumber = ""
    
    let sampleTables = [
        Table(tableNumber: 1, shape: .round, capacity: 8),
        Table(tableNumber: 2, shape: .rectangular, capacity: 10),
        Table(tableNumber: 3, shape: .round, capacity: 6),
    ]
    
    let sampleAssignments = [
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[0].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[0].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[1].id),
    ]
    
    TableSelectionCard(
        tables: sampleTables,
        assignments: sampleAssignments,
        currentAssignmentId: sampleAssignments[0].id,
        selectedTableId: $selectedId,
        searchText: $searchText,
        seatNumber: $seatNumber
    )
    .frame(width: 600)
    .padding()
}
