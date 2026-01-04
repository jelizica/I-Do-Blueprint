//
//  SettingsModel.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import Foundation

// MARK: - Root Settings Model

struct CoupleSettings: Codable, Equatable {
    var global: GlobalSettings
    var theme: ThemeSettings
    var budget: BudgetSettings
    var cashFlow: CashFlowSettings
    var tasks: TasksSettings
    var vendors: VendorsSettings
    var guests: GuestsSettings
    var documents: DocumentsSettings
    var notifications: NotificationsSettings
    var links: LinksSettings

    enum CodingKeys: String, CodingKey {
        case global = "global"
        case theme = "theme"
        case budget = "budget"
        case cashFlow = "cash_flow"
        case tasks = "tasks"
        case vendors = "vendors"
        case guests = "guests"
        case documents = "documents"
        case notifications = "notifications"
        case links = "links"
    }

    static var `default`: CoupleSettings {
        CoupleSettings(
            global: .default,
            theme: .default,
            budget: .default,
            cashFlow: .default,
            tasks: .default,
            vendors: .default,
            guests: .default,
            documents: .default,
            notifications: .default,
            links: .default)
    }
}

// MARK: - Global Settings

struct GlobalSettings: Codable, Equatable {
    var currency: String
    var weddingDate: String
    var isWeddingDateTBD: Bool
    var timezone: String
    var partner1FullName: String
    var partner1Nickname: String
    var partner2FullName: String
    var partner2Nickname: String
    var weddingEvents: [SettingsWeddingEvent]

    enum CodingKeys: String, CodingKey {
        case currency = "currency"
        case weddingDate = "wedding_date"
        case isWeddingDateTBD = "is_wedding_date_tbd"
        case timezone = "timezone"
        case partner1FullName = "partner1_full_name"
        case partner1Nickname = "partner1_nickname"
        case partner2FullName = "partner2_full_name"
        case partner2Nickname = "partner2_nickname"
        case weddingEvents = "wedding_events"
    }

    static var `default`: GlobalSettings {
        GlobalSettings(
            currency: "USD",
            weddingDate: "",
            isWeddingDateTBD: false,
            timezone: "America/Los_Angeles",
            partner1FullName: "Partner 1",
            partner1Nickname: "",
            partner2FullName: "Partner 2",
            partner2Nickname: "",
            weddingEvents: [
                SettingsWeddingEvent(
                    id: "default-ceremony",
                    eventName: "Wedding Ceremony",
                    eventDate: "",
                    eventTime: "",
                    venueLocation: "",
                    description: "The main wedding ceremony",
                    isMainEvent: true,
                    eventOrder: 1),
                SettingsWeddingEvent(
                    id: "default-reception",
                    eventName: "Wedding Reception",
                    eventDate: "",
                    eventTime: "",
                    venueLocation: "",
                    description: "The wedding reception and celebration",
                    isMainEvent: false,
                    eventOrder: 2)
            ])
    }
}

struct SettingsWeddingEvent: Codable, Equatable, Identifiable {
    let id: String
    var eventName: String
    var eventDate: String
    var eventTime: String
    var venueLocation: String
    var description: String
    var isMainEvent: Bool
    var eventOrder: Int

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case eventName = "event_name"
        case eventDate = "event_date"
        case eventTime = "event_time"
        case venueLocation = "venue_location"
        case description = "description"
        case isMainEvent = "is_main_event"
        case eventOrder = "event_order"
    }
}

// MARK: - Theme Settings

struct ThemeSettings: Codable, Equatable {
    var colorScheme: String
    var darkMode: Bool
    var useCustomWeddingColors: Bool
    var weddingColor1: String  // Hex color code (e.g., "#EAE2FF")
    var weddingColor2: String  // Hex color code (e.g., "#5A9070")

    enum CodingKeys: String, CodingKey {
        case colorScheme = "color_scheme"
        case darkMode = "dark_mode"
        case useCustomWeddingColors = "use_custom_wedding_colors"
        case weddingColor1 = "wedding_color_1"
        case weddingColor2 = "wedding_color_2"
    }

    // Custom decoder to handle both boolean and string values from database
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        colorScheme = try container.decode(String.self, forKey: .colorScheme)

        // Handle dark_mode as either Bool or String "true"/"false"
        if let boolValue = try? container.decode(Bool.self, forKey: .darkMode) {
            darkMode = boolValue
        } else if let stringValue = try? container.decode(String.self, forKey: .darkMode) {
            darkMode = stringValue.lowercased() == "true"
        } else {
            darkMode = false
        }

        // Handle use_custom_wedding_colors
        if let boolValue = try? container.decode(Bool.self, forKey: .useCustomWeddingColors) {
            useCustomWeddingColors = boolValue
        } else if let stringValue = try? container.decode(String.self, forKey: .useCustomWeddingColors) {
            useCustomWeddingColors = stringValue.lowercased() == "true"
        } else {
            useCustomWeddingColors = false
        }

        // Decode wedding colors with defaults
        weddingColor1 = (try? container.decode(String.self, forKey: .weddingColor1)) ?? "#EAE2FF"
        weddingColor2 = (try? container.decode(String.self, forKey: .weddingColor2)) ?? "#5A9070"
    }

    init(colorScheme: String, darkMode: Bool, useCustomWeddingColors: Bool = false, weddingColor1: String = "#EAE2FF", weddingColor2: String = "#5A9070") {
        self.colorScheme = colorScheme
        self.darkMode = darkMode
        self.useCustomWeddingColors = useCustomWeddingColors
        self.weddingColor1 = weddingColor1
        self.weddingColor2 = weddingColor2
    }

    static var `default`: ThemeSettings {
        ThemeSettings(colorScheme: "blush-romance", darkMode: false, useCustomWeddingColors: false, weddingColor1: "#EAE2FF", weddingColor2: "#5A9070")
    }
}

// MARK: - Budget Settings

struct BudgetSettings: Codable, Equatable {
    var totalBudget: Double
    var baseBudget: Double
    var includesEngagementRings: Bool
    var engagementRingAmount: Double
    var autoCategorize: Bool
    var paymentReminders: Bool
    var notes: String
    var taxRates: [SettingsTaxRate]

    enum CodingKeys: String, CodingKey {
        case totalBudget = "total_budget"
        case baseBudget = "base_budget"
        case includesEngagementRings = "includes_engagement_rings"
        case engagementRingAmount = "engagement_ring_amount"
        case autoCategorize = "auto_categorize"
        case paymentReminders = "payment_reminders"
        case notes = "notes"
        case taxRates = "tax_rates"
    }

    static var `default`: BudgetSettings {
        BudgetSettings(
            totalBudget: 50000,
            baseBudget: 50000,
            includesEngagementRings: false,
            engagementRingAmount: 0,
            autoCategorize: true,
            paymentReminders: true,
            notes: "",
            taxRates: [
                SettingsTaxRate(
                    id: "default-sales-tax",
                    name: "Sales Tax",
                    rate: 10.35,
                    isDefault: true)
            ])
    }
}

struct SettingsTaxRate: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var rate: Double
    var isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case rate = "rate"
        case isDefault = "is_default"
    }
}

// MARK: - Cash Flow Settings

struct CashFlowSettings: Codable, Equatable {
    var defaultPartner1Monthly: Double
    var defaultPartner2Monthly: Double
    var defaultInterestMonthly: Double
    var defaultGiftsMonthly: Double

    enum CodingKeys: String, CodingKey {
        case defaultPartner1Monthly = "default_partner1_monthly"
        case defaultPartner2Monthly = "default_partner2_monthly"
        case defaultInterestMonthly = "default_interest_monthly"
        case defaultGiftsMonthly = "default_gifts_monthly"
    }

    static var `default`: CashFlowSettings {
        CashFlowSettings(
            defaultPartner1Monthly: 0,
            defaultPartner2Monthly: 0,
            defaultInterestMonthly: 0,
            defaultGiftsMonthly: 0)
    }
}

// MARK: - Tasks Settings

struct TasksSettings: Codable, Equatable {
    var defaultView: String
    var showCompleted: Bool
    var notificationsEnabled: Bool
    var customResponsibleParties: [String]?

    enum CodingKeys: String, CodingKey {
        case defaultView = "default_view"
        case showCompleted = "show_completed"
        case notificationsEnabled = "notifications_enabled"
        case customResponsibleParties = "custom_responsible_parties"
    }

    static var `default`: TasksSettings {
        TasksSettings(
            defaultView: "kanban",
            showCompleted: false,
            notificationsEnabled: true,
            customResponsibleParties: [])
    }
}

// MARK: - Vendors Settings

struct VendorsSettings: Codable, Equatable {
    var defaultView: String
    var showPaymentStatus: Bool
    var autoReminders: Bool
    var hiddenStandardCategories: [String]?

    enum CodingKeys: String, CodingKey {
        case defaultView = "default_view"
        case showPaymentStatus = "show_payment_status"
        case autoReminders = "auto_reminders"
        case hiddenStandardCategories = "hidden_standard_categories"
    }

    static var `default`: VendorsSettings {
        VendorsSettings(
            defaultView: "grid",
            showPaymentStatus: true,
            autoReminders: true,
            hiddenStandardCategories: [])
    }
}

// MARK: - Guests Settings

struct GuestsSettings: Codable, Equatable {
    var defaultView: String
    var showMealPreferences: Bool
    var rsvpReminders: Bool
    var customMealOptions: [String]

    enum CodingKeys: String, CodingKey {
        case defaultView = "default_view"
        case showMealPreferences = "show_meal_preferences"
        case rsvpReminders = "rsvp_reminders"
        case customMealOptions = "custom_meal_options"
    }

    static var `default`: GuestsSettings {
        GuestsSettings(
            defaultView: "list",
            showMealPreferences: true,
            rsvpReminders: true,
            customMealOptions: ["Chicken", "Beef", "Fish", "Vegetarian", "Vegan"])
    }
}

// MARK: - Documents Settings

struct DocumentsSettings: Codable, Equatable {
    var autoOrganize: Bool
    var cloudBackup: Bool
    var retentionDays: Int
    var vendorBehavior: VendorBehavior

    enum CodingKeys: String, CodingKey {
        case autoOrganize = "auto_organize"
        case cloudBackup = "cloud_backup"
        case retentionDays = "retention_days"
        case vendorBehavior = "vendor_behavior"
    }

    static var `default`: DocumentsSettings {
        DocumentsSettings(
            autoOrganize: true,
            cloudBackup: true,
            retentionDays: 365,
            vendorBehavior: .default)
    }
}

struct VendorBehavior: Codable, Equatable {
    var enforceConsistency: Bool
    var allowInheritance: Bool
    var preferExpenseVendor: Bool
    var enableValidationLogging: Bool

    enum CodingKeys: String, CodingKey {
        case enforceConsistency = "enforce_consistency"
        case allowInheritance = "allow_inheritance"
        case preferExpenseVendor = "prefer_expense_vendor"
        case enableValidationLogging = "enable_validation_logging"
    }

    static var `default`: VendorBehavior {
        VendorBehavior(
            enforceConsistency: false,
            allowInheritance: true,
            preferExpenseVendor: true,
            enableValidationLogging: false)
    }
}

// MARK: - Notifications Settings

struct NotificationsSettings: Codable, Equatable {
    var emailEnabled: Bool
    var pushEnabled: Bool
    var digestFrequency: String

    enum CodingKeys: String, CodingKey {
        case emailEnabled = "email_enabled"
        case pushEnabled = "push_enabled"
        case digestFrequency = "digest_frequency"
    }

    static var `default`: NotificationsSettings {
        NotificationsSettings(
            emailEnabled: true,
            pushEnabled: false,
            digestFrequency: "weekly")
    }
}

// MARK: - Links Settings

struct LinksSettings: Codable, Equatable {
    var importantLinks: [ImportantLink]

    enum CodingKeys: String, CodingKey {
        case importantLinks = "important_links"
    }

    static var `default`: LinksSettings {
        LinksSettings(importantLinks: [])
    }
}

struct ImportantLink: Codable, Equatable, Identifiable {
    let id: String
    var title: String
    var url: String
    var description: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case url = "url"
        case description = "description"
    }
}

// MARK: - Custom Vendor Category

struct CustomVendorCategory: Codable, Equatable, Identifiable {
    let id: String
    let coupleId: String
    var name: String
    var description: String?
    var typicalBudgetPercentage: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case name = "name"
        case description = "description"
        case typicalBudgetPercentage = "typical_budget_percentage"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Phone Formatter Result

struct PhoneFormatResult: Codable, Equatable {
    let message: String
    let vendors: PhoneFormatSection?
    let contacts: PhoneFormatSection?
}

struct PhoneFormatSection: Codable, Equatable {
    let total: Int
    let updated: Int
    let unchanged: Int
    let errors: [PhoneFormatError]
}

struct PhoneFormatError: Codable, Equatable, Identifiable {
    var id: String { "\(vendorId.map(String.init) ?? contactId ?? "unknown")_\(error)" }
    let vendorId: Int?
    let contactId: String?
    let vendorName: String?
    let contactName: String?
    let error: String

    enum CodingKeys: String, CodingKey {
        case vendorId = "vendor_id"
        case contactId = "contact_id"
        case vendorName = "vendor_name"
        case contactName = "contact_name"
        case error = "error"
    }
}
