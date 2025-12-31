//
//  TimelineDateParser.swift
//  I Do Blueprint
//
//  Date parsing utilities for timeline data
//

import Foundation

/// Utility for parsing dates from various formats used in timeline data
struct TimelineDateParser {
    
    /// Parse a date from yyyy-MM-dd format
    static func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    /// Parse an ISO8601 date with multiple fallback formats
    static func iso8601DateFromString(_ dateString: String) -> Date? {
        // Try ISO8601DateFormatter first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Fallback to DateFormatter for Postgres timestamp format
        let postgresFormatter = DateFormatter()
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        if let date = postgresFormatter.date(from: dateString) {
            return date
        }
        
        // Another fallback without fractional seconds
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        return postgresFormatter.date(from: dateString)
    }
    
    /// Format a date to yyyy-MM-dd string
    static func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
