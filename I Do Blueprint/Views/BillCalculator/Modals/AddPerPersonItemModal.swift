//
//  AddPerPersonItemModal.swift
//  I Do Blueprint
//
//  Modal for adding per-person bill calculator items
//  Costs are multiplied by guest count
//

import SwiftUI

// MARK: - Add Per-Person Item Modal

struct AddPerPersonItemModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appStores) private var appStores

    // MARK: - Form State

    @State private var itemName: String = ""
    @State private var amountPerPerson: Double = 0
    @State private var itemDescription: String = ""

    // MARK: - Callbacks

    let guestCount: Int
    let onAdd: (BillLineItem) -> Void
    let onAddAnother: (BillLineItem) -> Void

    // MARK: - Computed Properties

    private var settingsStore: SettingsStoreV2 { appStores.settings }

    private var totalCost: Double {
        amountPerPerson * Double(guestCount)
    }

    private var isFormValid: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amountPerPerson > 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerView
            formContentView
            footerView
        }
        .frame(width: 520)
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(CornerRadius.xxl)
        .macOSShadow(.modal)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            HStack(spacing: Spacing.md) {
                iconContainer
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Add Per-Person Item")
                        .font(Typography.title3)
                        .foregroundColor(.white)
                    Text("Cost will be multiplied by guest count")
                        .font(Typography.caption)
                        .foregroundColor(.white.opacity(Opacity.nearOpaque))
                }
            }

            Spacer()

            closeButton
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.lg)
        .background(
            LinearGradient(
                colors: [SoftLavender.shade500, BlushPink.shade500],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var iconContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.white.opacity(Opacity.lightMedium))
                .frame(width: Spacing.huge - Spacing.sm, height: Spacing.huge - Spacing.sm)

            Image(systemName: "person.fill")
                .font(Typography.subheading)
                .foregroundColor(.white)
        }
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(Typography.subheading)
                .foregroundColor(.white)
                .frame(width: Spacing.xxxl, height: Spacing.xxxl)
                .background(Color.white.opacity(Opacity.lightMedium))
                .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form Content View

    private var formContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                itemNameField
                amountField
                calculationPreviewBox
                descriptionField
            }
            .padding(Spacing.xxl)
        }
    }

    private var itemNameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("ITEM NAME")

            TextField("e.g., Plated Dinner, Beverage Package...", text: $itemName)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
                .padding(Spacing.md)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )

            Text("Enter a descriptive name for this per-person cost item")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("AMOUNT PER PERSON")

            HStack(spacing: Spacing.xs) {
                Text("$")
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textSecondary)

                TextField("0.00", value: $amountPerPerson, format: .number.precision(.fractionLength(2)))
                    .textFieldStyle(.plain)
                    .font(Typography.numberMedium)
            }
            .padding(Spacing.md)
            .background(SemanticColors.controlBackground)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.borderPrimary, lineWidth: 1)
            )

            Text("This amount will be multiplied by the guest count (currently \(guestCount) guests)")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var calculationPreviewBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "function")
                .font(Typography.subheading)
                .foregroundColor(SoftLavender.shade700)
                .frame(width: Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Calculation Preview")
                    .font(Typography.bodySmall.weight(.bold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("\(formatCurrency(amountPerPerson)) × \(guestCount) guests = \(formatCurrency(totalCost))")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(SoftLavender.shade100)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SoftLavender.shade300, lineWidth: 1)
        )
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("DESCRIPTION (OPTIONAL)")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            TextEditor(text: $itemDescription)
                .font(Typography.bodyRegular)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(Spacing.md)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if itemDescription.isEmpty {
                        Text("Add any additional details or notes about this item...")
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textTertiary)
                            .padding(Spacing.md)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack(spacing: Spacing.md) {
            cancelButton
            addAnotherButton
            addItemButton
        }
        .padding(Spacing.xxl)
        .background(SemanticColors.backgroundSecondary)
    }

    private var cancelButton: some View {
        Button(action: { dismiss() }) {
            Text("Cancel")
                .font(Typography.bodyRegular.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(SemanticColors.controlBackground)
                .foregroundColor(SemanticColors.textPrimary)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var addAnotherButton: some View {
        Button(action: addAndCreateAnother) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                Text("Add Another")
            }
            .font(Typography.bodyRegular.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(SemanticColors.controlBackground)
            .foregroundColor(SoftLavender.shade700)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SoftLavender.shade500, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1 : Opacity.medium)
    }

    private var addItemButton: some View {
        Button(action: addItem) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark")
                Text("Add Item")
            }
            .font(Typography.bodyRegular.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [SoftLavender.shade500, BlushPink.shade500],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1 : Opacity.medium)
    }

    // MARK: - Helper Methods

    private func requiredFieldLabel(_ text: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            Text(text)
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)
            Text("*")
                .font(Typography.caption.weight(.bold))
                .foregroundColor(SemanticColors.error)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsStore.settings.global.currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func createBillLineItem() -> BillLineItem {
        // Note: Description is stored in the item name if provided
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = itemDescription.isEmpty ? name : "\(name) - \(itemDescription)"

        return BillLineItem(
            name: finalName,
            amount: amountPerPerson
        )
    }

    private func addItem() {
        let item = createBillLineItem()
        onAdd(item)
        dismiss()
    }

    private func addAndCreateAnother() {
        let item = createBillLineItem()
        onAddAnother(item)
        resetForm()
    }

    private func resetForm() {
        itemName = ""
        amountPerPerson = 0
        itemDescription = ""
    }
}

// MARK: - Preview

#Preview {
    AddPerPersonItemModal(
        guestCount: 150,
        onAdd: { _ in },
        onAddAnother: { _ in }
    )
}
