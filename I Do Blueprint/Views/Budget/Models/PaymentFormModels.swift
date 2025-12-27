import Combine
import Foundation
import SwiftUI

// MARK: - Payment Type Enum

enum PaymentType: String, CaseIterable {
    case individual = "individual"
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
        case .individual: "individual"
        case .monthly: "monthly"
        case .interval: "interval"
        case .cyclical: "cyclical"
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
    
    // MARK: - Backward Compatibility
    
    /// Initialize from database value with backward compatibility for legacy values
    /// Handles migration from old format:
    /// - "single" -> .individual
    /// - "custom" -> .interval (default) or .cyclical (if varying amounts detected)
    init?(fromDatabaseValue value: String) {
        switch value.lowercased() {
        // New canonical values
        case "individual":
            self = .individual
        case "monthly":
            self = .monthly
        case "interval":
            self = .interval
        case "cyclical":
            self = .cyclical
            
        // Legacy value mappings (backward compatibility)
        case "single":
            // Old "single" maps to new "individual"
            self = .individual
            
        case "custom":
            // Old "custom" defaults to "interval"
            // Note: Ambiguous records should be resolved via migration
            // This provides a safe fallback for any unmigrated data
            self = .interval
            
        // Handle deposit/retainer as individual payments
        case "deposit", "retainer":
            self = .individual
            
        default:
            return nil
        }
    }
    
    /// All valid database values (new and legacy)
    static var allDatabaseValues: [String] {
        return [
            // New canonical values
            "individual", "monthly", "interval", "cyclical",
            // Legacy values (for backward compatibility)
            "single", "custom",
            // Special types
            "deposit", "retainer"
        ]
    }
    
    /// Check if a database value is a legacy value that needs migration
    static func isLegacyValue(_ value: String) -> Bool {
        return ["single", "custom"].contains(value.lowercased())
    }
    
    /// Get migration suggestion for a legacy value
    /// - Parameter value: The legacy database value
    /// - Parameter context: Additional context for disambiguation (e.g., payment count, amount uniformity)
    /// - Returns: Suggested PaymentType for migration
    static func migrationSuggestion(
        for value: String,
        paymentCount: Int? = nil,
        hasUniformAmounts: Bool? = nil
    ) -> PaymentType {
        switch value.lowercased() {
        case "single":
            return .individual
            
        case "custom":
            // Use context to disambiguate
            if let count = paymentCount, count == 1 {
                return .individual
            } else if let uniform = hasUniformAmounts, uniform {
                return .interval
            } else {
                return .cyclical
            }
            
        default:
            return .individual
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
