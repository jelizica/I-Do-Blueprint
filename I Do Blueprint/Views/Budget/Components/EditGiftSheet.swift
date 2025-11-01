//
//  EditGiftSheet.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct EditGiftSheet: View {
    @Environment(\.dismiss) private var dismiss
    let gift: GiftOrOwed
    let onSave: (GiftOrOwed) -> Void
    let onCancel: () -> Void

    @State private var editedTitle: String
    @State private var editedAmount: String
    @State private var editedType: GiftOrOwed.GiftOrOwedType
    @State private var editedDescription: String
    @State private var editedFromPerson: String
    @State private var editedExpectedDate: Date?
    @State private var editedReceivedDate: Date?
    @State private var editedStatus: GiftOrOwed.GiftOrOwedStatus

    init(gift: GiftOrOwed, onSave: @escaping (GiftOrOwed) -> Void, onCancel: @escaping () -> Void) {
        self.gift = gift
        self.onSave = onSave
        self.onCancel = onCancel

        _editedTitle = State(initialValue: gift.title)
        _editedAmount = State(initialValue: String(format: "%.2f", gift.amount))
        _editedType = State(initialValue: gift.type)
        _editedDescription = State(initialValue: gift.description ?? "")
        _editedFromPerson = State(initialValue: gift.fromPerson ?? "")
        _editedExpectedDate = State(initialValue: gift.expectedDate)
        _editedReceivedDate = State(initialValue: gift.receivedDate)
        _editedStatus = State(initialValue: gift.status)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Gift/Contribution")
                .font(.title2)
                .fontWeight(.bold)

            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Gift title", text: $editedTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    // From Person
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From Person")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Person's name", text: $editedFromPerson)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("0.00", text: $editedAmount)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Picker("Type", selection: $editedType) {
                            ForEach(GiftOrOwed.GiftOrOwedType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Picker("Status", selection: $editedStatus) {
                            ForEach(GiftOrOwed.GiftOrOwedStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Expected Date
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Has Expected Date", isOn: Binding(
                            get: { editedExpectedDate != nil },
                            set: { if $0 { editedExpectedDate = Date() } else { editedExpectedDate = nil } }
                        ))
                        if let _ = editedExpectedDate {
                            DatePicker("Expected Date", selection: Binding(
                                get: { editedExpectedDate ?? Date() },
                                set: { editedExpectedDate = $0 }
                            ), displayedComponents: .date)
                            .datePickerStyle(.field)
                        }
                    }

                    // Received Date
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Has Received Date", isOn: Binding(
                            get: { editedReceivedDate != nil },
                            set: { if $0 { editedReceivedDate = Date() } else { editedReceivedDate = nil } }
                        ))
                        if let _ = editedReceivedDate {
                            DatePicker("Received Date", selection: Binding(
                                get: { editedReceivedDate ?? Date() },
                                set: { editedReceivedDate = $0 }
                            ), displayedComponents: .date)
                            .datePickerStyle(.field)
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextEditor(text: $editedDescription)
                            .frame(height: 80)
                            .border(AppColors.textSecondary.opacity(0.3))
                    }
                }
            }
            .frame(maxHeight: 500)

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    let amount = Double(editedAmount) ?? gift.amount
                    let updatedGift = GiftOrOwed(
                        id: gift.id,
                        coupleId: gift.coupleId,
                        title: editedTitle,
                        amount: amount,
                        type: editedType,
                        description: editedDescription.isEmpty ? nil : editedDescription,
                        fromPerson: editedFromPerson.isEmpty ? nil : editedFromPerson,
                        expectedDate: editedExpectedDate,
                        receivedDate: editedReceivedDate,
                        status: editedStatus,
                        scenarioId: gift.scenarioId,
                        createdAt: gift.createdAt,
                        updatedAt: Date()
                    )
                    onSave(updatedGift)
                }
                .buttonStyle(.borderedProminent)
                .disabled(editedTitle.isEmpty || editedAmount.isEmpty)
            }
        }
        .padding(Spacing.xxl)
        .frame(width: 500)
    }
}
