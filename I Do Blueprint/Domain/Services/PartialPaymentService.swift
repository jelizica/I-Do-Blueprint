//
//  PartialPaymentService.swift
//  I Do Blueprint
//
//  Domain service for handling partial payment business logic
//  Manages underpayments (creates carryover payments) and overpayments (recalculates remainder)
//

import Foundation

// MARK: - Partial Payment Result

/// Result of recording a partial payment
struct PartialPaymentResult: Sendable {
    /// The updated original payment (marked as paid with amountPaid set)
    let updatedPayment: PaymentSchedule

    /// New carryover payment created for underpayments (nil if fully paid or overpaid)
    let carryoverPayment: PaymentSchedule?

    /// Updated subsequent payments (for overpayments that reduce future amounts)
    let updatedSubsequentPayments: [PaymentSchedule]

    /// Payments to be deleted (when overpayment eliminates a payment)
    let paymentsToDelete: [Int64]

    /// Whether the operation was successful
    let isValid: Bool

    /// Error message if operation failed
    let errorMessage: String?

    /// Summary description of what happened
    var summary: String {
        if let error = errorMessage {
            return "Error: \(error)"
        }

        if let carryover = carryoverPayment {
            let formatter = NumberFormatter.currencyShort
            let carryoverAmount = formatter.string(from: NSNumber(value: carryover.paymentAmount)) ?? "$\(carryover.paymentAmount)"
            return "Partial payment recorded. \(carryoverAmount) carried over to next month."
        }

        if !paymentsToDelete.isEmpty {
            return "Overpayment recorded. \(paymentsToDelete.count) future payment(s) eliminated."
        }

        if !updatedSubsequentPayments.isEmpty {
            return "Overpayment recorded. Future payments recalculated."
        }

        return "Payment recorded successfully."
    }
}

// MARK: - Partial Payment Service

/// Actor for handling partial payment business logic
/// Thread-safe service that manages the complexity of partial/over payments
actor PartialPaymentService {
    private let logger = AppLogger.database

    // MARK: - Public Methods

    /// Records a partial or full payment for a payment schedule
    /// - Parameters:
    ///   - payment: The payment schedule being paid
    ///   - amountPaid: The actual amount being paid
    ///   - allPlanPayments: All payments in the same plan (for overpayment recalculation)
    /// - Returns: PartialPaymentResult with all affected payments
    func recordPayment(
        payment: PaymentSchedule,
        amountPaid: Double,
        allPlanPayments: [PaymentSchedule]
    ) -> PartialPaymentResult {
        // Validate amount
        guard amountPaid > 0 else {
            return PartialPaymentResult(
                updatedPayment: payment,
                carryoverPayment: nil,
                updatedSubsequentPayments: [],
                paymentsToDelete: [],
                isValid: false,
                errorMessage: "Payment amount must be greater than zero"
            )
        }

        let dueAmount = payment.paymentAmount

        // Determine payment type
        if amountPaid < dueAmount {
            // Underpayment - create carryover
            return handleUnderpayment(
                payment: payment,
                amountPaid: amountPaid,
                shortfall: dueAmount - amountPaid
            )
        } else if amountPaid > dueAmount {
            // Overpayment - recalculate subsequent payments
            return handleOverpayment(
                payment: payment,
                amountPaid: amountPaid,
                excess: amountPaid - dueAmount,
                allPlanPayments: allPlanPayments
            )
        } else {
            // Exact payment
            return handleExactPayment(payment: payment, amountPaid: amountPaid)
        }
    }

    /// Creates a carryover payment for the next month
    /// - Parameters:
    ///   - originalPayment: The payment that was underpaid
    ///   - carryoverAmount: The amount to carry over
    /// - Returns: A new PaymentSchedule for the carryover
    func createCarryoverPayment(
        from originalPayment: PaymentSchedule,
        carryoverAmount: Double
    ) -> PaymentSchedule {
        // Calculate next month's date (same day)
        let calendar = Calendar.current
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: originalPayment.paymentDate) ?? originalPayment.paymentDate

        // Create new payment as carryover
        return PaymentSchedule(
            id: 0, // Will be assigned by database
            coupleId: originalPayment.coupleId,
            vendor: originalPayment.vendor,
            paymentDate: nextMonthDate,
            paymentAmount: carryoverAmount,
            notes: "Carryover from \(DateFormatting.formatDateMedium(originalPayment.paymentDate, timezone: .current))",
            vendorType: originalPayment.vendorType,
            paid: false,
            paymentType: originalPayment.paymentType,
            customAmount: nil,
            billingFrequency: originalPayment.billingFrequency,
            autoRenew: false,
            startDate: nil,
            reminderEnabled: originalPayment.reminderEnabled,
            reminderDaysBefore: originalPayment.reminderDaysBefore,
            priorityLevel: originalPayment.priorityLevel,
            expenseId: originalPayment.expenseId,
            vendorId: originalPayment.vendorId,
            isDeposit: false,
            isRetainer: false,
            paymentOrder: nil, // Carryover payments don't have an order in the original plan
            totalPaymentCount: nil,
            paymentPlanType: "carryover",
            paymentPlanId: originalPayment.paymentPlanId,
            segmentIndex: originalPayment.segmentIndex,
            createdAt: Date(),
            updatedAt: nil,
            originalAmount: carryoverAmount,
            amountPaid: 0,
            carryoverAmount: 0,
            carryoverFromId: originalPayment.id,
            isCarryover: true,
            paymentRecordedAt: nil
        )
    }

    // MARK: - Private Helpers

    /// Handles an underpayment by marking payment as paid and creating a carryover
    private func handleUnderpayment(
        payment: PaymentSchedule,
        amountPaid: Double,
        shortfall: Double
    ) -> PartialPaymentResult {
        logger.info("Processing underpayment: paid \(amountPaid) of \(payment.paymentAmount), shortfall: \(shortfall)")

        // Update the original payment
        var updatedPayment = payment
        updatedPayment.paid = true
        updatedPayment.amountPaid = amountPaid
        updatedPayment.paymentRecordedAt = Date()

        // Create carryover payment
        let carryover = createCarryoverPayment(from: payment, carryoverAmount: shortfall)

        return PartialPaymentResult(
            updatedPayment: updatedPayment,
            carryoverPayment: carryover,
            updatedSubsequentPayments: [],
            paymentsToDelete: [],
            isValid: true,
            errorMessage: nil
        )
    }

    /// Handles an overpayment by recalculating the remaining payments
    private func handleOverpayment(
        payment: PaymentSchedule,
        amountPaid: Double,
        excess: Double,
        allPlanPayments: [PaymentSchedule]
    ) -> PartialPaymentResult {
        logger.info("Processing overpayment: paid \(amountPaid) of \(payment.paymentAmount), excess: \(excess)")

        // Update the original payment
        var updatedPayment = payment
        updatedPayment.paid = true
        updatedPayment.amountPaid = amountPaid
        updatedPayment.paymentRecordedAt = Date()

        // Get unpaid payments after this one, sorted by date/order
        let subsequentPayments = allPlanPayments
            .filter { !$0.paid && $0.id != payment.id }
            .sorted { ($0.paymentOrder ?? 0) < ($1.paymentOrder ?? 0) }

        guard !subsequentPayments.isEmpty else {
            // No subsequent payments - just mark as overpaid (excess is absorbed)
            logger.info("No subsequent payments to apply excess to")
            return PartialPaymentResult(
                updatedPayment: updatedPayment,
                carryoverPayment: nil,
                updatedSubsequentPayments: [],
                paymentsToDelete: [],
                isValid: true,
                errorMessage: nil
            )
        }

        // Apply excess to subsequent payments using "adjust last" strategy
        var remainingExcess = excess
        var updatedSubsequent: [PaymentSchedule] = []
        var toDelete: [Int64] = []

        // For cyclical/monthly/interval plans: recalculate at the end (remainder in last payment)
        // Apply excess to payments in reverse order (from last to first)
        let reversedPayments = subsequentPayments.reversed()

        for var subsequent in reversedPayments {
            if remainingExcess >= subsequent.paymentAmount {
                // This payment is fully covered by excess - delete it
                remainingExcess -= subsequent.paymentAmount
                toDelete.append(subsequent.id)
                logger.info("Payment \(subsequent.id) eliminated by overpayment")
            } else if remainingExcess > 0 {
                // Reduce this payment by the remaining excess
                subsequent.paymentAmount -= remainingExcess
                updatedSubsequent.append(subsequent)
                logger.info("Payment \(subsequent.id) reduced by \(remainingExcess)")
                remainingExcess = 0
            }
        }

        // Update total payment count for remaining payments if any were deleted
        if !toDelete.isEmpty {
            let newTotalCount = allPlanPayments.count - toDelete.count
            updatedSubsequent = updatedSubsequent.map { payment in
                var updated = payment
                updated.totalPaymentCount = newTotalCount
                return updated
            }
        }

        return PartialPaymentResult(
            updatedPayment: updatedPayment,
            carryoverPayment: nil,
            updatedSubsequentPayments: updatedSubsequent,
            paymentsToDelete: toDelete,
            isValid: true,
            errorMessage: nil
        )
    }

    /// Handles an exact payment (amount matches what's due)
    private func handleExactPayment(
        payment: PaymentSchedule,
        amountPaid: Double
    ) -> PartialPaymentResult {
        logger.info("Processing exact payment: \(amountPaid)")

        var updatedPayment = payment
        updatedPayment.paid = true
        updatedPayment.amountPaid = amountPaid
        updatedPayment.paymentRecordedAt = Date()

        return PartialPaymentResult(
            updatedPayment: updatedPayment,
            carryoverPayment: nil,
            updatedSubsequentPayments: [],
            paymentsToDelete: [],
            isValid: true,
            errorMessage: nil
        )
    }
}

// MARK: - Preview/Calculation Helpers

extension PartialPaymentService {
    /// Previews what would happen with a partial payment without making changes
    func previewPartialPayment(
        payment: PaymentSchedule,
        amountPaid: Double,
        allPlanPayments: [PaymentSchedule]
    ) -> PartialPaymentResult {
        recordPayment(payment: payment, amountPaid: amountPaid, allPlanPayments: allPlanPayments)
    }

    /// Calculates the suggested carryover date (same day next month)
    func suggestedCarryoverDate(from date: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
    }
}
