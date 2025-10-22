import SwiftUI

struct AddGiftOrOwedModal: View {
    private let logger = AppLogger.ui
    let onSave: (GiftOrOwed) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = SessionManager.shared
    @State private var title = ""
    @State private var amount = ""
    @State private var type: GiftOrOwed.GiftOrOwedType = .giftReceived
    @State private var description = ""
    @State private var fromPerson = ""
    @State private var expectedDate = Date()
    @State private var receivedDate = Date()
    @State private var status: GiftOrOwed.GiftOrOwedStatus = .pending
    @State private var hasExpectedDate = false
    @State private var hasReceivedDate = false

    private var isFormValid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              case .success(let amountValue) = InputValidator.validateAmount(amount),
              amountValue > 0 else {
            return false
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Information Section
                    basicInformationSection

                    // Type and Status Section
                    typeAndStatusSection

                    // Dates Section
                    datesSection

                    // Additional Information Section
                    additionalInformationSection
                }
                .padding()
            }
            .navigationTitle("Add Gift or Owed Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveGiftOrOwed()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Form Sections

    private var basicInformationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Basic Information")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Title")
                        .frame(width: 100, alignment: .leading)
                    TextField("e.g., Wedding gift from parents", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Amount")
                        .frame(width: 100, alignment: .leading)
                    TextField("$0.00", text: $amount)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var typeAndStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Type & Status")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Type")
                        .frame(width: 100, alignment: .leading)
                    Picker("Type", selection: $type) {
                        ForEach(GiftOrOwed.GiftOrOwedType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    Text("Status")
                        .frame(width: 100, alignment: .leading)
                    Picker("Status", selection: $status) {
                        ForEach(GiftOrOwed.GiftOrOwedStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var datesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dates")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack {
                        Toggle("Has expected date", isOn: $hasExpectedDate)
                        Spacer()
                    }

                    if hasExpectedDate {
                        HStack {
                            Text("Expected")
                                .frame(width: 100, alignment: .leading)
                            DatePicker("", selection: $expectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                    }
                }

                VStack(spacing: 8) {
                    HStack {
                        Toggle("Has received date", isOn: $hasReceivedDate)
                        Spacer()
                    }

                    if hasReceivedDate {
                        HStack {
                            Text("Received")
                                .frame(width: 100, alignment: .leading)
                            DatePicker("", selection: $receivedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: status) { _, newStatus in
            // Auto-set date toggles based on status
            switch newStatus {
            case .pending:
                hasReceivedDate = false
                hasExpectedDate = true
            case .received, .confirmed:
                hasExpectedDate = false
                hasReceivedDate = true
            }
        }
    }

    private var additionalInformationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Additional Information")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    Text("From Person")
                        .frame(width: 100, alignment: .leading)
                    TextField("e.g., Mom & Dad", text: $fromPerson)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(alignment: .top) {
                    Text("Description")
                        .frame(width: 100, alignment: .leading)
                    TextField("Additional details...", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3 ... 6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func saveGiftOrOwed() {
        guard let amountValue = Double(amount) else { return }

        guard let coupleId = sessionManager.getTenantId() else {
            return
        }

        let giftOrOwed = GiftOrOwed(
            id: UUID(), // Will be set by database
            coupleId: coupleId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amountValue,
            type: type,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description
                .trimmingCharacters(in: .whitespacesAndNewlines),
            fromPerson: fromPerson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fromPerson
                .trimmingCharacters(in: .whitespacesAndNewlines),
            expectedDate: hasExpectedDate ? expectedDate : nil,
            receivedDate: hasReceivedDate ? receivedDate : nil,
            status: status,
            createdAt: Date(),
            updatedAt: nil)

        onSave(giftOrOwed)
        dismiss()
    }
}

#Preview {
    AddGiftOrOwedModal { giftOrOwed in
        // TODO: Implement action - print("Saved: \(giftOrOwed)")
    }
}
