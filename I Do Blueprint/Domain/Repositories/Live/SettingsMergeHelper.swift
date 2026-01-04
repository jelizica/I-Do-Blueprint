//
//  SettingsMergeHelper.swift
//  I Do Blueprint
//
//  Helper for deep merging settings updates
//

import Foundation

/// Helper struct for merging partial settings updates into existing settings
struct SettingsMergeHelper {
    private let logger = AppLogger.repository
    
    func mergeGlobalSettings(current: GlobalSettings, updates: [String: Any]) -> GlobalSettings {
        var merged = current
        if let weddingDate = updates["wedding_date"] as? String { merged.weddingDate = weddingDate }
        if let partner1FullName = updates["partner1_full_name"] as? String { merged.partner1FullName = partner1FullName }
        if let partner1Nickname = updates["partner1_nickname"] as? String { merged.partner1Nickname = partner1Nickname }
        if let partner2FullName = updates["partner2_full_name"] as? String { merged.partner2FullName = partner2FullName }
        if let partner2Nickname = updates["partner2_nickname"] as? String { merged.partner2Nickname = partner2Nickname }
        if let currency = updates["currency"] as? String { merged.currency = currency }
        if let timezone = updates["timezone"] as? String { merged.timezone = timezone }
        return merged
    }

    func mergeThemeSettings(current: ThemeSettings, updates: [String: Any]) -> ThemeSettings {
        var merged = current
        if let colorScheme = updates["color_scheme"] as? String { merged.colorScheme = colorScheme }
        if let darkMode = updates["dark_mode"] as? Bool { merged.darkMode = darkMode }
        if let useCustomWeddingColors = updates["use_custom_wedding_colors"] as? Bool {
            merged.useCustomWeddingColors = useCustomWeddingColors
        }
        if let weddingColor1 = updates["wedding_color_1"] as? String { merged.weddingColor1 = weddingColor1 }
        if let weddingColor2 = updates["wedding_color_2"] as? String { merged.weddingColor2 = weddingColor2 }
        return merged
    }

    func mergeBudgetSettings(current: BudgetSettings, updates: [String: Any]) -> BudgetSettings {
        logger.debug("mergeBudgetSettings called")
        logger.debug("Current tax rates: \(current.taxRates.count)")
        logger.debug("Updates keys: \(updates.keys.joined(separator: ", "))")

        var merged = current
        if let totalBudget = updates["total_budget"] as? Double { merged.totalBudget = totalBudget }
        if let baseBudget = updates["base_budget"] as? Double { merged.baseBudget = baseBudget }
        if let includesEngagementRings = updates["includes_engagement_rings"] as? Bool {
            merged.includesEngagementRings = includesEngagementRings
        }
        if let engagementRingAmount = updates["engagement_ring_amount"] as? Double {
            merged.engagementRingAmount = engagementRingAmount
        }
        if let autoCategorize = updates["auto_categorize"] as? Bool { merged.autoCategorize = autoCategorize }
        if let paymentReminders = updates["payment_reminders"] as? Bool { merged.paymentReminders = paymentReminders }
        if let notes = updates["notes"] as? String { merged.notes = notes }

        // Handle tax_rates array
        if let taxRatesArray = updates["tax_rates"] as? [[String: Any]] {
            logger.debug("Found tax_rates array with \(taxRatesArray.count) items")
            merged.taxRates = taxRatesArray.compactMap { taxRateDict in
                logger.debug("Processing tax rate: \(taxRateDict.keys.joined(separator: ", "))")
                guard let id = taxRateDict["id"] as? String,
                      let name = taxRateDict["name"] as? String,
                      let rate = taxRateDict["rate"] as? Double else {
                    logger.warning("Failed to parse tax rate from dict")
                    return nil
                }
                let isDefault = taxRateDict["is_default"] as? Bool ?? false
                logger.info("Parsed tax rate: \(name) - \(rate)%")
                return SettingsTaxRate(id: id, name: name, rate: rate, isDefault: isDefault)
            }
            logger.debug("Merged tax rates: \(merged.taxRates.count)")
        } else {
            logger.warning("No tax_rates found in updates or wrong type")
        }

        return merged
    }

    func mergeCashFlowSettings(current: CashFlowSettings, updates: [String: Any]) -> CashFlowSettings {
        var merged = current
        if let defaultPartner1Monthly = updates["default_partner1_monthly"] as? Double {
            merged.defaultPartner1Monthly = defaultPartner1Monthly
        }
        if let defaultPartner2Monthly = updates["default_partner2_monthly"] as? Double {
            merged.defaultPartner2Monthly = defaultPartner2Monthly
        }
        if let defaultInterestMonthly = updates["default_interest_monthly"] as? Double {
            merged.defaultInterestMonthly = defaultInterestMonthly
        }
        if let defaultGiftsMonthly = updates["default_gifts_monthly"] as? Double {
            merged.defaultGiftsMonthly = defaultGiftsMonthly
        }
        return merged
    }

    func mergeTasksSettings(current: TasksSettings, updates: [String: Any]) -> TasksSettings {
        var merged = current
        if let defaultView = updates["default_view"] as? String { merged.defaultView = defaultView }
        if let showCompleted = updates["show_completed"] as? Bool { merged.showCompleted = showCompleted }
        if let notificationsEnabled = updates["notifications_enabled"] as? Bool {
            merged.notificationsEnabled = notificationsEnabled
        }
        return merged
    }

    func mergeVendorsSettings(current: VendorsSettings, updates: [String: Any]) -> VendorsSettings {
        var merged = current
        if let defaultView = updates["default_view"] as? String { merged.defaultView = defaultView }
        if let showPaymentStatus = updates["show_payment_status"] as? Bool {
            merged.showPaymentStatus = showPaymentStatus
        }
        if let autoReminders = updates["auto_reminders"] as? Bool { merged.autoReminders = autoReminders }
        return merged
    }

    func mergeGuestsSettings(current: GuestsSettings, updates: [String: Any]) -> GuestsSettings {
        var merged = current
        if let defaultView = updates["default_view"] as? String { merged.defaultView = defaultView }
        if let showMealPreferences = updates["show_meal_preferences"] as? Bool {
            merged.showMealPreferences = showMealPreferences
        }
        if let rsvpReminders = updates["rsvp_reminders"] as? Bool { merged.rsvpReminders = rsvpReminders }
        if let customMealOptions = updates["custom_meal_options"] as? [String] {
            merged.customMealOptions = customMealOptions
        }
        return merged
    }

    func mergeDocumentsSettings(current: DocumentsSettings, updates: [String: Any]) -> DocumentsSettings {
        var merged = current
        if let autoOrganize = updates["auto_organize"] as? Bool { merged.autoOrganize = autoOrganize }
        if let cloudBackup = updates["cloud_backup"] as? Bool { merged.cloudBackup = cloudBackup }
        if let retentionDays = updates["retention_days"] as? Int { merged.retentionDays = retentionDays }
        return merged
    }

    func mergeNotificationsSettings(
        current: NotificationsSettings,
        updates: [String: Any]) -> NotificationsSettings {
        var merged = current
        if let emailEnabled = updates["email_enabled"] as? Bool { merged.emailEnabled = emailEnabled }
        if let pushEnabled = updates["push_enabled"] as? Bool { merged.pushEnabled = pushEnabled }
        if let digestFrequency = updates["digest_frequency"] as? String { merged.digestFrequency = digestFrequency }
        return merged
    }

    func mergeLinksSettings(current: LinksSettings, updates _: [String: Any]) -> LinksSettings {
        current
    }
}
