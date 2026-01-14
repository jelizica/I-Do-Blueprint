//
//  AddVariableItemModal.swift
//  I Do Blueprint
//
//  Modal for adding variable quantity items to the bill calculator
//  Each item has its own quantity instead of being multiplied by guest count
//

import SwiftUI

// MARK: - Add Variable Item Modal

struct AddVariableItemModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appStores) private var appStores

    // MARK: - Form State

    @State private var itemName: String = ""
    @State private var amountPerItem: Double = 0
    @State private var quantity: Int = 1
    @State private var itemDescription: String = ""
    @State private var showMultiplierOptions: Bool = false
    @State private var customMultiplier: Double = 1.0

    // MARK: - Callbacks

    let guestCount: Int
    let onAdd: (BillLineItem) -> Void
    let onAddAnother: (BillLineItem) -> Void

    // MARK: - Computed Properties

    private var settingsStore: SettingsStoreV2 { appStores.settings }
    private var guestStore: GuestStoreV2 { appStores.guest }

    /// The current attending guest count (live from store)
    private var currentGuestCount: Int {
        guestStore.attendingCount
    }

    private var totalCost: Double {
        amountPerItem * Double(quantity)
    }

    private var isFormValid: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amountPerItem > 0 && quantity > 0
    }

    /// Common multiplier presets for quantity calculations
    private var multiplierPresets: [(label: String, value: Double)] {
        [
            ("1×", 1.0),
            ("1.2×", 1.2),
            ("1.5×", 1.5),
            ("2×", 2.0)
        ]
    }

    /// Calculate quantity from guest count and multiplier
    private func calculateWithMultiplier(_ multiplier: Double) -> Int {
        max(1, Int(ceil(Double(currentGuestCount) * multiplier)))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerView
            formContentView
            footerView
        }
        .frame(width: 520, height: 700)
        .glassPanel(cornerRadius: CornerRadius.xxl, padding: 0)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            HStack(spacing: Spacing.md) {
                iconContainer
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Add Per-Item Expense")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Each item has its own quantity")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()

            closeButton
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.lg)
    }

    private var iconContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.primaryAction.opacity(0.15))
                .frame(width: Spacing.huge - Spacing.sm, height: Spacing.huge - Spacing.sm)

            Image(systemName: "number.square")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.primaryAction)
        }
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: Spacing.xxxl, height: Spacing.xxxl)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form Content View

    private var formContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                itemNameField
                amountField
                quantityField
                calculationPreviewBox
                descriptionField
            }
            .padding(Spacing.xxl)
        }
    }

    private var itemNameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("ITEM NAME")

            TextField("e.g., Centerpiece, Chair Cover, Charger Plate...", text: $itemName)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
                .padding(Spacing.md)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )

            Text("Enter a descriptive name for this expense item")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("AMOUNT PER ITEM")

            HStack(spacing: Spacing.xs) {
                Text("$")
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textSecondary)

                TextField("0.00", value: $amountPerItem, format: .number.precision(.fractionLength(2)))
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

            Text("The cost per single item or unit")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var quantityField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("QUANTITY")

            HStack(spacing: Spacing.md) {
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(quantity > 1 ? SemanticColors.primaryAction : SemanticColors.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(quantity <= 1)

                TextField("1", value: $quantity, format: .number)
                    .textFieldStyle(.plain)
                    .font(Typography.title2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .padding(.vertical, Spacing.sm)
                    .background(SemanticColors.controlBackground)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                    )

                Button(action: {
                    quantity += 1
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(SemanticColors.primaryAction)
                }
                .buttonStyle(.plain)

                Spacer()

                // Use Guest Count button
                useGuestCountButton
            }

            // Multiplier equation section
            multiplierSection

            Text("How many of this item do you need?")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var useGuestCountButton: some View {
        Button(action: {
            quantity = currentGuestCount
        }) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "person.3.fill")
                    .font(Typography.caption2)
                Text("Use Guest Count (\(currentGuestCount))")
                    .font(Typography.caption)
            }
            .foregroundColor(SemanticColors.primaryAction)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(SemanticColors.primaryAction.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
        .disabled(currentGuestCount <= 0)
        .opacity(currentGuestCount > 0 ? 1 : Opacity.medium)
    }

    // MARK: - Multiplier Section

    private var multiplierSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Toggle to show/hide multiplier options
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMultiplierOptions.toggle()
                }
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "function")
                        .font(Typography.caption)
                    Text("Use Formula")
                        .font(Typography.caption)
                    Spacer()
                    Image(systemName: showMultiplierOptions ? "chevron.up" : "chevron.down")
                        .font(Typography.caption2)
                }
                .foregroundColor(SemanticColors.textSecondary)
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
            .disabled(currentGuestCount <= 0)
            .opacity(currentGuestCount > 0 ? 1 : Opacity.medium)

            if showMultiplierOptions && currentGuestCount > 0 {
                multiplierOptionsView
            }
        }
        .padding(.top, Spacing.sm)
    }

    private var multiplierOptionsView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Formula display
            HStack(spacing: Spacing.xs) {
                Text("\(currentGuestCount) guests")
                    .font(Typography.bodySmall.weight(.medium))
                    .foregroundColor(SemanticColors.textPrimary)
                Text("×")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textTertiary)

                // Custom multiplier input
                TextField("1.0", value: $customMultiplier, format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.plain)
                    .font(Typography.bodySmall.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(SemanticColors.controlBackground)
                    .cornerRadius(CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                    )

                Text("=")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textTertiary)

                Text("\(calculateWithMultiplier(customMultiplier))")
                    .font(Typography.bodySmall.weight(.bold))
                    .foregroundColor(SemanticColors.primaryAction)

                Spacer()

                // Apply button
                Button(action: {
                    quantity = calculateWithMultiplier(customMultiplier)
                }) {
                    Text("Apply")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(SemanticColors.primaryAction)
                        .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
            }

            // Preset multiplier pills
            HStack(spacing: Spacing.xs) {
                ForEach(multiplierPresets, id: \.value) { preset in
                    Button(action: {
                        customMultiplier = preset.value
                        quantity = calculateWithMultiplier(preset.value)
                    }) {
                        Text(preset.label)
                            .font(Typography.caption)
                            .foregroundColor(customMultiplier == preset.value ? .white : SemanticColors.textSecondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(customMultiplier == preset.value ? SemanticColors.primaryAction : SemanticColors.controlBackground)
                            .cornerRadius(CornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .stroke(customMultiplier == preset.value ? Color.clear : SemanticColors.borderPrimary, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            // Helper text
            Text("Great for napkins, favors, or items needing extras")
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textTertiary)
                .italic()
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary.opacity(0.5))
        .cornerRadius(CornerRadius.md)
    }

    private var calculationPreviewBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "function")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.primaryAction)
                .frame(width: Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Calculation Preview")
                    .font(Typography.bodySmall.weight(.bold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("\(formatCurrency(amountPerItem)) × \(quantity) items = \(formatCurrency(totalCost))")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(SemanticColors.primaryAction.opacity(0.08))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.primaryAction.opacity(0.2), lineWidth: 1)
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
            .foregroundColor(SemanticColors.primaryAction)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.primaryAction, lineWidth: 1)
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
            .background(SemanticColors.primaryAction)
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
            amount: amountPerItem,
            quantity: quantity
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
        amountPerItem = 0
        quantity = 1
        itemDescription = ""
        showMultiplierOptions = false
        customMultiplier = 1.0
    }
}

// MARK: - Preview

#Preview {
    AddVariableItemModal(
        guestCount: 150,
        onAdd: { _ in },
        onAddAnother: { _ in }
    )
}
