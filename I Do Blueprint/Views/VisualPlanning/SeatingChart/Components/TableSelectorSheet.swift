//
//  TableSelectorSheet.swift
//  I Do Blueprint
//
//  Sheet view for selecting a table when assigning a guest
//

import SwiftUI

struct TableSelectorSheet: View {
    let guest: SeatingGuest
    let tables: [Table]
    let assignments: [SeatingAssignment]
    let onSelectTable: (Table) -> Void
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var filterByAvailability = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Table for \(guest.fullName)")
                        .font(Typography.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .accessibleHeading(level: 1)
                    
                    Text("Choose a table with available seats")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .accessibleActionButton(
                    label: "Cancel table selection",
                    hint: "Closes the table selector without assigning a table"
                )
            }
            .padding(Spacing.lg)
            
            Divider()
            
            // Filters
            HStack(spacing: Spacing.md) {
                // Search
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
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
                        .fill(AppColors.cardBackground)
                )
                
                // Filter toggle
                Toggle(isOn: $filterByAvailability) {
                    Text("Available only")
                        .font(Typography.bodySmall)
                }
                .toggleStyle(.switch)
                .accessibleFormField(
                    label: "Filter by availability",
                    hint: "Show only tables with available seats"
                )
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            
            Divider()
            
            // Table List
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(filteredTables) { table in
                        TableCard(
                            table: table,
                            availableSeats: availableSeats(for: table),
                            assignedGuestsCount: assignedGuestsCount(for: table),
                            onSelect: {
                                onSelectTable(table)
                            }
                        )
                    }
                    
                    if filteredTables.isEmpty {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "tablecells.badge.ellipsis")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(emptyStateMessage)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxxl)
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // MARK: - Computed Properties
    
    private var filteredTables: [Table] {
        var result = tables
        
        // Filter by availability
        if filterByAvailability {
            result = result.filter { availableSeats(for: $0) > 0 }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { table in
                String(table.tableNumber).contains(searchText) ||
                (table.tableName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort by availability (most available first)
        result.sort { availableSeats(for: $0) > availableSeats(for: $1) }
        
        return result
    }
    
    private var emptyStateMessage: String {
        if filterByAvailability && !searchText.isEmpty {
            return "No available tables match '\(searchText)'"
        } else if filterByAvailability {
            return "No tables with available seats"
        } else if !searchText.isEmpty {
            return "No tables match '\(searchText)'"
        } else {
            return "No tables available"
        }
    }
    
    // MARK: - Helper Methods
    
    private func availableSeats(for table: Table) -> Int {
        let assigned = assignedGuestsCount(for: table)
        return max(0, table.capacity - assigned)
    }
    
    private func assignedGuestsCount(for table: Table) -> Int {
        assignments.filter { $0.tableId == table.id }.count
    }
}

// MARK: - Table Card

private struct TableCard: View {
    let table: Table
    let availableSeats: Int
    let assignedGuestsCount: Int
    let onSelect: () -> Void
    
    @State private var isHovering = false
    
    private var isFull: Bool {
        availableSeats == 0
    }
    
    private var fillPercentage: Double {
        guard table.capacity > 0 else { return 0 }
        return Double(assignedGuestsCount) / Double(table.capacity)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.lg) {
                // Table Icon
                ZStack {
                    Circle()
                        .fill(isFull ? AppColors.errorLight : AppColors.primaryLight)
                        .frame(width: 60, height: 60)
                    
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: tableShapeIcon)
                            .font(.system(size: 20))
                            .foregroundColor(isFull ? AppColors.error : AppColors.primary)
                        
                        Text("\(table.tableNumber)")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(isFull ? AppColors.error : AppColors.primary)
                    }
                }
                
                // Table Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Table \(table.tableNumber)")
                            .font(Typography.heading)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let tableName = table.tableName, !tableName.isEmpty {
                            Text("(\(tableName))")
                                .font(Typography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if isFull {
                            Text("FULL")
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.error)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(AppColors.errorLight)
                                )
                        }
                    }
                    
                    HStack(spacing: Spacing.md) {
                        // Capacity info
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "person.2")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                            Text("\(assignedGuestsCount) / \(table.capacity)")
                                .font(Typography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        // Shape
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: tableShapeIcon)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                            Text(table.tableShape.displayName)
                                .font(Typography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Available seats
                        if !isFull {
                            Text("\(availableSeats) seat\(availableSeats == 1 ? "" : "s") available")
                                .font(Typography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.success)
                        }
                    }
                    
                    // Capacity bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(AppColors.borderLight)
                                .frame(height: 4)
                            
                            // Fill
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(isFull ? AppColors.error : AppColors.success)
                                .frame(width: geometry.size.width * fillPercentage, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                
                // Select indicator
                if !isFull {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.cardBackground)
                    .shadow(
                        color: isHovering && !isFull ? AppColors.shadowMedium : AppColors.shadowLight,
                        radius: isHovering && !isFull ? 6 : 3,
                        x: 0,
                        y: isHovering && !isFull ? 3 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        isHovering && !isFull ? AppColors.primary : AppColors.borderLight,
                        lineWidth: isHovering && !isFull ? 2 : 1
                    )
            )
            .scaleEffect(isHovering && !isFull ? 1.01 : 1.0)
            .animation(AnimationStyle.fast, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .buttonStyle(.plain)
        .disabled(isFull)
        .opacity(isFull ? 0.6 : 1.0)
        .accessibleActionButton(
            label: "Table \(table.tableNumber), \(availableSeats) seats available",
            hint: isFull ? "This table is full" : "Select this table to assign \(table.tableName ?? "guest")"
        )
    }
    
    private var tableShapeIcon: String {
        switch table.tableShape {
        case .round:
            return "circle"
        case .rectangular:
            return "rectangle"
        case .square:
            return "square"
        case .oval:
            return "oval"
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleGuest = SeatingGuest(
        firstName: "John",
        lastName: "Doe",
        relationship: .friend
    )
    
    let sampleTables = [
        Table(tableNumber: 1, shape: .round, capacity: 8),
        Table(tableNumber: 2, shape: .rectangular, capacity: 10),
        Table(tableNumber: 3, shape: .square, capacity: 4),
        Table(tableNumber: 4, shape: .oval, capacity: 12),
    ]
    
    let sampleAssignments = [
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[0].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[0].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[0].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[1].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[1].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[2].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[2].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[2].id),
        SeatingAssignment(guestId: UUID(), tableId: sampleTables[2].id),
    ]
    
    return TableSelectorSheet(
        guest: sampleGuest,
        tables: sampleTables,
        assignments: sampleAssignments,
        onSelectTable: { _ in },
        onDismiss: { }
    )
}
