//
//  AssignmentEditorSheet.swift
//  I Do Blueprint
//
//  Sheet view for editing seating assignments
//
//  Refactored: Split into focused components to reduce complexity
//  - AssignmentEditorHeader: Header with save/cancel buttons
//  - GuestSelectionCard: Guest selection with search
//  - TableSelectionCard: Table selection with search
//  - AssignmentDetailsCard: Seat number, notes, guest info
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
            AssignmentEditorHeader(
                selectedGuest: selectedGuest,
                isValid: isValid,
                validationMessage: validationMessage,
                onSave: saveChanges,
                onCancel: onDismiss
            )

            Divider()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Guest Selection Card
                    GuestSelectionCard(
                        guests: guests,
                        selectedGuestId: $selectedGuestId,
                        searchText: $guestSearchText
                    )

                    // Table Selection Card
                    TableSelectionCard(
                        tables: tables,
                        assignments: assignments,
                        currentAssignmentId: assignment.id,
                        selectedTableId: $selectedTableId,
                        searchText: $tableSearchText,
                        seatNumber: $seatNumber
                    )

                    // Additional Details Card
                    AssignmentDetailsCard(
                        selectedGuest: selectedGuest,
                        selectedTable: selectedTable,
                        seatNumber: $seatNumber,
                        notes: $notes
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
