//
//  BudgetInputsSection.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct BudgetInputsSection: View {
    @Binding var calculationStartDate: Date?
    @Binding var partner1Monthly: Double
    @Binding var partner2Monthly: Double
    let hasUnsavedChanges: Bool
    let weddingDate: Date?
    let partner1Name: String
    let partner2Name: String
    let onFieldChanged: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Budget Inputs")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter your financial information to calculate affordability")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Date Inputs
            VStack(alignment: .leading, spacing: 16) {
                // Wedding Date (from Settings)
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Wedding Date")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    if let weddingDate = weddingDate {
                        Text(weddingDate, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Set in Settings")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Divider()

                // Calculation Start Date
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.secondary)
                    Text("Calculation Start Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                DatePicker("", selection: Binding(
                    get: { calculationStartDate ?? Date() },
                    set: { calculationStartDate = $0 }
                ), displayedComponents: .date)
                    .datePickerStyle(.field)
                    .labelsHidden()
                    .onChange(of: calculationStartDate) { _, _ in
                        onFieldChanged()
                    }
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Monthly Contributions
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    // Partner 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(partner1Name) Monthly")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 4) {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("1200", text: Binding(
                                get: { String(format: "%.0f", partner1Monthly) },
                                set: { partner1Monthly = Double($0) ?? 0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .onChange(of: partner1Monthly) { _, _ in
                                    onFieldChanged()
                                }
                        }
                    }

                    // Partner 2
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(partner2Name) Monthly")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 4) {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("1300", text: Binding(
                                get: { String(format: "%.0f", partner2Monthly) },
                                set: { partner2Monthly = Double($0) ?? 0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .onChange(of: partner2Monthly) { _, _ in
                                    onFieldChanged()
                                }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Save Button
            if hasUnsavedChanges {
                Button(action: onSave) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Changes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
