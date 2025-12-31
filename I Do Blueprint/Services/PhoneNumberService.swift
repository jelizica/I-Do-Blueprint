//
//  PhoneNumberService.swift
//  I Do Blueprint
//
//  Created by Claude Code on 12/30/24.
//  Centralized service for phone number formatting, validation, and parsing
//

import Foundation
import PhoneNumberKit

/// Actor-based service for thread-safe phone number operations
/// Uses PhoneNumberKit library for parsing, formatting, and validation
actor PhoneNumberService {
    
    // MARK: - Properties
    
    /// Singleton PhoneNumberUtility instance (expensive to allocate)
    /// Lazily initialized to avoid actor isolation issues
    private lazy var phoneNumberKit = PhoneNumberUtility()
    
    /// Logger for phone number operations
    nonisolated private let logger = AppLogger.general
    
    // MARK: - Public Methods
    
    /// Format a phone number to international standard format
    ///
    /// Converts any phone number format to international standard: +X XXX-XXX-XXXX
    ///
    /// - Parameters:
    ///   - input: Raw phone number string (e.g., "(555) 123-4567", "5551234567")
    ///   - defaultRegion: ISO country code for parsing (default: "US")
    /// - Returns: Formatted phone number string or nil if invalid
    ///
    /// - Example:
    /// ```swift
    /// let service = PhoneNumberService()
    /// let formatted = await service.formatPhoneNumber("(206) 633-7926")
    /// // Returns: "+1 206-633-7926"
    /// ```
    func formatPhoneNumber(_ input: String, defaultRegion: String = "US") -> String? {
        // Handle empty input
        guard !input.isEmpty else {
            logger.debug("Empty phone number input, returning nil")
            return nil
        }
        
        do {
            // Parse the phone number
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: defaultRegion)
            
            // Format to international format
            let formatted = phoneNumberKit.format(phoneNumber, toType: .international)
            
            logger.debug("Successfully formatted phone number: \(input) -> \(formatted) (region: \(defaultRegion))")
            
            return formatted
            
        } catch {
            logger.warning("Failed to format phone number: \(input) (region: \(defaultRegion)) - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Validate if a phone number is valid
    ///
    /// Checks if the phone number is valid according to libphonenumber rules
    ///
    /// - Parameters:
    ///   - input: Phone number string to validate
    ///   - region: ISO country code for validation (default: "US")
    /// - Returns: True if valid, false otherwise
    ///
    /// - Example:
    /// ```swift
    /// let isValid = await service.isValid("+1 555-123-4567")
    /// // Returns: true
    /// ```
    func isValid(_ input: String, region: String = "US") -> Bool {
        guard !input.isEmpty else {
            return false
        }
        
        do {
            // If parsing succeeds, the number is valid
            _ = try phoneNumberKit.parse(input, withRegion: region)
            
            logger.debug("Phone number validation: \(input) (region: \(region)) - valid: true")
            
            return true
            
        } catch {
            logger.debug("Phone number validation failed: \(input) (region: \(region)) - \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get the type of phone number (mobile, landline, etc.)
    ///
    /// - Parameters:
    ///   - input: Phone number string
    ///   - region: ISO country code (default: "US")
    /// - Returns: PhoneNumberType enum or nil if invalid
    ///
    /// - Example:
    /// ```swift
    /// let type = await service.getType("555-123-4567")
    /// // Returns: .mobile or .fixedLine
    /// ```
    func getType(_ input: String, region: String = "US") -> PhoneNumberType? {
        guard !input.isEmpty else {
            return nil
        }
        
        do {
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: region)
            let type = phoneNumber.type
            
            logger.debug("Phone number type detected: \(input) (region: \(region)) - type: \(type)")
            
            return type
            
        } catch {
            logger.debug("Failed to get phone number type: \(input) (region: \(region)) - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Parse a phone number into its components
    ///
    /// Returns a PhoneNumber object with all parsed components
    ///
    /// - Parameters:
    ///   - input: Phone number string
    ///   - region: ISO country code (default: "US")
    /// - Returns: PhoneNumber object or nil if invalid
    ///
    /// - Example:
    /// ```swift
    /// let phoneNumber = await service.parsePhoneNumber("+1 555-123-4567")
    /// print(phoneNumber?.countryCode) // 1
    /// print(phoneNumber?.nationalNumber) // 5551234567
    /// ```
    func parsePhoneNumber(_ input: String, region: String = "US") -> PhoneNumber? {
        guard !input.isEmpty else {
            return nil
        }
        
        do {
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: region)
            
            logger.debug("Successfully parsed phone number: \(input) (region: \(region)) - country: \(phoneNumber.countryCode), national: \(phoneNumber.nationalNumber)")
            
            return phoneNumber
            
        } catch {
            logger.debug("Failed to parse phone number: \(input) (region: \(region)) - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Format a phone number to E.164 format
    ///
    /// E.164 is the international standard format: +[country code][number]
    /// Example: +15551234567
    ///
    /// - Parameters:
    ///   - input: Phone number string
    ///   - defaultRegion: ISO country code (default: "US")
    /// - Returns: E.164 formatted string or nil if invalid
    func formatToE164(_ input: String, defaultRegion: String = "US") -> String? {
        guard !input.isEmpty else {
            return nil
        }
        
        do {
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: defaultRegion)
            let formatted = phoneNumberKit.format(phoneNumber, toType: .e164)
            
            logger.debug("Formatted to E.164: \(input) -> \(formatted)")
            
            return formatted
            
        } catch {
            logger.warning("Failed to format to E.164: \(input) - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Format a phone number to national format
    ///
    /// National format is the local format without country code
    /// Example: (555) 123-4567
    ///
    /// - Parameters:
    ///   - input: Phone number string
    ///   - defaultRegion: ISO country code (default: "US")
    /// - Returns: National formatted string or nil if invalid
    func formatToNational(_ input: String, defaultRegion: String = "US") -> String? {
        guard !input.isEmpty else {
            return nil
        }
        
        do {
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: defaultRegion)
            let formatted = phoneNumberKit.format(phoneNumber, toType: .national)
            
            logger.debug("Formatted to national: \(input) -> \(formatted)")
            
            return formatted
            
        } catch {
            logger.warning("Failed to format to national: \(input) - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get the country code from a phone number
    ///
    /// - Parameters:
    ///   - input: Phone number string
    ///   - region: ISO country code (default: "US")
    /// - Returns: Country calling code (e.g., 1 for US) or nil if invalid
    func getCountryCode(_ input: String, region: String = "US") -> UInt64? {
        guard let phoneNumber = parsePhoneNumber(input, region: region) else {
            return nil
        }
        
        return phoneNumber.countryCode
    }
    
    /// Get the region code (ISO country code) from a phone number
    ///
    /// - Parameters:
    ///   - input: Phone number string
    ///   - region: ISO country code for parsing (default: "US")
    /// - Returns: ISO country code (e.g., "US", "GB") or nil if invalid
    func getRegionCode(_ input: String, region: String = "US") -> String? {
        guard let phoneNumber = parsePhoneNumber(input, region: region) else {
            return nil
        }
        
        return phoneNumberKit.mainCountry(forCode: phoneNumber.countryCode)
    }
}

// MARK: - Convenience Extensions

extension PhoneNumberService {
    
    /// Batch format multiple phone numbers
    ///
    /// Useful for bulk operations like imports
    ///
    /// - Parameters:
    ///   - inputs: Array of phone number strings
    ///   - defaultRegion: ISO country code (default: "US")
    /// - Returns: Array of formatted phone numbers (nil for invalid numbers)
    func batchFormat(_ inputs: [String], defaultRegion: String = "US") async -> [String?] {
        var results: [String?] = []
        
        for input in inputs {
            let formatted = formatPhoneNumber(input, defaultRegion: defaultRegion)
            results.append(formatted)
        }
        
        let successCount = results.compactMap { $0 }.count
        let failCount = results.filter { $0 == nil }.count
        
        logger.info("Batch formatted phone numbers: total=\(inputs.count), successful=\(successCount), failed=\(failCount)")
        
        return results
    }
}
