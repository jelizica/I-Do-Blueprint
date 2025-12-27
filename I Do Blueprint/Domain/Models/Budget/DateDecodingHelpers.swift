//
//  DateDecodingHelpers.swift
//  I Do Blueprint
//
//  Shared date decoding utilities for Budget models
//  Consolidates date parsing logic to avoid duplication across Budget.swift and PaymentSchedule+Migration.swift
//

import Foundation

/// Shared namespace for date decoding utilities used across Budget models
enum DateDecodingHelpers {
    
    // MARK: - Cached Date Formatters (Thread-Safe)
    
    /// Static cached formatters - created once and reused
    /// Access is serialized through formatterQueue to ensure thread-safety
    private static let iso8601Formatter = ISO8601DateFormatter()
    
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private static let microsecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private static let secondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// Static array of formatters to avoid repeated allocations
    private static let dateFormatters: [DateFormatter] = [
        dateOnlyFormatter,
        microsecondFormatter,
        secondFormatter
    ]
    
    /// Serial queue to protect formatter access (DateFormatter is not thread-safe)
    private static let formatterQueue = DispatchQueue(label: "com.ido.blueprint.dateDecodingHelpers")
    
    // MARK: - Public Decoding Methods
    
    /// Decode a required date field from a keyed container
    /// - Parameters:
    ///   - container: The keyed decoding container
    ///   - key: The coding key for the date field
    /// - Returns: The decoded Date
    /// - Throws: DecodingError if the date cannot be decoded
    static func decodeDate<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) throws -> Date {
        // Try to decode as Date directly first
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        
        // Fall back to string parsing
        let dateString = try container.decode(String.self, forKey: key)
        return try parseDate(from: dateString)
    }
    
    /// Decode an optional date field from a keyed container
    /// - Parameters:
    ///   - container: The keyed decoding container
    ///   - key: The coding key for the date field
    /// - Returns: The decoded Date, or nil if not present
    /// - Throws: DecodingError if the date string is present but cannot be parsed
    static func decodeDateIfPresent<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) throws -> Date? {
        // Try to decode as Date directly first
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }
        
        // Fall back to string parsing
        guard let dateString = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }
        
        return try parseDate(from: dateString)
    }
    
    /// Parse a date string using multiple format attempts
    /// - Parameter dateString: The date string to parse
    /// - Returns: The parsed Date
    /// - Throws: DecodingError if none of the formats succeed
    static func parseDate(from dateString: String) throws -> Date {
        // Try ISO8601 first (thread-safe, no queue needed)
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // For DateFormatter instances, serialize access through the queue
        return try formatterQueue.sync {
            // Try different date formats using cached static formatters array
            for formatter in dateFormatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to parse date: \(dateString)"
                )
            )
        }
    }
}
