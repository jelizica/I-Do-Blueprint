//
//  OnboardingSettingsService.swift
//  I Do Blueprint
//
//  Service for creating settings from onboarding data
//

import Foundation
import Dependencies
import Supabase

/// Actor managing settings creation from onboarding data
actor OnboardingSettingsService {
    
    // MARK: - Dependencies
    
    private let logger = AppLogger.ui
    
    // MARK: - Create Settings
    
    /// Creates initial settings from onboarding data
    func createSettings(
        coupleId: UUID,
        weddingDetails: WeddingDetails,
        defaultSettings: OnboardingDefaultSettings
    ) async throws {
        logger.info("Creating settings from onboarding data")
        
        // Build complete settings with onboarding data
        var settings = CoupleSettings.default
        
        // Update global settings
        settings.global.currency = defaultSettings.currency
        settings.global.timezone = defaultSettings.timezone
        
        if weddingDetails.isValid {
            settings.global.partner1FullName = weddingDetails.partner1Name
            settings.global.partner1Nickname = weddingDetails.partner1Nickname
            settings.global.partner2FullName = weddingDetails.partner2Name
            settings.global.partner2Nickname = weddingDetails.partner2Nickname
            
            // Save wedding date in YYYY-MM-DD format
            if let weddingDate = weddingDetails.weddingDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(secondsFromGMT: 0) // Use UTC to avoid timezone shifts
                settings.global.weddingDate = formatter.string(from: weddingDate)
                settings.global.isWeddingDateTBD = false
                
                logger.info("Saving wedding date from onboarding: \(settings.global.weddingDate)")
            } else {
                // No date set - mark as TBD
                settings.global.weddingDate = ""
                settings.global.isWeddingDateTBD = true
                
                logger.info("No wedding date set - marking as TBD")
            }
            
            // Create events in the wedding_events database table
            // This is the single source of truth for events
            if !weddingDetails.weddingEvents.isEmpty {
                await createWeddingEventsInDatabase(
                    coupleId: coupleId,
                    events: weddingDetails.weddingEvents,
                    weddingDate: weddingDetails.weddingDate
                )
                logger.info("Created \(weddingDetails.weddingEvents.count) wedding events in database")
            } else {
                // Create default events if none configured in onboarding
                logger.info("No wedding events configured in onboarding, creating defaults")
                
                let defaultEvents = [
                    OnboardingWeddingEvent.defaultCeremony(),
                    OnboardingWeddingEvent.defaultReception()
                ]
                
                await createWeddingEventsInDatabase(
                    coupleId: coupleId,
                    events: defaultEvents,
                    weddingDate: weddingDetails.weddingDate
                )
            }
            
            // Note: We no longer store events in settings.global.weddingEvents
            // The wedding_events table is the single source of truth
            // Clear the settings events to avoid confusion
            settings.global.weddingEvents = []
        }
        
        // Update budget settings
        if let budgetPrefs = defaultSettings.budgetPreferences {
            if let totalBudget = budgetPrefs.totalBudget {
                settings.budget.totalBudget = totalBudget
                settings.budget.baseBudget = totalBudget
            }
            settings.budget.paymentReminders = budgetPrefs.trackPayments
        }
        
        // Update theme settings
        if let themePrefs = defaultSettings.themePreferences {
            settings.theme.colorScheme = themePrefs.colorScheme
            settings.theme.darkMode = themePrefs.darkMode
            
            logger.info("Saved theme preferences: \(themePrefs.colorScheme), dark mode: \(themePrefs.darkMode)")
        }
        
        // Update notification settings
        if let notifPrefs = defaultSettings.notificationPreferences {
            settings.notifications.emailEnabled = notifPrefs.emailEnabled
            settings.notifications.pushEnabled = notifPrefs.pushEnabled
            
            logger.info("Saved notification preferences")
        }
        
        // Update feature preferences
        if let featurePrefs = defaultSettings.featurePreferences {
            settings.tasks = featurePrefs.tasks
            settings.vendors = featurePrefs.vendors
            settings.guests = featurePrefs.guests
            settings.documents = featurePrefs.documents
            
            logger.info("Saved feature preferences")
        }
        
        // Upsert the settings record (insert or update if exists)
        try await upsertSettings(coupleId: coupleId, settings: settings)
        
        logger.info("Successfully created/updated settings record from onboarding data")
    }
    
    // MARK: - Private Helpers
    
    /// Creates wedding events in the wedding_events database table
    /// This is the single source of truth for wedding events
    private func createWeddingEventsInDatabase(
        coupleId: UUID,
        events: [OnboardingWeddingEvent],
        weddingDate: Date?
    ) async {
        guard let client = SupabaseManager.shared.client else {
            logger.error("Supabase client not available for creating wedding events")
            return
        }
        
        for (index, event) in events.enumerated() {
            do {
                // Use event date if set, otherwise use wedding date
                let eventDate = event.eventDate ?? weddingDate ?? Date()
                
                // Create the database event record using the event type directly
                let dbEvent = WeddingEventInsert(
                    id: UUID().uuidString, // Generate new UUID for database
                    event_name: event.eventName,
                    event_type: event.eventType.rawValue, // Use the enum's raw value
                    event_date: eventDate,
                    start_time: parseTime(event.eventTime),
                    end_time: nil,
                    venue_name: event.venueLocation.isEmpty ? nil : event.venueLocation,
                    notes: event.notes.isEmpty ? nil : event.notes, // Store notes for "other" type
                    is_main_event: event.isMainEvent,
                    event_order: index + 1,
                    couple_id: coupleId.uuidString
                )
                
                try await client
                    .from("wedding_events")
                    .insert(dbEvent)
                    .execute()
                
                logger.info("Created wedding event in database: \(event.eventName) (type: \(event.eventType.rawValue))")
            } catch {
                // Log error but don't fail onboarding - events can be created later
                logger.error("Failed to create wedding event '\(event.eventName)' in database", error: error)
            }
        }
    }
    
    /// Parses time string to Date (for start_time field)
    private func parseTime(_ timeString: String) -> Date? {
        guard !timeString.isEmpty else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try various time formats
        let formats = ["h:mm a", "H:mm", "h:mma", "HH:mm"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                return date
            }
        }
        
        return nil
    }
    
    /// Upserts settings to database
    private func upsertSettings(coupleId: UUID, settings: CoupleSettings) async throws {
        struct SettingsUpsert: Encodable {
            let couple_id: UUID
            let settings: CoupleSettings
            let schema_version: Int
        }
        
        let upsert = SettingsUpsert(
            couple_id: coupleId,
            settings: settings,
            schema_version: 1
        )
        
        guard let client = SupabaseManager.shared.client else {
            logger.error("Supabase client not available")
            throw OnboardingError.saveFailed(underlying: NSError(
                domain: "OnboardingSettingsService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Supabase client not available"]
            ))
        }
        
        try await client
            .from("couple_settings")
            .upsert(upsert, onConflict: "couple_id")
            .execute()
    }
}

// MARK: - Wedding Event Insert Model

/// Model for inserting wedding events into the database
private struct WeddingEventInsert: Encodable {
    let id: String
    let event_name: String
    let event_type: String
    let event_date: Date
    let start_time: Date?
    let end_time: Date?
    let venue_name: String?
    let notes: String?
    let is_main_event: Bool
    let event_order: Int
    let couple_id: String
}
