//
//  DateParsingHelpers.swift
//  I Do Blueprint
//
//  Pure functions for parsing dates from import data
//

import Foundation

/// Pure date parsing utilities for import operations
enum DateParsingHelpers {
    /// Parse date from string (supports multiple formats)
    static func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let dateFormatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "d/M/yyyy"
                return formatter
            }()
        ]

        for formatter in dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }

    /// Parse integer from string
    static func parseInteger(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }

    /// Parse numeric/decimal value from string (for currency, coordinates, etc.)
    static func parseNumeric(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    /// Parse boolean value from string (supports yes/no, true/false, 1/0, y/n)
    static func parseBoolean(_ value: String) -> Bool? {
        let normalized = value.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalized {
        case "true", "yes", "y", "1", "t":
            return true
        case "false", "no", "n", "0", "f", "":
            return false
        default:
            return nil
        }
    }
}