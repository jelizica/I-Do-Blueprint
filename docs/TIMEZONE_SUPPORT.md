# Timezone Support Documentation

## Overview

I Do Blueprint now has comprehensive timezone support that allows users to configure their preferred timezone and have all dates/times displayed in that timezone throughout the app.

## Default Timezone

The default timezone is set to **America/Los_Angeles (PST/PDT)** for users based in Seattle, WA. This can be changed by the user in Settings.

## Architecture

### Storage vs Display

- **Database Storage**: All dates are stored in UTC (Coordinated Universal Time) in the Supabase database
- **Display**: Dates are converted to the user's configured timezone for display in the UI
- **User Configuration**: Users can select their timezone in Settings → Global Settings

### Key Components

1. **DateFormatting Utility** (`Utilities/DateFormatting.swift`)
   - Centralized date formatting that respects user timezone
   - Separate methods for display vs database operations
   - Convenience extensions on `Date` type

2. **Settings Model** (`Domain/Models/Settings/SettingsModel.swift`)
   - `GlobalSettings.timezone` stores the user's timezone identifier
   - Default: `"America/Los_Angeles"` (PST/PDT)

3. **Onboarding** (`Domain/Models/Onboarding/OnboardingModels.swift`)
   - New users default to PST/PDT timezone
   - Can be customized during onboarding

## Usage Guide

### For Display (Use User's Timezone)

When displaying dates to the user, always use the user's configured timezone:

```swift
// Get user's timezone from settings
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)

// Format dates for display
let formattedDate = DateFormatting.formatDateLong(date, timezone: userTimezone)
// Output: "January 15, 2025"

let formattedDateTime = DateFormatting.formatDateTime(date, timezone: userTimezone)
// Output: "Jan 15, 2025 at 3:30 PM"

let relativeDate = DateFormatting.formatRelativeDate(date, timezone: userTimezone)
// Output: "Today", "Tomorrow", "In 5 days", etc.
```

### Using Date Extensions

```swift
// Get user's timezone
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)

// Use convenient extensions
let formatted = date.formatted(style: .medium, timezone: userTimezone)
let custom = date.formatted("MMM d, yyyy", timezone: userTimezone)
let relative = date.relativeFormatted(timezone: userTimezone)
```

### For Database Operations (Always Use UTC)

When saving or parsing dates from the database, always use UTC:

```swift
// Saving to database
let dateString = DateFormatting.formatForDatabase(date)
// Output: "2025-01-15" (UTC)

let timestampString = DateFormatting.formatDateTimeForDatabase(date)
// Output: "2025-01-15T20:30:00.000Z" (UTC)

// Parsing from database
if let date = DateFormatting.parseDateFromDatabase("2025-01-15") {
    // Use date (will be in UTC)
}

if let timestamp = DateFormatting.parseDateTimeFromDatabase("2025-01-15T20:30:00.000Z") {
    // Use timestamp (will be in UTC)
}
```

### Calculating Days Between Dates

When calculating days between dates, use the user's timezone to ensure correct day boundaries:

```swift
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)

let daysUntilWedding = DateFormatting.daysBetween(
    from: Date(),
    to: weddingDate,
    in: userTimezone
)
```

## Migration Guide

### Before (Inconsistent Timezone Handling)

```swift
// ❌ Old way - inconsistent timezone usage
let formatter = DateFormatter()
formatter.dateFormat = "MMM d, yyyy"
formatter.timeZone = TimeZone.current // Uses device timezone
let formatted = formatter.string(from: date)
```

### After (Timezone-Aware)

```swift
// ✅ New way - respects user's configured timezone
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)
let formatted = DateFormatting.formatDate(date, format: "MMM d, yyyy", timezone: userTimezone)

// Or use the extension
let formatted = date.formatted("MMM d, yyyy", timezone: userTimezone)
```

## Common Patterns

### In Views

```swift
struct MyView: View {
    @Environment(\.appStores) private var appStores
    
    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: appStores.settings.settings)
    }
    
    var body: some View {
        Text(date.formatted(style: .medium, timezone: userTimezone))
    }
}
```

### In Stores

```swift
@MainActor
class MyStore: ObservableObject {
    @Dependency(\.settingsRepository) var settingsRepository
    
    func formatDateForDisplay(_ date: Date) async -> String {
        let settings = try? await settingsRepository.fetchSettings()
        let timezone = DateFormatting.userTimeZone(from: settings)
        return DateFormatting.formatDateMedium(date, timezone: timezone)
    }
}
```

### In Repositories (Database Operations)

```swift
class LiveRepository {
    func saveEvent(date: Date) async throws {
        // Always use UTC for database
        let dateString = DateFormatting.formatForDatabase(date)
        
        try await supabase.database
            .from("events")
            .insert(["event_date": dateString])
            .execute()
    }
    
    func fetchEvent() async throws -> Date? {
        let row: [String: String] = try await supabase.database
            .from("events")
            .select()
            .single()
            .execute()
            .value
        
        // Parse from UTC
        return DateFormatting.parseDateFromDatabase(row["event_date"] ?? "")
    }
}
```

## Available Formatters

### Display Formatters (Use User's Timezone)

| Method | Example Output | Use Case |
|--------|---------------|----------|
| `formatDateLong()` | "January 15, 2025" | Full date display |
| `formatDateMedium()` | "Jan 15, 2025" | Standard date display |
| `formatDateShort()` | "1/15/25" | Compact date display |
| `formatTime()` | "3:30 PM" | Time only |
| `formatDateTime()` | "Jan 15, 2025 at 3:30 PM" | Date and time |
| `formatRelativeDate()` | "Today", "Tomorrow", "In 5 days" | Relative dates |
| `formatDate(format:)` | Custom | Custom formatting |

### Database Formatters (Always UTC)

| Method | Example Output | Use Case |
|--------|---------------|----------|
| `formatForDatabase()` | "2025-01-15" | Storing dates |
| `formatDateTimeForDatabase()` | "2025-01-15T20:30:00.000Z" | Storing timestamps |
| `parseDateFromDatabase()` | Date object | Reading dates |
| `parseDateTimeFromDatabase()` | Date object | Reading timestamps |

## Testing

When writing tests, you can specify a timezone explicitly:

```swift
func testDateFormatting() {
    let date = Date()
    let pstTimezone = TimeZone(identifier: "America/Los_Angeles")!
    let estTimezone = TimeZone(identifier: "America/New_York")!
    
    let pstFormatted = DateFormatting.formatTime(date, timezone: pstTimezone)
    let estFormatted = DateFormatting.formatTime(date, timezone: estTimezone)
    
    // Times will differ by 3 hours
    XCTAssertNotEqual(pstFormatted, estFormatted)
}
```

## User Configuration

Users can change their timezone in:

**Settings → Global Settings → Timezone**

The timezone picker shows all available timezones sorted alphabetically. Common US timezones include:

- America/Los_Angeles (PST/PDT) - **Default**
- America/Denver (MST/MDT)
- America/Chicago (CST/CDT)
- America/New_York (EST/EDT)
- Pacific/Honolulu (HST)
- America/Anchorage (AKST/AKDT)

## Best Practices

### ✅ Do's

1. **Always use `DateFormatting` utilities** for consistent timezone handling
2. **Store dates in UTC** in the database
3. **Display dates in user's timezone** in the UI
4. **Get timezone from settings** using `DateFormatting.userTimeZone()`
5. **Use relative dates** when appropriate (Today, Tomorrow, etc.)
6. **Test with different timezones** to ensure correct behavior

### ❌ Don'ts

1. **Don't use `TimeZone.current`** for display (use user's configured timezone)
2. **Don't store dates in local timezone** in the database (always UTC)
3. **Don't create new DateFormatter instances** everywhere (use utilities)
4. **Don't assume timezone** - always get it from settings
5. **Don't mix UTC and local times** without clear documentation

## Troubleshooting

### Dates showing wrong time

**Problem**: Dates are showing in UTC instead of user's timezone

**Solution**: Make sure you're using `DateFormatting` utilities with the user's timezone:

```swift
let userTimezone = DateFormatting.userTimeZone(from: settings)
let formatted = date.formatted(style: .medium, timezone: userTimezone)
```

### Day boundaries incorrect

**Problem**: "Today" shows wrong dates

**Solution**: Use timezone-aware day calculations:

```swift
let userTimezone = DateFormatting.userTimeZone(from: settings)
let days = DateFormatting.daysBetween(from: date1, to: date2, in: userTimezone)
```

### Database dates incorrect

**Problem**: Dates saved to database are wrong

**Solution**: Always use UTC for database operations:

```swift
// ✅ Correct
let dateString = DateFormatting.formatForDatabase(date)

// ❌ Wrong
let formatter = DateFormatter()
formatter.timeZone = userTimezone // Don't do this for database!
```

## Future Enhancements

Potential future improvements:

1. **Automatic timezone detection** based on device location
2. **Timezone conversion UI** for destination weddings
3. **Multi-timezone support** for guests in different timezones
4. **Timezone-aware reminders** that respect user's sleep schedule
5. **Daylight saving time warnings** for events near DST transitions

## Related Files

- `Utilities/DateFormatting.swift` - Main date formatting utilities
- `Domain/Models/Settings/SettingsModel.swift` - Settings model with timezone
- `Views/Settings/Sections/GlobalSettingsView.swift` - Timezone picker UI
- `Domain/Models/Onboarding/OnboardingModels.swift` - Onboarding defaults

## Support

For questions or issues with timezone support, please refer to:

- This documentation
- Code comments in `DateFormatting.swift`
- Best practices in `best_practices.md`
