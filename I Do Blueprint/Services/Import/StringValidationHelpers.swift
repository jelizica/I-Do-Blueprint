//
//  StringValidationHelpers.swift
//  I Do Blueprint
//
//  Pure functions for validating strings from import data
//

import Foundation

/// Pure string validation utilities for import operations
enum StringValidationHelpers {
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Validate phone format (basic validation - at least 10 digits)
    static func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digits.count >= 10
    }
}