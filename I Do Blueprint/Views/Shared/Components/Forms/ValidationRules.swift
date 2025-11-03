//
//  ValidationRules.swift
//  I Do Blueprint
//
//  Validation rules for form fields
//

import Foundation

/// Result of a validation check
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?

    static let valid = ValidationResult(isValid: true, errorMessage: nil)

    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
}

/// Protocol for validation rules
protocol ValidationRule {
    func validate(_ value: String) -> ValidationResult
}

// MARK: - Basic Validation Rules

/// Validates that a field is not empty
struct RequiredRule: ValidationRule {
    let fieldName: String

    init(fieldName: String = "This field") {
        self.fieldName = fieldName
    }

    func validate(_ value: String) -> ValidationResult {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid("\(fieldName) is required")
        }
        return .valid
    }
}

/// Validates email format
struct EmailRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if !predicate.evaluate(with: value) {
            return .invalid("Please enter a valid email address")
        }
        return .valid
    }
}

/// Validates minimum length
struct MinLengthRule: ValidationRule {
    let minLength: Int
    let fieldName: String

    init(minLength: Int, fieldName: String = "This field") {
        self.minLength = minLength
        self.fieldName = fieldName
    }

    func validate(_ value: String) -> ValidationResult {
        if value.count < minLength {
            return .invalid("\(fieldName) must be at least \(minLength) characters")
        }
        return .valid
    }
}

/// Validates maximum length
struct MaxLengthRule: ValidationRule {
    let maxLength: Int
    let fieldName: String

    init(maxLength: Int, fieldName: String = "This field") {
        self.maxLength = maxLength
        self.fieldName = fieldName
    }

    func validate(_ value: String) -> ValidationResult {
        if value.count > maxLength {
            return .invalid("\(fieldName) must be no more than \(maxLength) characters")
        }
        return .valid
    }
}

/// Validates phone number format
struct PhoneRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        // Remove common formatting characters
        let cleaned = value.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        // Check if it's a valid length (10-15 digits)
        if cleaned.count < 10 || cleaned.count > 15 {
            return .invalid("Please enter a valid phone number")
        }
        return .valid
    }
}

/// Validates URL format
struct URLRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        guard let url = URL(string: value),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return .invalid("Please enter a valid URL (e.g., https://example.com)")
        }
        return .valid
    }
}

/// Validates numeric input
struct NumericRule: ValidationRule {
    let allowDecimal: Bool
    let allowNegative: Bool

    init(allowDecimal: Bool = true, allowNegative: Bool = false) {
        self.allowDecimal = allowDecimal
        self.allowNegative = allowNegative
    }

    func validate(_ value: String) -> ValidationResult {
        let pattern = allowDecimal ? "[0-9]*\\.?[0-9]+" : "[0-9]+"
        let fullPattern = allowNegative ? "-?\(pattern)" : pattern

        let predicate = NSPredicate(format: "SELF MATCHES %@", fullPattern)

        if !predicate.evaluate(with: value) {
            return .invalid("Please enter a valid number")
        }
        return .valid
    }
}

/// Validates currency amount
struct CurrencyRule: ValidationRule {
    let minAmount: Double?
    let maxAmount: Double?

    init(minAmount: Double? = nil, maxAmount: Double? = nil) {
        self.minAmount = minAmount
        self.maxAmount = maxAmount
    }

    func validate(_ value: String) -> ValidationResult {
        // Remove currency symbols and commas
        let cleaned = value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)

        guard let amount = Double(cleaned) else {
            return .invalid("Please enter a valid amount")
        }

        if let min = minAmount, amount < min {
            return .invalid("Amount must be at least $\(String(format: "%.2f", min))")
        }

        if let max = maxAmount, amount > max {
            return .invalid("Amount must be no more than $\(String(format: "%.2f", max))")
        }

        return .valid
    }
}

/// Validates date format
struct DateRule: ValidationRule {
    let format: String

    init(format: String = "MM/dd/yyyy") {
        self.format = format
    }

    func validate(_ value: String) -> ValidationResult {
        let formatter = DateFormatter()
        formatter.dateFormat = format

        if formatter.date(from: value) == nil {
            return .invalid("Please enter a valid date (\(format))")
        }
        return .valid
    }
}

// MARK: - Composite Validation Rules

/// Combines multiple validation rules
struct CompositeRule: ValidationRule {
    let rules: [ValidationRule]

    init(rules: [ValidationRule]) {
        self.rules = rules
    }

    func validate(_ value: String) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                return result
            }
        }
        return .valid
    }
}

// MARK: - Convenience Extensions

extension ValidationRule {
    /// Combines this rule with another rule
    func and(_ other: ValidationRule) -> ValidationRule {
        CompositeRule(rules: [self, other])
    }
}

// MARK: - Common Rule Combinations

extension ValidationRule where Self == CompositeRule {
    /// Required email validation
    static var requiredEmail: ValidationRule {
        CompositeRule(rules: [
            RequiredRule(fieldName: "Email"),
            EmailRule()
        ])
    }

    /// Required phone validation
    static var requiredPhone: ValidationRule {
        CompositeRule(rules: [
            RequiredRule(fieldName: "Phone"),
            PhoneRule()
        ])
    }

    /// Required URL validation
    static var requiredURL: ValidationRule {
        CompositeRule(rules: [
            RequiredRule(fieldName: "URL"),
            URLRule()
        ])
    }

    /// Required name validation (2-50 characters)
    static var requiredName: ValidationRule {
        CompositeRule(rules: [
            RequiredRule(fieldName: "Name"),
            MinLengthRule(minLength: 2, fieldName: "Name"),
            MaxLengthRule(maxLength: 50, fieldName: "Name")
        ])
    }

    /// Required currency validation (positive amounts only)
    static var requiredCurrency: ValidationRule {
        CompositeRule(rules: [
            RequiredRule(fieldName: "Amount"),
            CurrencyRule(minAmount: 0)
        ])
    }
}
