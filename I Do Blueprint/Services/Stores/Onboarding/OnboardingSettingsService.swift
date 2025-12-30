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
            
            // Update wedding events from onboarding
            if !weddingDetails.weddingEvents.isEmpty {
                // Convert onboarding events to settings events
                settings.global.weddingEvents = weddingDetails.weddingEvents.enumerated().map { index, event in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    return SettingsWeddingEvent(
                        id: event.id,
                        eventName: event.eventName,
                        eventDate: event.eventDate.map { formatter.string(from: $0) } ?? "",
                        eventTime: event.eventTime,
                        venueLocation: event.venueLocation,
                        description: "",
                        isMainEvent: event.isMainEvent,
                        eventOrder: index + 1
                    )
                }
                
                logger.info("Saved \(weddingDetails.weddingEvents.count) wedding events from onboarding")
            } else {
                // Keep default events if none configured in onboarding
                logger.info("No wedding events configured in onboarding, keeping defaults")
            }
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
            
            logger.info("Saved feature preferences: tasks(\(featurePrefs.tasks.defaultView)), vendors(\(featurePrefs.vendors.defaultView)), guests(\(featurePrefs.guests.defaultView))")
        }
        
        // Upsert the settings record (insert or update if exists)
        try await upsertSettings(coupleId: coupleId, settings: settings)
        
        logger.info("Successfully created/updated settings record from onboarding data")
    }
    
    // MARK: - Private Helpers
    
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
