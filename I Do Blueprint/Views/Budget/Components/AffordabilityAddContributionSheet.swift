import SwiftUI

struct AffordabilityAddContributionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2

    let scenario: AffordabilityScenario?
    let contribution: ContributionItem?
    let onSave: (ContributionItem) -> Void

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var type: ContributionType = .gift
    @State private var date: Date = Date()
    @State private var notes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(contribution == nil ? "Add New Contribution" : "Edit Contribution")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Form Content
            ScrollView {
                VStack(spacing: 24) {
                    // Contributor Name and Amount Row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contributor Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)

                            TextField("John Doe", text: $name)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)

                            HStack(spacing: 8) {
                                Text("$")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)

                                TextField("0", text: $amount)
                                    .textFieldStyle(.plain)
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Date and Type Row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)

                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)

                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)

                            Picker("", selection: $type) {
                                Text("Gift").tag(ContributionType.gift)
                                Text("External").tag(ContributionType.external)
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)

                        TextEditor(text: $notes)
                            .font(.system(size: 13))
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                Group {
                                    if notes.isEmpty {
                                        Text("Add any notes about this contribution...")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }

            // Footer with buttons
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: {
                    guard let scenario = scenario else {
                        return
                    }

                    guard let coupleId = SessionManager.shared.getTenantId() else {
                        return
                    }

                    let newContribution = ContributionItem(
                        id: contribution?.id ?? UUID(),
                        scenarioId: scenario.id,
                        contributorName: name,
                        amount: Double(amount) ?? 0,
                        contributionDate: date,
                        contributionType: type,
                        notes: notes.isEmpty ? nil : notes,
                        coupleId: coupleId,
                        createdAt: contribution?.createdAt ?? Date(),
                        updatedAt: Date())
                    onSave(newContribution)
                }) {
                    Text(contribution == nil ? "Add Contribution" : "Save Changes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(
                    (name.isEmpty || amount.isEmpty) ?
                        Color.purple.opacity(0.5) :
                        Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(name.isEmpty || amount.isEmpty)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 700, height: 550)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if let contribution = contribution {
                name = contribution.contributorName
                amount = String(Int(contribution.amount))
                type = contribution.contributionType
                date = contribution.contributionDate
                notes = contribution.notes ?? ""
            }
        }
    }
}
