//
//  AddServiceFeeModal.swift
//  I Do Blueprint
//
//  Modal for adding service fee items to bill calculator
//  Percentage-based fees calculated on subtotal
//

import SwiftUI

// MARK: - Add Service Fee Modal

struct AddServiceFeeModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appStores) private var appStores

    // MARK: - Form State

    @State private var feeName: String = ""
    @State private var percentageRate: Double = 0
    @State private var notes: String = ""

    // MARK: - Callbacks

    let subtotal: Double
    let onAdd: (BillLineItem) -> Void
    let onAddAnother: (BillLineItem) -> Void

    // MARK: - Computed Properties

    private var settingsStore: SettingsStoreV2 { appStores.settings }

    private var feeAmount: Double {
        subtotal * (percentageRate / 100)
    }

    private var isFormValid: Bool {
        !feeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && percentageRate > 0
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
                    Text("Add Service Fee")
                        .font(Typography.title3)
                        .foregroundColor(.white)
                    Text("Percentage-based fee on subtotal")
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
                colors: [AppColors.info, AppColors.info.opacity(Opacity.veryStrong)],
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

            Image(systemName: "percent")
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
                feeNameField
                percentageField
                calculationPreviewBox
                notesField
                warningBox
            }
            .padding(Spacing.xxl)
        }
    }

    private var infoBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "info.circle.fill")
                .font(Typography.numberSmall)
                .foregroundColor(AppColors.info)
                .frame(width: Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("How service fees are calculated")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Service fees are applied as a percentage of the per-person items subtotal only. Other service fees are excluded from the calculation base. Current subtotal: \(formatCurrency(subtotal))")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.infoLight)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.info.opacity(Opacity.semiLight), lineWidth: 1)
        )
    }

    private var feeNameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("FEE NAME")

            TextField("e.g., Service Charge, Gratuity, Administrative Fee...", text: $feeName)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
                .padding(Spacing.md)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )

            Text("Enter a descriptive name for this service fee")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var percentageField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            requiredFieldLabel("PERCENTAGE RATE")

            HStack(spacing: Spacing.xs) {
                TextField("0.00", value: $percentageRate, format: .number.precision(.fractionLength(2)))
                    .textFieldStyle(.plain)
                    .font(Typography.numberMedium)

                Text("%")
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(Spacing.md)
            .background(SemanticColors.controlBackground)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.borderPrimary, lineWidth: 1)
            )

            Text("Enter the percentage rate (e.g., 20 for 20%)")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    private var calculationPreviewBox: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Calculation Base (Subtotal)")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                Spacer()
                Text(formatCurrency(subtotal))
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
            }

            HStack {
                Text("Fee Rate")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                Spacer()
                Text(String(format: "%.2f%%", percentageRate))
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Divider()

            HStack {
                Text(String(format: "%.2f%% of %@", percentageRate, formatCurrency(subtotal)))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
                Spacer()
            }

            HStack {
                Text("Fee Amount")
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                Spacer()
                Text(formatCurrency(feeAmount))
                    .font(Typography.numberMedium)
                    .foregroundColor(AppColors.info)
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.infoLight)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.info.opacity(Opacity.semiLight), lineWidth: 1)
        )
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
                        Text("Add any additional details about this fee...")
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textTertiary)
                            .padding(Spacing.md)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var warningBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.numberSmall)
                .foregroundColor(AppColors.warning)
                .frame(width: Spacing.xxl)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Important Note")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Service fees are typically non-negotiable and may be required by the vendor. Make sure to verify the exact percentage with your vendor.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.warningLight)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.warning.opacity(Opacity.semiLight), lineWidth: 1)
        )
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack(spacing: Spacing.md) {
            cancelButton
            addFeeButton
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

    private var addFeeButton: some View {
        Button(action: addFee) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                Text("Add Fee")
            }
            .font(Typography.bodyRegular.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(AppColors.info)
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
            .foregroundColor(AppColors.info)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(AppColors.info, lineWidth: 1)
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
        // Note: For service fees, amount is the percentage rate
        // Notes are stored in the item name if provided
        let name = feeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = notes.isEmpty ? name : "\(name) - \(notes)"

        return BillLineItem(
            name: finalName,
            amount: percentageRate
        )
    }

    private func addFee() {
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
        feeName = ""
        percentageRate = 0
        notes = ""
    }
}

// MARK: - Preview

#Preview {
    AddServiceFeeModal(
        subtotal: 18750.00,
        onAdd: { _ in },
        onAddAnother: { _ in }
    )
}
