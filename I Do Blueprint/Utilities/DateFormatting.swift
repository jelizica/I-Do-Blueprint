//
//  DateFormatting.swift
//  I Do Blueprint
//
//  Centralized date formatting utilities that respect user timezone preferences
//

import Foundation

/// Centralized date formatting utilities that respect user timezone preferences
/// All date display should use these formatters to ensure consistent timezone handling
enum DateFormatting {
    
    // MARK: - Formatter Cache
    
    /// Thread-safe cache for DateFormatter instances to avoid expensive recreation
    private static let formatterCache = NSCache<NSString, DateFormatter>()
    
    /// Generate a cache key for formatter configuration
    private static func cacheKey(
        dateStyle: DateFormatter.Style? = nil,
        timeStyle: DateFormatter.Style? = nil,
        dateFormat: String? = nil,
        timezone: TimeZone,
        locale: Locale? = nil
    ) -> String {
        var key = "tz:\(timezone.identifier)"
        if let dateStyle = dateStyle {
            key += "_ds:\(dateStyle.rawValue)"
        }
        if let timeStyle = timeStyle {
            key += "_ts:\(timeStyle.rawValue)"
        }
        if let dateFormat = dateFormat {
            key += "_df:\(dateFormat)"
        }
        key += "_loc:\(locale?.identifier ?? "default")"
        return key
    }
    
    /// Get or create a cached DateFormatter with the specified configuration
    private static func formatter(
        dateStyle: DateFormatter.Style? = nil,
        timeStyle: DateFormatter.Style? = nil,
        dateFormat: String? = nil,
        timezone: TimeZone,
        locale: Locale? = nil
    ) -> DateFormatter {
        let key = cacheKey(
            dateStyle: dateStyle,
            timeStyle: timeStyle,
            dateFormat: dateFormat,
            timezone: timezone,
            locale: locale
        )
        
        if let cached = formatterCache.object(forKey: key as NSString) {
            return cached
        }
        
        let formatter = DateFormatter()
        
        if let dateStyle = dateStyle {
            formatter.dateStyle = dateStyle
        }
        if let timeStyle = timeStyle {
            formatter.timeStyle = timeStyle
        }
        if let dateFormat = dateFormat {
            formatter.dateFormat = dateFormat
            // Use POSIX locale for custom formats to ensure consistency
            formatter.locale = locale ?? Locale(identifier: "en_US_POSIX")
        }
        
        formatter.timeZone = timezone
        
        formatterCache.setObject(formatter, forKey: key as NSString)
        return formatter
    }
    
    // MARK: - Timezone Management
    
    /// Get the user's configured timezone from settings, with fallback to PST/PDT (Seattle)
    /// - Parameter settings: The user's couple settings
    /// - Returns: TimeZone configured by user, or America/Los_Angeles if not set
    static func userTimeZone(from settings: CoupleSettings?) -> TimeZone {
        guard let settings = settings else {
            return TimeZone(identifier: "America/Los_Angeles") ?? TimeZone.current
        }
        
        let timezoneIdentifier = settings.global.timezone
        
        // If timezone is empty or invalid, default to PST/PDT (Seattle)
        if timezoneIdentifier.isEmpty {
            return TimeZone(identifier: "America/Los_Angeles") ?? TimeZone.current
        }
        
        return TimeZone(identifier: timezoneIdentifier) ?? TimeZone(identifier: "America/Los_Angeles") ?? TimeZone.current
    }
    
    /// UTC timezone for database operations (always use this for storing dates)
    /// Uses UTC identifier with fallback to GMT offset, then system timezone as last resort
    static let utcTimeZone: TimeZone = {
        TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? TimeZone.current
    }()
    
    // MARK: - Display Formatters (Use User's Timezone)
    
    /// Format a date for display using the user's configured timezone
    /// Example: "January 15, 2025"
    static func formatDateLong(_ date: Date, timezone: TimeZone) -> String {
        let formatter = formatter(dateStyle: .long, timeStyle: .none, timezone: timezone)
        return formatter.string(from: date)
    }
    
    /// Format a date for display using the user's configured timezone
    /// Example: "Jan 15, 2025"
    static func formatDateMedium(_ date: Date, timezone: TimeZone) -> String {
        let formatter = formatter(dateStyle: .medium, timeStyle: .none, timezone: timezone)
        return formatter.string(from: date)
    }
    
    /// Format a date for display using the user's configured timezone
    /// Example: "1/15/25"
    static func formatDateShort(_ date: Date, timezone: TimeZone) -> String {
        let formatter = formatter(dateStyle: .short, timeStyle: .none, timezone: timezone)
        return formatter.string(from: date)
    }
    
    /// Format a date with custom format using the user's configured timezone
    /// Example: "MMM d, yyyy" → "Jan 15, 2025"
    static func formatDate(_ date: Date, format: String, timezone: TimeZone) -> String {
        let formatter = formatter(dateFormat: format, timezone: timezone)
        return formatter.string(from: date)
    }
    
    /// Format a time for display using the user's configured timezone
    /// Example: "3:30 PM"
    static func formatTime(_ date: Date, timezone: TimeZone) -> String {
        let formatter = formatter(dateStyle: .none, timeStyle: .short, timezone: timezone)
        return formatter.string(from: date)
    }
    
    /// Format a date and time for display using the user's configured timezone
    /// Example: "Jan 15, 2025 at 3:30 PM"
    static func formatDateTime(_ date: Date, timezone: TimeZone) -> String {
        let formatter = formatter(dateStyle: .medium, timeStyle: .short, timezone: timezone)
        return formatter.string(from: date)
    }
    
    /// Format a relative date (e.g., "Today", "Tomorrow", "In 5 days")
    /// Uses the user's timezone to determine "today"
    static func formatRelativeDate(_ date: Date, timezone: TimeZone) -> String {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if days > 0 && days <= 7 {
                return "In \(days) days"
            } else if days < 0 && days >= -7 {
                return "\(abs(days)) days ago"
            } else {
                return formatDateMedium(date, timezone: timezone)
            }
        }
    }
    
    // MARK: - Database Formatters (Always Use UTC)
    
    /// Format a date for database storage (always UTC, YYYY-MM-DD format)
    /// Use this when saving dates to Supabase
    static func formatForDatabase(_ date: Date) -> String {
        let formatter = formatter(dateFormat: "yyyy-MM-dd", timezone: utcTimeZone)
        return formatter.string(from: date)
    }
    
    /// Format a datetime for database storage (always UTC, ISO8601 format)
    /// Use this when saving timestamps to Supabase
    static func formatDateTimeForDatabase(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = utcTimeZone
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    /// Parse a date from database (assumes UTC, YYYY-MM-DD format)
    /// Use this when reading dates from Supabase
    /// 
    /// IMPORTANT: For date-only strings (YYYY-MM-DD), we add 12 hours to prevent
    /// timezone day-shifting. This ensures "2025-12-01" displays as Dec 1 in any
    /// timezone from UTC-12 to UTC+14.
    static func parseDateFromDatabase(_ dateString: String) -> Date? {
        let formatter = formatter(dateFormat: "yyyy-MM-dd", timezone: utcTimeZone)
        guard let date = formatter.date(from: dateString) else {
            return nil
        }
        // Add 12 hours (noon UTC) to prevent the date from shifting
        // when displayed in timezones behind UTC (like PST which is UTC-8)
        return date.addingTimeInterval(12 * 60 * 60)
    }
    
    /// Parse a datetime from database (assumes UTC, ISO8601 format)
    /// Use this when reading timestamps from Supabase
    static func parseDateTimeFromDatabase(_ dateString: String) -> Date? {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.timeZone = utcTimeZone
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Fallback to standard format without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        return iso8601Formatter.date(from: dateString)
    }
    
    // MARK: - Convenience Methods
    
    /// Get the start of day for a date in the user's timezone
    static func startOfDay(for date: Date, in timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.startOfDay(for: date)
    }
    
    /// Get the end of day for a date in the user's timezone
    /// Returns the start of the next day, suitable for exclusive range comparisons (e.g., date < endOfDay)
    /// This approach is DST-safe and avoids issues with 23:59:59 boundaries
    static func endOfDay(for date: Date, in timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
    }
    
    /// Calculate days between two dates in the user's timezone
    static func daysBetween(from: Date, to: Date, in timezone: TimeZone) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        let fromStart = calendar.startOfDay(for: from)
        let toStart = calendar.startOfDay(for: to)
        
        return calendar.dateComponents([.day], from: fromStart, to: toStart).day ?? 0
    }
}

// MARK: - Extension for Easy Access

extension Date {
    /// Format this date for display in the user's timezone
    func formatted(style: DateFormatter.Style = .medium, timezone: TimeZone) -> String {
        switch style {
        case .short:
            return DateFormatting.formatDateShort(self, timezone: timezone)
        case .medium:
            return DateFormatting.formatDateMedium(self, timezone: timezone)
        case .long:
            return DateFormatting.formatDateLong(self, timezone: timezone)
        default:
            return DateFormatting.formatDateMedium(self, timezone: timezone)
        }
    }
    
    /// Format this date with a custom format in the user's timezone
    func formatted(_ format: String, timezone: TimeZone) -> String {
        return DateFormatting.formatDate(self, format: format, timezone: timezone)
    }
    
    /// Format this date as a relative string (e.g., "Today", "Tomorrow")
    func relativeFormatted(timezone: TimeZone) -> String {
        return DateFormatting.formatRelativeDate(self, timezone: timezone)
    }
}
