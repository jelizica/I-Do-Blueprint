//
//  AssignmentDetailsCard.swift
//  I Do Blueprint
//
//  Additional details component for seat number, notes, and guest information
//

import SwiftUI

struct AssignmentDetailsCard: View {
    let selectedGuest: SeatingGuest?
    let selectedTable: Table?
    @Binding var seatNumber: String
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Additional Details")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
                .accessibleHeading(level: 2)

            Divider()

            // Seat Number
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Seat Number (Optional)")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textSecondary)
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
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }

            Divider()

            // Notes
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Notes")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textSecondary)
                    .textCase(.uppercase)

                TextEditor(text: $notes)
                    .frame(height: 80)
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 1)
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
                        .foregroundColor(SemanticColors.textSecondary)
                        .textCase(.uppercase)

                    if !guest.dietaryRestrictions.isEmpty {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 12))
                                .foregroundColor(SemanticColors.textSecondary)
                            Text("Dietary: \(guest.dietaryRestrictions)")
                                .font(Typography.bodySmall)
                                .foregroundColor(SemanticColors.textSecondary)
                        }
                    }

                    if let accessibility = guest.accessibility,
                       accessibility.wheelchairAccessible || accessibility.mobilityLimited {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "figure.roll")
                                .font(.system(size: 12))
                                .foregroundColor(SemanticColors.info)
                            Text("Accessibility needs")
                                .font(Typography.bodySmall)
                                .foregroundColor(SemanticColors.info)
                        }
                    }

                    if !guest.specialRequests.isEmpty {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "star")
                                .font(.system(size: 12))
                                .foregroundColor(SemanticColors.textSecondary)
                            Text("Special: \(guest.specialRequests)")
                                .font(Typography.bodySmall)
                                .foregroundColor(SemanticColors.textSecondary)
                        }
                    }
                }
            }
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
}

// MARK: - Preview

#Preview {
    @Previewable @State var seatNumber = "3"
    @Previewable @State var notes = "Close to the dance floor"
    
    let sampleGuest = SeatingGuest(
        firstName: "John",
        lastName: "Doe",
        relationship: .friend
    )
    
    let sampleTable = Table(tableNumber: 5, shape: .round, capacity: 8)
    
    VStack(spacing: Spacing.xl) {
        AssignmentDetailsCard(
            selectedGuest: sampleGuest,
            selectedTable: sampleTable,
            seatNumber: $seatNumber,
            notes: $notes
        )
        
        AssignmentDetailsCard(
            selectedGuest: nil,
            selectedTable: nil,
            seatNumber: $seatNumber,
            notes: $notes
        )
    }
    .frame(width: 600)
    .padding()
}
