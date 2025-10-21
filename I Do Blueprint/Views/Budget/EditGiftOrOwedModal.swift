import SwiftUI

struct EditGiftOrOwedModal: View {
    let giftOrOwed: GiftOrOwed
    let onSave: (GiftOrOwed) -> Void
    let onDelete: (GiftOrOwed) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedGift: GiftOrOwed
    @State private var showingDeleteAlert = false
    @State private var hasExpectedDate: Bool
    @State private var hasReceivedDate: Bool

    init(giftOrOwed: GiftOrOwed, onSave: @escaping (GiftOrOwed) -> Void, onDelete: @escaping (GiftOrOwed) -> Void) {
        self.giftOrOwed = giftOrOwed
        self.onSave = onSave
        self.onDelete = onDelete
        _editedGift = State(initialValue: giftOrOwed)
        _hasExpectedDate = State(initialValue: giftOrOwed.expectedDate != nil)
        _hasReceivedDate = State(initialValue: giftOrOwed.receivedDate != nil)
    }

    private var isFormValid: Bool {
        !editedGift.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            editedGift.amount > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Details Header
                    detailsHeader

                    // Edit Form
                    editForm

                    // Status Section
                    statusSection

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Edit Gift/Owed Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete(giftOrOwed)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this gift/owed item? This action cannot be undone.")
        }
    }

    // MARK: - View Components

    private var detailsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(editedGift.status.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: editedGift.type.iconName)
                            .foregroundColor(editedGift.status.color)
                            .font(.title2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(editedGift.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(editedGift.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let fromPerson = editedGift.fromPerson, !fromPerson.isEmpty {
                        Text("from \(fromPerson)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberFormatter.currency.string(from: NSNumber(value: editedGift.amount)) ?? "$0")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(editedGift.status.color)

                    Text(editedGift.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(editedGift.status.color.opacity(0.2))
                        .foregroundColor(editedGift.status.color)
                        .clipShape(Capsule())
                }
            }

            if let description = editedGift.description, !description.isEmpty {
                HStack {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var editForm: some View {
        VStack(spacing: 16) {
            Text("Edit Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Title
                HStack {
                    Text("Title")
                        .frame(width: 100, alignment: .leading)
                    TextField("Title", text: $editedGift.title)
                        .textFieldStyle(.roundedBorder)
                }

                // Amount
                HStack {
                    Text("Amount")
                        .frame(width: 100, alignment: .leading)
                    TextField("Amount", value: $editedGift.amount, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                }

                // Type
                HStack {
                    Text("Type")
                        .frame(width: 100, alignment: .leading)
                    Picker("Type", selection: $editedGift.type) {
                        ForEach(GiftOrOwed.GiftOrOwedType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Status
                HStack {
                    Text("Status")
                        .frame(width: 100, alignment: .leading)
                    Picker("Status", selection: $editedGift.status) {
                        ForEach(GiftOrOwed.GiftOrOwedStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // From Person
                HStack {
                    Text("From Person")
                        .frame(width: 100, alignment: .leading)
                    TextField("From Person", text: Binding(
                        get: { editedGift.fromPerson ?? "" },
                        set: { editedGift.fromPerson = $0.isEmpty ? nil : $0 }))
                        .textFieldStyle(.roundedBorder)
                }

                // Expected Date
                VStack(spacing: 8) {
                    HStack {
                        Toggle("Has expected date", isOn: $hasExpectedDate)
                        Spacer()
                    }

                    if hasExpectedDate {
                        HStack {
                            Text("Expected")
                                .frame(width: 100, alignment: .leading)
                            DatePicker("", selection: Binding(
                                get: { editedGift.expectedDate ?? Date() },
                                set: { editedGift.expectedDate = $0 }), displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                    }
                }

                // Received Date
                VStack(spacing: 8) {
                    HStack {
                        Toggle("Has received date", isOn: $hasReceivedDate)
                        Spacer()
                    }

                    if hasReceivedDate {
                        HStack {
                            Text("Received")
                                .frame(width: 100, alignment: .leading)
                            DatePicker("", selection: Binding(
                                get: { editedGift.receivedDate ?? Date() },
                                set: { editedGift.receivedDate = $0 }), displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                    }
                }

                // Description
                HStack(alignment: .top) {
                    Text("Description")
                        .frame(width: 100, alignment: .leading)
                    TextField("Description", text: Binding(
                        get: { editedGift.description ?? "" },
                        set: { editedGift.description = $0.isEmpty ? nil : $0 }), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3 ... 6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: hasExpectedDate) { _, newValue in
            if !newValue {
                editedGift.expectedDate = nil
            }
        }
        .onChange(of: hasReceivedDate) { _, newValue in
            if !newValue {
                editedGift.receivedDate = nil
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 16) {
            Text("Quick Status Update")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: {
                    editedGift.status = editedGift.status == .received ? .pending : .received
                    if editedGift.status == .received {
                        hasReceivedDate = true
                        editedGift.receivedDate = Date()
                        hasExpectedDate = false
                        editedGift.expectedDate = nil
                    } else {
                        hasReceivedDate = false
                        editedGift.receivedDate = nil
                        hasExpectedDate = true
                        editedGift.expectedDate = Date()
                    }
                }) {
                    HStack {
                        Image(systemName: editedGift.status == .received ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(editedGift.status == .received ? AppColors.Budget.income : .secondary)
                            .font(.title2)

                        Text(editedGift.status == .received ? "Mark as Pending" : "Mark as Received")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if editedGift.status == .received {
                    Text("✓ Item received")
                        .font(.caption)
                        .foregroundColor(AppColors.Budget.income)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Delete Item") {
                showingDeleteAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(AppColors.Budget.overBudget)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        guard isFormValid else { return }

        var updatedGift = editedGift
        updatedGift.updatedAt = Date()

        onSave(updatedGift)
        dismiss()
    }
}

#Preview {
    let sampleGift = GiftOrOwed(
        id: UUID(),
        coupleId: UUID(),
        title: "Wedding Gift from Parents",
        amount: 2500.0,
        type: .giftReceived,
        description: "Contribution towards wedding costs",
        fromPerson: "Mom & Dad",
        expectedDate: nil,
        receivedDate: Date(),
        status: .received,
        createdAt: Date(),
        updatedAt: nil)

    EditGiftOrOwedModal(
        giftOrOwed: sampleGift,
        onSave: { _ in },
        onDelete: { _ in })
}
