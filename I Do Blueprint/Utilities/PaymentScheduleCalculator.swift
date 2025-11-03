import Foundation

/// Calculator for generating payment schedules based on form data
class PaymentScheduleCalculator {

    /// Calculate payment schedule from form data
    static func calculateSchedule(from formData: PaymentFormData) -> [PaymentScheduleItem] {
        var schedule: [PaymentScheduleItem] = []
        // Use effective amount (partial or full) for calculations
        var remainingAmount = formData.effectiveAmount
        _ = formData.selectedExpenseId

        // Add deposit if enabled (for non-individual payments)
        if formData.hasDeposit, formData.paymentType != .individual {
            let depositAmount = formData.actualDepositAmount
            schedule.append(PaymentScheduleItem(
                id: UUID().uuidString,
                description: formData.isDepositRetainer ? "Retainer" : "Deposit",
                amount: depositAmount,
                vendorName: "Selected Vendor",
                dueDate: formData.startDate,
                isPaid: false,
                isRecurring: false))
            remainingAmount -= depositAmount
        }

        // Calculate payment schedule based on type
        switch formData.paymentType {
        case .individual:
            schedule.append(contentsOf: calculateIndividualSchedule(formData: formData))

        case .monthly:
            schedule.append(contentsOf: calculateMonthlySchedule(formData: formData, remainingAmount: remainingAmount))

        case .interval:
            schedule.append(contentsOf: calculateIntervalSchedule(formData: formData, remainingAmount: remainingAmount))

        case .cyclical:
            schedule.append(contentsOf: calculateCyclicalSchedule(formData: formData, remainingAmount: remainingAmount))
        }

        return schedule.sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: - Individual Payment Schedule

    private static func calculateIndividualSchedule(formData: PaymentFormData) -> [PaymentScheduleItem] {
        let description = formData.isIndividualDeposit ?
            (formData.isIndividualRetainer ? "Retainer" : "Deposit") : "Payment"

        return [PaymentScheduleItem(
            id: UUID().uuidString,
            description: description,
            amount: formData.individualAmount,
            vendorName: "Selected Vendor",
            dueDate: formData.startDate,
            isPaid: false,
            isRecurring: false)]
    }

    // MARK: - Monthly Payment Schedule

    private static func calculateMonthlySchedule(formData: PaymentFormData, remainingAmount: Double) -> [PaymentScheduleItem] {
        var schedule: [PaymentScheduleItem] = []
        var remaining = remainingAmount
        var paymentIndex = 0

        let startDate = formData.hasDeposit ?
            Calendar.current.date(byAdding: .month, value: 1, to: formData.startDate) ?? formData.startDate :
            formData.startDate

        while remaining > 0.01 {
            let paymentAmount = min(formData.monthlyAmount, remaining)
            let isLast = paymentAmount >= remaining - 0.01
            let paymentDate = Calendar.current.date(byAdding: .month, value: paymentIndex, to: startDate) ?? startDate

            // Determine description for first payment (deposit/retainer)
            let description: String = if paymentIndex == 0,
                                         formData.isFirstMonthlyDeposit || formData.isFirstMonthlyRetainer {
                formData.isFirstMonthlyRetainer ? "Retainer" : "Deposit"
            } else {
                isLast ? "Final Payment" : "Monthly Payment #\(paymentIndex + 1)"
            }

            schedule.append(PaymentScheduleItem(
                id: UUID().uuidString,
                description: description,
                amount: paymentAmount,
                vendorName: "Selected Vendor",
                dueDate: paymentDate,
                isPaid: false,
                isRecurring: true))

            remaining -= paymentAmount
            paymentIndex += 1
            if paymentIndex > 100 { break } // Safety break
        }

        return schedule
    }

    // MARK: - Interval Payment Schedule

    private static func calculateIntervalSchedule(formData: PaymentFormData, remainingAmount: Double) -> [PaymentScheduleItem] {
        var schedule: [PaymentScheduleItem] = []
        var remaining = remainingAmount
        var paymentIndex = 0

        let startDate = formData.hasDeposit ?
            Calendar.current.date(byAdding: .month, value: formData.intervalMonths, to: formData.startDate) ?? formData.startDate :
            formData.startDate

        while remaining > 0.01 {
            let paymentAmount = min(formData.intervalAmount, remaining)
            let isLast = paymentAmount >= remaining - 0.01
            let monthsToAdd = paymentIndex * formData.intervalMonths
            let paymentDate = Calendar.current.date(byAdding: .month, value: monthsToAdd, to: startDate) ?? startDate

            // Determine description for first payment (deposit/retainer)
            let description: String = if paymentIndex == 0,
                                         formData.isFirstIntervalDeposit || formData.isFirstIntervalRetainer {
                formData.isFirstIntervalRetainer ? "Retainer" : "Deposit"
            } else {
                isLast ? "Final Payment" : "Interval Payment #\(paymentIndex + 1)"
            }

            schedule.append(PaymentScheduleItem(
                id: UUID().uuidString,
                description: description,
                amount: paymentAmount,
                vendorName: "Selected Vendor",
                dueDate: paymentDate,
                isPaid: false,
                isRecurring: true))

            remaining -= paymentAmount
            paymentIndex += 1
            if paymentIndex > 100 { break } // Safety break
        }

        return schedule
    }

    // MARK: - Cyclical Payment Schedule

    private static func calculateCyclicalSchedule(formData: PaymentFormData, remainingAmount: Double) -> [PaymentScheduleItem] {
        var schedule: [PaymentScheduleItem] = []
        let validPayments = formData.cyclicalPayments.filter { $0.amount > 0 }.sorted { $0.order < $1.order }

        guard !validPayments.isEmpty else { return [] }

        var remaining = remainingAmount
        var cycleIndex = 0
        var paymentCount = 0

        let startDate = formData.hasDeposit ?
            Calendar.current.date(byAdding: .month, value: 1, to: formData.startDate) ?? formData.startDate :
            formData.startDate

        while remaining > 0.01 {
            let cyclicalAmount = validPayments[cycleIndex].amount
            let paymentAmount = min(cyclicalAmount, remaining)
            let isLast = paymentAmount >= remaining - 0.01
            let paymentDate = Calendar.current.date(byAdding: .month, value: paymentCount, to: startDate) ?? startDate

            // Determine description for first payment (deposit/retainer)
            let description: String = if paymentCount == 0,
                                         formData.isFirstCyclicalDeposit || formData.isFirstCyclicalRetainer {
                formData.isFirstCyclicalRetainer ? "Retainer" : "Deposit"
            } else {
                isLast ? "Final Payment" : "Cyclical Payment #\(paymentCount + 1)"
            }

            schedule.append(PaymentScheduleItem(
                id: UUID().uuidString,
                description: description,
                amount: paymentAmount,
                vendorName: "Selected Vendor",
                dueDate: paymentDate,
                isPaid: false,
                isRecurring: true))

            remaining -= paymentAmount
            cycleIndex = (cycleIndex + 1) % validPayments.count
            paymentCount += 1
            if paymentCount > 100 { break } // Safety break
        }

        return schedule
    }
}
