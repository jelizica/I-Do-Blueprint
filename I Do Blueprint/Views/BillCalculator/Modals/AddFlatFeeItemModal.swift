//
//  AddFlatFeeItemModal.swift
//  I Do Blueprint
//
//  Modal for adding flat fee items to bill calculator
//  One-time fixed costs that don't depend on guest count
//

import SwiftUI

// MARK: - Add Flat Fee Item Modal

struct AddFlatFeeItemModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appStores) private var appStores

    // MARK: - Form State

    @State private var itemName: String = ""
    @State private var amount: Double = 0
    @State private var selectedCategory: String = ""
    @State private var notes: String = ""

    // MARK: - Callbacks

    let onAdd: (BillLineItem) -> Void
    let onAddAnother: (BillLineItem) -> Void

    // MARK: - Constants

    private let categories = [
        "Setup & Breakdown",
        "Delivery",
        "Equipment Rental",
        "Labor",
        "Permits & Fees",
        "Insurance",
        "Other"
    ]

    // MARK: - Computed Properties

    private var settingsStore: SettingsStoreV2 { appStores.settings }

    private var isFormValid: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0
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
                    Text("Add Flat Fee Item")
                        .font(Typography.title3)
                        .foregroundColor(.white)
                    Text("One-time fixed cost")
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
                colors: [SageGreen.shade500, SageGreen.shade600],
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

            Image(systemName: "tag.fill")
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
                infoBox
                itemNameField
                amountField
                totalCostPreviewBox
                categoryField
                notesField
                helpfulHintBox
            }
            .padding(Spacing.xxl)
        }
    }

    private var infoBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "info.circle.fill")
                .font(Typography.numberSmall)
                .foregroundColor(SageGreen.shade600)
                .frame(width: Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("About flat fees")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Flat fees are one-time charges that don't depend on guest count. Examples include setup fees, delivery charges, or equipment rentals.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(SageGreen.shade100)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SageGreen.shade300, lineWidth: 1)
        )
    }

    private var itemNameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("ITEM NAME")

            TextField("e.g., Venue Setup, Delivery Fee, Equipment Rental...", text: $itemName)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
                .padding(Spacing.md)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )

            Text("Enter a descriptive name for this flat fee item")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("AMOUNT")

            HStack(spacing: Spacing.xs) {
                Text("$")
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textSecondary)

                TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
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

            Text("Enter the total fixed amount for this item")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var totalCostPreviewBox: some View {
        HStack {
            Text("Total Cost")
                .font(Typography.bodyRegular.weight(.semibold))
                .foregroundColor(SemanticColors.textPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("One-time charge")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
                Text(formatCurrency(amount))
                    .font(Typography.numberMedium)
                    .foregroundColor(SageGreen.shade600)
            }
        }
        .padding(Spacing.lg)
        .background(SageGreen.shade100)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SageGreen.shade300, lineWidth: 1)
        )
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("CATEGORY (OPTIONAL)")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            Menu {
                Button("Select a category...") {
                    selectedCategory = ""
                }
                Divider()
                ForEach(categories, id: \.self) { category in
                    Button(category) {
                        selectedCategory = category
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory.isEmpty ? "Select a category..." : selectedCategory)
                        .font(Typography.bodyRegular)
                        .foregroundColor(selectedCategory.isEmpty ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(Spacing.md)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("NOTES (OPTIONAL)")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            TextEditor(text: $notes)
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
                    if notes.isEmpty {
                        Text("Add any additional details or special instructions...")
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textTertiary)
                            .padding(Spacing.md)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var helpfulHintBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(Typography.numberSmall)
                .foregroundColor(SoftLavender.shade600)
                .frame(width: Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Helpful Hint")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Common flat fees include cake cutting fees, corkage fees, venue rental, and coordinator services. Always confirm these charges with your vendor.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(SoftLavender.shade100)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SoftLavender.shade300, lineWidth: 1)
        )
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack(spacing: Spacing.md) {
            cancelButton
            addItemButton
            addAnotherButton
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

    private var addItemButton: some View {
        Button(action: addItem) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                Text("Add Item")
            }
            .font(Typography.bodyRegular.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(SageGreen.shade500)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1 : Opacity.medium)
    }

    private var addAnotherButton: some View {
        Button(action: addAndCreateAnother) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "arrow.clockwise")
                Text("Add & Create Another")
            }
            .font(Typography.bodyRegular.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(SemanticColors.controlBackground)
            .foregroundColor(SageGreen.shade600)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SageGreen.shade500, lineWidth: 1)
            )
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
        // Build the item name with optional category and notes
        let baseName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        var finalName = baseName

        if !selectedCategory.isEmpty {
            finalName = "[\(selectedCategory)] \(baseName)"
        }

        if !notes.isEmpty {
            finalName += " - \(notes)"
        }

        return BillLineItem(
            name: finalName,
            amount: amount
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
        amount = 0
        selectedCategory = ""
        notes = ""
    }
}

// MARK: - Preview

#Preview {
    AddFlatFeeItemModal(
        onAdd: { _ in },
        onAddAnother: { _ in }
    )
}
