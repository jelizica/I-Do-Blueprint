//
//  PaymentScheduleFocusedField.swift
//  I Do Blueprint
//
//  Enum for tracking focused fields in payment schedule forms.
//  Defined in a separate file to avoid MainActor isolation issues in previews.
//

import Foundation

/// Enum for tracking focused fields in payment schedule forms
/// This enum is intentionally NOT MainActor-isolated to allow use in #Preview macros
enum PaymentScheduleFocusedField: Hashable, Sendable {
    case partialAmount
    case individualAmount
    case monthlyAmount
    case intervalAmount
    case cyclicalAmount(Int)
    case notes
}
