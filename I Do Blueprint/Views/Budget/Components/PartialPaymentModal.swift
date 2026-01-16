//
//  PartialPaymentModal.swift
//  I Do Blueprint
//
//  Modal for making partial or full payments with live preview of effects
//  Supports underpayments (creates carryover) and overpayments (recalculates remainder)
//

import SwiftUI

struct PartialPaymentModal: View {
    let payment: PaymentSchedule
    let onMakePayment: (Double) async -> PartialPaymentResult

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var settingsStore: SettingsStoreV2

    @State private var amountPaid: String = ""
    @State private var isRecording = false
    @State private var previewResult: PartialPaymentResult?
    @State private var recordResult: PartialPaymentResult?
    @State private var showSuccessMessage = false

    // MARK: - Proportional Modal Sizing

    private let minWidth: CGFloat = 450
    private let maxWidth: CGFloat = 550
    private let minHeight: CGFloat = 500
    private let maxHeight: CGFloat = 650
    private let widthProportion: CGFloat = 0.40
    private let heightProportion: CGFloat = 0.65

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion
        let boundedWidth = min(maxWidth, max(minWidth, targetWidth))
        let boundedHeight = min(maxHeight, max(minHeight, targetHeight))
        let finalWidth = min(boundedWidth, parentSize.width - 40)
        let finalHeight = min(boundedHeight, parentSize.height - 40)
        return CGSize(width: max(300, finalWidth), height: max(300, finalHeight))
    }

    // MARK: - Computed Properties

    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: settingsStore.settings)
    }

    private var parsedAmount: Double? {
        let cleanedString = amountPaid
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleanedString)
    }

    private var isValidAmount: Bool {
        guard let amount = parsedAmount else { return false }
        return amount > 0
    }

    private var paymentType: PaymentAmountType {
        guard let amount = parsedAmount else { return .exact }
        if amount < payment.paymentAmount {
            return .underpayment
        } else if amount > payment.paymentAmount {
            return .overpayment
        }
        return .exact
    }

    private var difference: Double {
        guard let amount = parsedAmount else { return 0 }
        return amount - payment.paymentAmount
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Payment Info Header
                    paymentInfoHeader

                    Divider()

                    // Amount Entry Section
                    amountEntrySection

                    // Preview Section
                    if isValidAmount {
                        previewSection
                    }

                    // Quick Amount Buttons
                    quickAmountButtons

                    Spacer(minLength: Spacing.lg)
                }
                .padding(Spacing.xl)
            }
            .navigationTitle("Make Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Submit Payment") {
                        Task { await submitPayment() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidAmount || isRecording)
                }
            }
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .alert("Payment Recorded", isPresented: $showSuccessMessage) {
            Button("Done") { dismiss() }
        } message: {
            if let result = recordResult {
                Text(result.summary)
            }
        }
        .onAppear {
            // Pre-fill with the due amount
            amountPaid = String(format: "%.2f", payment.paymentAmount)
        }
    }

    // MARK: - Payment Info Header

    private var paymentInfoHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(payment.vendor)
                        .font(.headline)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("Due: \(DateFormatting.formatDateMedium(payment.paymentDate, timezone: userTimezone))")
                        .font(.subheadline)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Amount Due")
                        .font(.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: payment.paymentAmount)) ?? "$\(payment.paymentAmount)")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }

            // Show any existing partial payment info
            if payment.hasPaymentRecorded {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.info)

                    Text("Previously paid: \(NumberFormatter.currencyShort.string(from: NSNumber(value: payment.amountPaid)) ?? "$\(payment.amountPaid)")")
                        .font(.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Amount Entry Section

    private var amountEntrySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Amount Paying")
                .font(.headline)
                .foregroundColor(SemanticColors.textPrimary)

            HStack(spacing: Spacing.sm) {
                Text("$")
                    .font(.title2)
                    .foregroundColor(SemanticColors.textSecondary)

                TextField("0.00", text: $amountPaid)
                    .textFieldStyle(.plain)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .onChange(of: amountPaid) { _, _ in
                        updatePreview()
                    }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(paymentType.borderColor, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(paymentType.backgroundColor)
                    )
            )

            // Payment Type Indicator
            if isValidAmount {
                paymentTypeIndicator
            }
        }
    }

    // MARK: - Payment Type Indicator

    private var paymentTypeIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: paymentType.icon)
                .foregroundColor(paymentType.color)

            Text(paymentType.description(difference: abs(difference)))
                .font(.subheadline)
                .foregroundColor(paymentType.color)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(paymentType.color.opacity(0.1))
        )
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What will happen")
                .font(.headline)
                .foregroundColor(SemanticColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                switch paymentType {
                case .exact:
                    Label("Payment will be marked as paid", systemImage: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)

                case .underpayment:
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Payment will be marked as paid", systemImage: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)

                        Label(
                            "\(formatCurrency(abs(difference))) will be carried over to next month",
                            systemImage: "arrow.right.circle.fill"
                        )
                        .foregroundColor(AppColors.warning)

                        if let carryoverDate = Calendar.current.date(byAdding: .month, value: 1, to: payment.paymentDate) {
                            Text("New payment due: \(DateFormatting.formatDateMedium(carryoverDate, timezone: userTimezone))")
                                .font(.caption)
                                .foregroundColor(SemanticColors.textSecondary)
                                .padding(.leading, 28)
                        }
                    }

                case .overpayment:
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Payment will be marked as paid", systemImage: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)

                        Label(
                            "\(formatCurrency(abs(difference))) excess will reduce future payments",
                            systemImage: "arrow.down.circle.fill"
                        )
                        .foregroundColor(AppColors.info)

                        Text("The last payment(s) in this plan will be reduced or eliminated")
                            .font(.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                            .padding(.leading, 28)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Quick Amount Buttons

    private var quickAmountButtons: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick amounts")
                .font(.caption)
                .foregroundColor(SemanticColors.textSecondary)

            HStack(spacing: Spacing.md) {
                quickAmountButton(label: "50%", amount: payment.paymentAmount * 0.5)
                quickAmountButton(label: "75%", amount: payment.paymentAmount * 0.75)
                quickAmountButton(label: "Full", amount: payment.paymentAmount)
                quickAmountButton(label: "+10%", amount: payment.paymentAmount * 1.1)
            }
        }
    }

    private func quickAmountButton(label: String, amount: Double) -> some View {
        Button(action: {
            amountPaid = String(format: "%.2f", amount)
            updatePreview()
        }) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(SemanticColors.backgroundSecondary)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func updatePreview() {
        // Preview logic would go here if we want real-time preview
        // For now, the UI shows a static preview based on the amount type
    }

    private func submitPayment() async {
        guard let amount = parsedAmount else { return }

        isRecording = true
        recordResult = await onMakePayment(amount)
        isRecording = false

        if recordResult?.isValid == true {
            showSuccessMessage = true
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Payment Amount Type

private enum PaymentAmountType {
    case exact
    case underpayment
    case overpayment

    var icon: String {
        switch self {
        case .exact: return "checkmark.circle.fill"
        case .underpayment: return "exclamationmark.triangle.fill"
        case .overpayment: return "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .exact: return AppColors.success
        case .underpayment: return AppColors.warning
        case .overpayment: return AppColors.info
        }
    }

    var borderColor: Color {
        switch self {
        case .exact: return AppColors.success.opacity(0.5)
        case .underpayment: return AppColors.warning.opacity(0.5)
        case .overpayment: return AppColors.info.opacity(0.5)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .exact: return AppColors.success.opacity(0.05)
        case .underpayment: return AppColors.warning.opacity(0.05)
        case .overpayment: return AppColors.info.opacity(0.05)
        }
    }

    func description(difference: Double) -> String {
        let formatted = NumberFormatter.currencyShort.string(from: NSNumber(value: difference)) ?? "$\(difference)"
        switch self {
        case .exact:
            return "Paying exact amount"
        case .underpayment:
            return "Underpaying by \(formatted)"
        case .overpayment:
            return "Overpaying by \(formatted)"
        }
    }
}

// MARK: - Preview

#Preview {
    PartialPaymentModal(
        payment: PaymentSchedule(
            id: 1,
            coupleId: UUID(),
            vendor: "Sample Vendor",
            paymentDate: Date(),
            paymentAmount: 800,
            paid: false,
            autoRenew: false,
            reminderEnabled: true,
            isDeposit: false,
            isRetainer: false,
            createdAt: Date()
        ),
        onMakePayment: { amount in
            PartialPaymentResult(
                updatedPayment: PaymentSchedule(
                    id: 1,
                    coupleId: UUID(),
                    vendor: "Sample Vendor",
                    paymentDate: Date(),
                    paymentAmount: 800,
                    paid: true,
                    autoRenew: false,
                    reminderEnabled: true,
                    isDeposit: false,
                    isRetainer: false,
                    createdAt: Date()
                ),
                carryoverPayment: nil,
                updatedSubsequentPayments: [],
                paymentsToDelete: [],
                isValid: true,
                errorMessage: nil
            )
        }
    )
}
