# ADR-005: Timezone-Aware Date Handling

## Status
Accepted

## Context
Wedding planning involves dates and times that are meaningful in specific timezones:
- Wedding date is in the venue's timezone, not the user's current timezone
- Users may plan from different timezones than the wedding location
- Countdown timers and date displays must be accurate
- Database stores dates in UTC, but display must respect user preferences
- Inconsistent timezone handling led to off-by-one-day errors

## Decision
We implemented centralized timezone-aware date handling:

1. **DateFormatting Utility**:
   - Single source of truth for all date operations
   - Located in `Utilities/DateFormatting.swift`
   - Handles timezone conversions consistently

2. **Storage Strategy**:
   - **Database**: Always store in UTC
   - **Display**: Use user's configured timezone
   - **Calculations**: Use user's configured timezone

3. **User Timezone Configuration**:
   - Users can set their preferred timezone in settings
   - Defaults to system timezone if not configured
   - Stored in user settings

4. **API**:
   ```swift
   // Get user's timezone
   let userTimezone = DateFormatting.userTimeZone(from: settings)
   
   // Format for display (uses user's timezone)
   let displayDate = DateFormatting.formatDateMedium(date, timezone: userTimezone)
   let relativeDate = DateFormatting.formatRelativeDate(date, timezone: userTimezone)
   
   // Format for database (always UTC)
   let dbDate = DateFormatting.formatForDatabase(date)
   let dbTimestamp = DateFormatting.formatDateTimeForDatabase(date)
   
   // Parse from database (assumes UTC)
   let parsedDate = DateFormatting.parseDateFromDatabase(dateString)
   
   // Calculate days between dates (timezone-aware)
   let daysUntil = DateFormatting.daysBetween(from: Date(), to: weddingDate, in: userTimezone)
   ```

## Consequences

### Positive
- **Accuracy**: Dates are always displayed correctly regardless of user location
- **Consistency**: All date handling goes through one utility
- **User Control**: Users can set their preferred timezone
- **Database Integrity**: UTC storage prevents timezone ambiguity
- **Testability**: Easy to test with different timezones
- **Maintainability**: Changes to date handling only need to be made in one place

### Negative
- **Complexity**: Developers must remember to use DateFormatting utility
- **Performance**: Timezone conversions add slight overhead
- **Migration**: Existing code needs to be updated to use utility
- **Edge Cases**: Daylight saving time transitions require careful handling

## Implementation Notes

### Rules
1. **Never use `TimeZone.current`** for display - use user's configured timezone
2. **Never store dates in local timezone** in database - always UTC
3. **Always use `DateFormatting` utility** - never format dates directly
4. **Test with different timezones** - especially edge cases like DST transitions

### Common Patterns

#### Display Date
```swift
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)
let formatted = DateFormatting.formatDateMedium(date, timezone: userTimezone)
```

#### Store Date
```swift
let dbString = DateFormatting.formatForDatabase(date)
// Store dbString in database
```

#### Parse Date
```swift
let date = DateFormatting.parseDateFromDatabase(dbString)
```

#### Calculate Days Until Wedding
```swift
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)
let daysUntil = DateFormatting.daysBetween(
    from: Date(),
    to: weddingDate,
    in: userTimezone
)
```

### Testing
- Test with multiple timezones (UTC, EST, PST, JST, etc.)
- Test DST transitions (spring forward, fall back)
- Test date boundaries (midnight, end of day)
- Test leap years and month boundaries

## Migration Checklist
- [ ] Replace `TimeZone.current` with `DateFormatting.userTimeZone()`
- [ ] Replace direct date formatting with `DateFormatting` methods
- [ ] Verify database stores dates in UTC
- [ ] Update date display to use user's timezone
- [ ] Test with different timezones
- [ ] Test DST transitions

## Related Documents
- `best_practices.md` - Section 5: Timezone-Aware Date Formatting
- `TIMEZONE_SUPPORT.md` - Detailed timezone documentation
- `Utilities/DateFormatting.swift` - Date formatting utility
