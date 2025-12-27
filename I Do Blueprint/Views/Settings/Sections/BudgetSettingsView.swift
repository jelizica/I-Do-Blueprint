//
//  BudgetSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct BudgetConfigSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    @State private var showAddTaxRate = false
    @State private var editingTaxRate: SettingsTaxRate?
    @State private var newTaxRateName = ""
    @State private var newTaxRateValue = ""
    @State private var showingCategoryManagement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Budget & Cash Flow",
                subtitle: "Budget configuration and financial settings",
                sectionName: "budget",
                isSaving: viewModel.savingSections.contains("budget"),
                hasUnsavedChanges: viewModel.localSettings.budget != viewModel.settings.budget ||
                    viewModel.localSettings.cashFlow != viewModel.settings.cashFlow,
                onSave: {
                    Task {
                        await viewModel.saveBudgetSettings()
                    }
                })

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Budget Configuration
                    GroupBox(label: Text("Budget Configuration").font(.headline)) {
                        VStack(spacing: 16) {
                            SettingsRow(label: "Base Budget") {
                                TextField(
                                    "Amount",
                                    value: $viewModel.localSettings.budget.baseBudget,
                                    format: .currency(code: viewModel.localSettings.global.currency))
                                    .frame(maxWidth: 200)
                            }

                            SettingsRow(label: "Engagement Rings") {
                                Toggle(
                                    "Include in budget",
                                    isOn: $viewModel.localSettings.budget.includesEngagementRings)
                            }

                            if viewModel.localSettings.budget.includesEngagementRings {
                                SettingsRow(label: "Ring Amount") {
                                    TextField(
                                        "Amount",
                                        value: $viewModel.localSettings.budget.engagementRingAmount,
                                        format: .currency(code: viewModel.localSettings.global.currency))
                                        .frame(maxWidth: 200)
                                }
                            }

                            SettingsRow(label: "Total Budget") {
                                Text(
                                    calculateTotalBudget(),
                                    format: .currency(code: viewModel.localSettings.global.currency))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            SettingsRow(label: "Auto-categorize") {
                                Toggle("", isOn: $viewModel.localSettings.budget.autoCategorize)
                                    .labelsHidden()
                            }

                            SettingsRow(label: "Payment Reminders") {
                                Toggle("", isOn: $viewModel.localSettings.budget.paymentReminders)
                                    .labelsHidden()
                            }
                        }
                        .padding()
                    }

                    // Budget Categories Link
                    GroupBox(label: Text("Budget Categories").font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Manage your budget categories and subcategories for expense organization.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: { showingCategoryManagement = true }) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                    Text("Manage Categories")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                    }
                    
                    // Budget Notes
                    GroupBox(label: Text("Budget Notes").font(.headline)) {
                        TextEditor(text: $viewModel.localSettings.budget.notes)
                            .frame(minHeight: 100)
                            .padding(Spacing.xs)
                    }

                    // Tax Rates
                    GroupBox(label: Text("Tax Rates").font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            if viewModel.localSettings.budget.taxRates.isEmpty {
                                Text("No tax rates configured")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(viewModel.localSettings.budget.taxRates) { rate in
                                    TaxRateRow(
                                        rate: rate,
                                        onEdit: { editingTaxRate = rate },
                                        onDelete: { deleteTaxRate(rate) },
                                        onToggleDefault: { setDefaultTaxRate(rate) })
                                }
                            }

                            Button(action: { showAddTaxRate = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Tax Rate")
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding()
                    }

                    // Cash Flow Settings
                    GroupBox(label: Text("Monthly Cash Flow Defaults").font(.headline)) {
                        VStack(spacing: 16) {
                            SettingsRow(label: "\(viewModel.localSettings.global.partner1FullName)") {
                                TextField(
                                    "Monthly Amount",
                                    value: $viewModel.localSettings.cashFlow.defaultPartner1Monthly,
                                    format: .currency(code: viewModel.localSettings.global.currency))
                                    .frame(maxWidth: 200)
                            }

                            SettingsRow(label: "\(viewModel.localSettings.global.partner2FullName)") {
                                TextField(
                                    "Monthly Amount",
                                    value: $viewModel.localSettings.cashFlow.defaultPartner2Monthly,
                                    format: .currency(code: viewModel.localSettings.global.currency))
                                    .frame(maxWidth: 200)
                            }

                            SettingsRow(label: "Interest/Returns") {
                                TextField(
                                    "Monthly Amount",
                                    value: $viewModel.localSettings.cashFlow.defaultInterestMonthly,
                                    format: .currency(code: viewModel.localSettings.global.currency))
                                    .frame(maxWidth: 200)
                            }

                            SettingsRow(label: "Gifts/Contributions") {
                                TextField(
                                    "Monthly Amount",
                                    value: $viewModel.localSettings.cashFlow.defaultGiftsMonthly,
                                    format: .currency(code: viewModel.localSettings.global.currency))
                                    .frame(maxWidth: 200)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTaxRate) {
            AddTaxRateSheet(
                name: $newTaxRateName,
                rate: $newTaxRateValue,
                onSave: {
                    addTaxRate()
                    showAddTaxRate = false
                },
                onCancel: {
                    showAddTaxRate = false
                    newTaxRateName = ""
                    newTaxRateValue = ""
                })
        }
        .sheet(item: $editingTaxRate) { rate in
            EditTaxRateSheet(
                rate: rate,
                onSave: { updatedRate in
                    updateTaxRate(updatedRate)
                    editingTaxRate = nil
                },
                onCancel: {
                    editingTaxRate = nil
                })
        }
        .sheet(isPresented: $showingCategoryManagement) {
            NavigationStack {
                BudgetCategoriesSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingCategoryManagement = false
                            }
                        }
                    }
            }
            .frame(minWidth: 700, minHeight: 600)
        }
    }

    private func calculateTotalBudget() -> Double {
        let base = viewModel.localSettings.budget.baseBudget
        let rings = viewModel.localSettings.budget.includesEngagementRings ?
            viewModel.localSettings.budget.engagementRingAmount : 0
        return base + rings
    }

    private func addTaxRate() {
        guard !newTaxRateName.isEmpty, let rateValue = Double(newTaxRateValue), rateValue >= 0 else {
            return
        }

        let newRate = SettingsTaxRate(
            id: UUID().uuidString,
            name: newTaxRateName,
            rate: rateValue,
            isDefault: viewModel.localSettings.budget.taxRates.isEmpty)

        viewModel.localSettings.budget.taxRates.append(newRate)
        newTaxRateName = ""
        newTaxRateValue = ""
    }

    private func updateTaxRate(_ updatedRate: SettingsTaxRate) {
        if let index = viewModel.localSettings.budget.taxRates.firstIndex(where: { $0.id == updatedRate.id }) {
            viewModel.localSettings.budget.taxRates[index] = updatedRate
        }
    }

    private func deleteTaxRate(_ rate: SettingsTaxRate) {
        viewModel.localSettings.budget.taxRates.removeAll { $0.id == rate.id }
    }

    private func setDefaultTaxRate(_ rate: SettingsTaxRate) {
        for index in viewModel.localSettings.budget.taxRates.indices {
            viewModel.localSettings.budget.taxRates[index].isDefault =
                viewModel.localSettings.budget.taxRates[index].id == rate.id
        }
    }
}

// MARK: - Tax Rate Row

struct TaxRateRow: View {
    let rate: SettingsTaxRate
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleDefault: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rate.name)
                    .font(.body)
                Text("\(rate.rate, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if rate.isDefault {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .help("Default tax rate")
            } else {
                Button(action: onToggleDefault) {
                    Image(systemName: "star")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Set as default")
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Add Tax Rate Sheet

struct AddTaxRateSheet: View {
    @Binding var name: String
    @Binding var rate: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Tax Rate")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Sales Tax", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Rate (%)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., 10.35", text: $rate)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Add", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || rate.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - Edit Tax Rate Sheet

struct EditTaxRateSheet: View {
    let rate: SettingsTaxRate
    @State private var name: String
    @State private var rateValue: String
    let onSave: (SettingsTaxRate) -> Void
    let onCancel: () -> Void

    init(rate: SettingsTaxRate, onSave: @escaping (SettingsTaxRate) -> Void, onCancel: @escaping () -> Void) {
        self.rate = rate
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: rate.name)
        _rateValue = State(initialValue: String(format: "%.2f", rate.rate))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Tax Rate")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Rate (%)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Rate", text: $rateValue)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Save") {
                    if let newRate = Double(rateValue), newRate >= 0 {
                        let updatedRate = SettingsTaxRate(
                            id: rate.id,
                            name: name,
                            rate: newRate,
                            isDefault: rate.isDefault)
                        onSave(updatedRate)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || rateValue.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

#Preview {
    BudgetConfigSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 800, height: 700)
}
