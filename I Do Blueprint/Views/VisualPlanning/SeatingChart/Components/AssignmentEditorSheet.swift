//
//  AssignmentEditorSheet.swift
//  I Do Blueprint
//
//  Sheet view for editing seating assignments
//

import SwiftUI

struct AssignmentEditorSheet: View {
    @Binding var assignment: SeatingAssignment
    let guests: [SeatingGuest]
    let tables: [Table]
    let assignments: [SeatingAssignment]
    let onSave: (SeatingAssignment) -> Void
    let onDismiss: () -> Void

    @State private var selectedGuestId: UUID
    @State private var selectedTableId: UUID
    @State private var seatNumber: String
    @State private var notes: String
    @State private var guestSearchText = ""
    @State private var tableSearchText = ""
    @State private var showValidationError = false
    @State private var validationMessage = ""

    init(
        assignment: Binding<SeatingAssignment>,
        guests: [SeatingGuest],
        tables: [Table],
        assignments: [SeatingAssignment],
        onSave: @escaping (SeatingAssignment) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _assignment = assignment
        self.guests = guests
        self.tables = tables
        self.assignments = assignments
        self.onSave = onSave
        self.onDismiss = onDismiss

        // Initialize state from assignment
        _selectedGuestId = State(initialValue: assignment.wrappedValue.guestId)
        _selectedTableId = State(initialValue: assignment.wrappedValue.tableId)
        _seatNumber = State(initialValue: assignment.wrappedValue.seatNumber.map { String($0) } ?? "")
        _notes = State(initialValue: assignment.wrappedValue.notes)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Seating Assignment")
                        .font(Typography.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .accessibleHeading(level: 1)

                    if let guest = selectedGuest {
                        Text("Assigning \(guest.fullName)")
                            .font(Typography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: Spacing.md) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .accessibleActionButton(
                        label: "Cancel editing",
                        hint: "Discards changes and closes the editor"
                    )

                    Button("Save") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .accessibleActionButton(
                        label: "Save assignment",
                        hint: isValid ? "Saves changes and closes the editor" : "Cannot save: \(validationMessage)"
                    )
                }
            }
            .padding(Spacing.lg)

            Divider()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Guest Selection Card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Guest")
                            .font(Typography.heading)
                            .foregroundColor(AppColors.textPrimary)
                            .accessibleHeading(level: 2)

                        Divider()

                        // Search
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textSecondary)
                            TextField("Search guests...", text: $guestSearchText)
                                .textFieldStyle(.plain)
                                .accessibleFormField(
                                    label: "Search guests",
                                    hint: "Filter guests by name"
                                )
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(AppColors.backgroundSecondary)
                        )

                        // Guest List
                        ScrollView {
                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(filteredGuests) { guest in
                                    GuestSelectionRow(
                                        guest: guest,
                                        isSelected: guest.id == selectedGuestId,
                                        onSelect: {
                                            selectedGuestId = guest.id
                                        }
                                    )
                                }

                                if filteredGuests.isEmpty {
                                    Text("No guests found")
                                        .font(Typography.bodySmall)
                                        .foregroundColor(AppColors.textSecondary)
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
                            .fill(AppColors.cardBackground)
                            .shadow(
                                color: AppColors.shadowLight,
                                radius: ShadowStyle.light.radius,
                                x: 0,
                                y: 2
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(AppColors.borderLight, lineWidth: 1)
                    )

                    // Table Selection Card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Table")
                                .font(Typography.heading)
                                .foregroundColor(AppColors.textPrimary)
                                .accessibleHeading(level: 2)

                            Spacer()

                            if let table = selectedTable {
                                Text("\(availableSeats(for: table)) / \(table.capacity) available")
                                    .font(Typography.bodySmall)
                                    .foregroundColor(availableSeats(for: table) > 0 ? AppColors.success : AppColors.error)
                            }
                        }

                        Divider()

                        // Search
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textSecondary)
                            TextField("Search tables...", text: $tableSearchText)
                                .textFieldStyle(.plain)
                                .accessibleFormField(
                                    label: "Search tables",
                                    hint: "Filter tables by number"
                                )
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(AppColors.backgroundSecondary)
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
                                        .foregroundColor(AppColors.textSecondary)
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
                            .fill(AppColors.cardBackground)
                            .shadow(
                                color: AppColors.shadowLight,
                                radius: ShadowStyle.light.radius,
                                x: 0,
                                y: 2
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(AppColors.borderLight, lineWidth: 1)
                    )

                    // Additional Details Card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Additional Details")
                            .font(Typography.heading)
                            .foregroundColor(AppColors.textPrimary)
                            .accessibleHeading(level: 2)

                        Divider()

                        // Seat Number
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Seat Number (Optional)")
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(.uppercase)

                            HStack {
                                TextField("Seat number", text: $seatNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    .accessibleFormField(
                                        label: "Seat number",
                                        hint: "Optional specific seat number at the table"
                                    )

                                if let table = selectedTable {
                                    Text("(1-\(table.capacity))")
                                        .font(Typography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }

                        Divider()

                        // Notes
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Notes")
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(.uppercase)

                            TextEditor(text: $notes)
                                .frame(height: 80)
                                .padding(Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                                .accessibleFormField(
                                    label: "Assignment notes",
                                    hint: "Optional notes about this seating assignment"
                                )
                        }

                        // Guest Info
                        if let guest = selectedGuest {
                            Divider()

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Guest Information")
                                    .font(Typography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textSecondary)
                                    .textCase(.uppercase)

                                if !guest.dietaryRestrictions.isEmpty {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.textSecondary)
                                        Text("Dietary: \(guest.dietaryRestrictions)")
                                            .font(Typography.bodySmall)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }

                                if let accessibility = guest.accessibility,
                                   accessibility.wheelchairAccessible || accessibility.mobilityLimited {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "figure.roll")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.info)
                                        Text("Accessibility needs")
                                            .font(Typography.bodySmall)
                                            .foregroundColor(AppColors.info)
                                    }
                                }

                                if !guest.specialRequests.isEmpty {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "star")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.textSecondary)
                                        Text("Special: \(guest.specialRequests)")
                                            .font(Typography.bodySmall)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(AppColors.cardBackground)
                            .shadow(
                                color: AppColors.shadowLight,
                                radius: ShadowStyle.light.radius,
                                x: 0,
                                y: 2
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(AppColors.borderLight, lineWidth: 1)
                    )

                    // Validation Error
                    if showValidationError {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppColors.error)
                            Text(validationMessage)
                                .font(Typography.bodySmall)
                                .foregroundColor(AppColors.error)
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(AppColors.errorLight)
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Validation error: \(validationMessage)")
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .frame(minWidth: 700, minHeight: 700)
    }

    // MARK: - Computed Properties

    private var selectedGuest: SeatingGuest? {
        guests.first { $0.id == selectedGuestId }
    }

    private var selectedTable: Table? {
        tables.first { $0.id == selectedTableId }
    }

    private var filteredGuests: [SeatingGuest] {
        if guestSearchText.isEmpty {
            return guests
        }
        return guests.filter { guest in
            guest.firstName.localizedCaseInsensitiveContains(guestSearchText) ||
            guest.lastName.localizedCaseInsensitiveContains(guestSearchText)
        }
    }

    private var filteredTables: [Table] {
        var result = tables

        if !tableSearchText.isEmpty {
            result = result.filter { table in
                String(table.tableNumber).contains(tableSearchText) ||
                (table.tableName?.localizedCaseInsensitiveContains(tableSearchText) ?? false)
            }
        }

        // Sort by availability
        result.sort { availableSeats(for: $0) > availableSeats(for: $1) }

        return result
    }

    private var isValid: Bool {
        guests.contains { $0.id == selectedGuestId } &&
        tables.contains { $0.id == selectedTableId } &&
        (seatNumber.isEmpty || isValidSeatNumber)
    }

    private var isValidSeatNumber: Bool {
        guard let number = Int(seatNumber),
              let table = selectedTable else {
            return false
        }
        return number >= 1 && number <= table.capacity
    }

    // MARK: - Helper Methods

    private func availableSeats(for table: Table) -> Int {
        let assigned = assignedGuestsCount(for: table)
        // Don't count the current assignment being edited
        let adjustment = (table.id == assignment.tableId) ? 1 : 0
        return max(0, table.capacity - assigned + adjustment)
    }

    private func assignedGuestsCount(for table: Table) -> Int {
        assignments.filter { $0.tableId == table.id }.count
    }

    private func nextAvailableSeat(for table: Table) -> Int {
        let usedSeats = Set(
            assignments
                .filter { $0.tableId == table.id && $0.id != assignment.id }
                .compactMap(\.seatNumber)
        )

        for seat in 1...table.capacity {
            if !usedSeats.contains(seat) {
                return seat
            }
        }

        return 1
    }

    // MARK: - Validation

    private func validate() -> Bool {
        guard guests.contains(where: { $0.id == selectedGuestId }) else {
            validationMessage = "Please select a valid guest"
            showValidationError = true
            return false
        }

        guard tables.contains(where: { $0.id == selectedTableId }) else {
            validationMessage = "Please select a valid table"
            showValidationError = true
            return false
        }

        if !seatNumber.isEmpty {
            guard let number = Int(seatNumber) else {
                validationMessage = "Seat number must be a valid number"
                showValidationError = true
                return false
            }

            guard let table = selectedTable else {
                validationMessage = "Please select a table first"
                showValidationError = true
                return false
            }

            guard number >= 1 && number <= table.capacity else {
                validationMessage = "Seat number must be between 1 and \(table.capacity)"
                showValidationError = true
                return false
            }
        }

        showValidationError = false
        return true
    }

    // MARK: - Actions

    private func saveChanges() {
        guard validate() else { return }

        var updatedAssignment = assignment
        updatedAssignment.guestId = selectedGuestId
        updatedAssignment.tableId = selectedTableId
        updatedAssignment.seatNumber = seatNumber.isEmpty ? nil : Int(seatNumber)
        updatedAssignment.notes = notes

        onSave(updatedAssignment)
    }
}

// MARK: - Guest Selection Row

private struct GuestSelectionRow: View {
    let guest: SeatingGuest
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(guest.relationship.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(guest.initials)
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(guest.relationship.color)
                }

                // Guest Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(guest.fullName)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)

                    Text(guest.relationship.displayName)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? AppColors.primaryLight : (isHovering ? AppColors.hoverBackground : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .animation(AnimationStyle.fast, value: isHovering)
            .animation(AnimationStyle.fast, value: isSelected)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .buttonStyle(.plain)
        .accessibleActionButton(
            label: guest.fullName,
            hint: isSelected ? "Currently selected" : "Select this guest"
        )
    }
}

// MARK: - Table Selection Row

private struct TableSelectionRow: View {
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
                        .fill(isFull ? AppColors.errorLight : AppColors.primaryLight)
                        .frame(width: 40, height: 40)

                    Text("\(table.tableNumber)")
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(isFull ? AppColors.error : AppColors.primary)
                }

                // Table Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Table \(table.tableNumber)")
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textPrimary)

                        if isFull {
                            Text("FULL")
                                .font(Typography.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.error)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(AppColors.errorLight)
                                )
                        }
                    }

                    Text("\(assignedCount) / \(table.capacity) seats • \(availableSeats) available")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? AppColors.primaryLight : (isHovering ? AppColors.hoverBackground : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
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
    @Previewable @State var assignment = SeatingAssignment(
        guestId: UUID(),
        tableId: UUID()
    )

    let sampleGuests = [
        SeatingGuest(firstName: "John", lastName: "Doe", relationship: .friend),
        SeatingGuest(firstName: "Jane", lastName: "Smith", relationship: .family),
    ]

    let sampleTables = [
        Table(tableNumber: 1, shape: .round, capacity: 8),
        Table(tableNumber: 2, shape: .rectangular, capacity: 10),
    ]

    return AssignmentEditorSheet(
        assignment: $assignment,
        guests: sampleGuests,
        tables: sampleTables,
        assignments: [],
        onSave: { _ in },
        onDismiss: { }
    )
}
