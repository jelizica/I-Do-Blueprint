import Combine
import Foundation
import SwiftUI

// MARK: - Payment Type Enum

enum PaymentType: String, CaseIterable {
    case individual
    case monthly = "simple-recurring"
    case interval = "interval-recurring"
    case cyclical = "cyclical-recurring"

    var displayName: String {
        switch self {
        case .individual: "Individual"
        case .monthly: "Monthly"
        case .interval: "Interval"
        case .cyclical: "Cyclical"
        }
    }

    var databaseValue: String {
        switch self {
        case .individual: "single"
        case .monthly: "monthly"
        case .interval: "custom"
        case .cyclical: "custom"
        }
    }

    var icon: String {
        switch self {
        case .individual: "1.circle.fill"
        case .monthly: "calendar.circle.fill"
        case .interval: "timer.circle.fill"
        case .cyclical: "repeat.circle.fill"
        }
    }
}

// MARK: - Cyclical Payment Model

struct CyclicalPayment: Identifiable, Equatable {
    let id = UUID()
    var amount: Double = 0
    var order: Int
}

// MARK: - Payment Form Data

class PaymentFormData: ObservableObject {
    @Published var paymentType: PaymentType = .individual
    @Published var selectedExpenseId: UUID?
    @Published var totalAmount: Double = 0
    @Published var startDate = Date()

    // Partial payment settings
    @Published var usePartialAmount = false
    @Published var partialAmount: Double = 0

    // Deposit settings
    @Published var hasDeposit = false
    @Published var usePercentage = true
    @Published var depositAmount: Double = 0
    @Published var depositPercentage: Double = 20
    @Published var isDepositRetainer = false

    // Individual payment settings
    @Published var individualAmount: Double = 0
    @Published var isIndividualDeposit = false
    @Published var isIndividualRetainer = false

    // Monthly recurring settings
    @Published var monthlyAmount: Double = 0
    @Published var isFirstMonthlyDeposit = false
    @Published var isFirstMonthlyRetainer = false

    // Interval recurring settings
    @Published var intervalAmount: Double = 0
    @Published var intervalMonths: Int = 1
    @Published var isFirstIntervalDeposit = false
    @Published var isFirstIntervalRetainer = false

    // Cyclical recurring settings
    @Published var cyclicalPayments: [CyclicalPayment] = [CyclicalPayment(order: 1)]
    @Published var isFirstCyclicalDeposit = false
    @Published var isFirstCyclicalRetainer = false

    @Published var notes: String = ""
    @Published var enableReminders = true

    var isValid: Bool {
        guard selectedExpenseId != nil, totalAmount > 0 else { return false }

        switch paymentType {
        case .individual:
            return individualAmount > 0
        case .monthly:
            return monthlyAmount > 0
        case .interval:
            return intervalAmount > 0 && intervalMonths > 0
        case .cyclical:
            return cyclicalPayments.contains { $0.amount > 0 }
        }
    }

    var actualDepositAmount: Double {
        guard hasDeposit else { return 0 }
        let baseAmount = effectiveAmount
        return usePercentage ? (baseAmount * depositPercentage / 100) : depositAmount
    }

    /// The effective amount to use for payment calculations
    /// Returns partial amount if enabled, otherwise full expense amount
    var effectiveAmount: Double {
        usePartialAmount ? partialAmount : totalAmount
    }
}
