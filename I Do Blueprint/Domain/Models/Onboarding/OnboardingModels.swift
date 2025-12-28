//
//  OnboardingModels.swift
//  I Do Blueprint
//
//  Domain models for onboarding flow
//

import Foundation

// MARK: - Onboarding Progress

/// Tracks user progress through the onboarding flow
struct OnboardingProgress: Codable, Equatable {
    let id: UUID
    let coupleId: UUID
    var currentStep: OnboardingStep
    var completedSteps: Set<OnboardingStep>
    var isCompleted: Bool
    var weddingDetails: WeddingDetails?
    var defaultSettings: OnboardingDefaultSettings?
    var guestImportStatus: ImportStatus?
    var vendorImportStatus: ImportStatus?
    var budgetSetupStatus: BudgetSetupStatus?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        coupleId: UUID,
        currentStep: OnboardingStep = .welcome,
        completedSteps: Set<OnboardingStep> = [],
        isCompleted: Bool = false,
        weddingDetails: WeddingDetails? = nil,
        defaultSettings: OnboardingDefaultSettings? = nil,
        guestImportStatus: ImportStatus? = nil,
        vendorImportStatus: ImportStatus? = nil,
        budgetSetupStatus: BudgetSetupStatus? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.coupleId = coupleId
        self.currentStep = currentStep
        self.completedSteps = completedSteps
        self.isCompleted = isCompleted
        self.weddingDetails = weddingDetails
        self.defaultSettings = defaultSettings
        self.guestImportStatus = guestImportStatus
        self.vendorImportStatus = vendorImportStatus
        self.budgetSetupStatus = budgetSetupStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Onboarding Step

/// Represents each step in the onboarding flow
enum OnboardingStep: String, Codable, CaseIterable, Hashable {
    case welcome = "welcome"
    case weddingDetails = "weddingDetails"
    case defaultSettings = "defaultSettings"
    case featurePreferences = "featurePreferences"
    case guestImport = "guestImport"
    case vendorImport = "vendorImport"
    case budgetSetup = "budgetSetup"
    case completion = "completion"

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .weddingDetails: return "Wedding Details"
        case .defaultSettings: return "Default Settings"
        case .featurePreferences: return "Feature Preferences"
        case .guestImport: return "Import Guests"
        case .vendorImport: return "Import Vendors"
        case .budgetSetup: return "Budget Setup"
        case .completion: return "All Set!"
        }
    }

    var description: String {
        switch self {
        case .welcome:
            return "Welcome to I Do Blueprint! Let's get started planning your perfect wedding."
        case .weddingDetails:
            return "Tell us about your wedding day."
        case .defaultSettings:
            return "Configure your preferences."
        case .featurePreferences:
            return "Customize how you want to use each feature."
        case .guestImport:
            return "Import your guest list (optional)."
        case .vendorImport:
            return "Import your vendor list (optional)."
        case .budgetSetup:
            return "Set up your wedding budget."
        case .completion:
            return "You're all set! Let's start planning."
        }
    }

    var isOptional: Bool {
        switch self {
        case .guestImport, .vendorImport, .featurePreferences:
            return true
        default:
            return false
        }
    }

    var nextStep: OnboardingStep? {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: self),
              currentIndex < allSteps.count - 1 else {
            return nil
        }
        return allSteps[currentIndex + 1]
    }

    var previousStep: OnboardingStep? {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: self),
              currentIndex > 0 else {
            return nil
        }
        return allSteps[currentIndex - 1]
    }
}

// MARK: - Wedding Details

/// Wedding details captured during onboarding
struct WeddingDetails: Codable, Equatable {
    var weddingDate: Date?
    var isWeddingDateTBD: Bool
    var venue: String
    var partner1Name: String
    var partner1Nickname: String
    var partner2Name: String
    var partner2Nickname: String
    var weddingStyle: WeddingStyle?
    var estimatedGuestCount: Int?
    var weddingEvents: [OnboardingWeddingEvent]

    init(
        weddingDate: Date? = nil,
        isWeddingDateTBD: Bool = false,
        venue: String = "",
        partner1Name: String = "",
        partner1Nickname: String = "",
        partner2Name: String = "",
        partner2Nickname: String = "",
        weddingStyle: WeddingStyle? = nil,
        estimatedGuestCount: Int? = nil,
        weddingEvents: [OnboardingWeddingEvent] = []
    ) {
        self.weddingDate = weddingDate
        self.isWeddingDateTBD = isWeddingDateTBD
        self.venue = venue
        self.partner1Name = partner1Name
        self.partner1Nickname = partner1Nickname
        self.partner2Name = partner2Name
        self.partner2Nickname = partner2Nickname
        self.weddingStyle = weddingStyle
        self.estimatedGuestCount = estimatedGuestCount
        self.weddingEvents = weddingEvents
    }

    var isValid: Bool {
        // Partner names are required (trim whitespace)
        // Wedding date is required UNLESS TBD is checked
        let name1 = partner1Name.trimmingCharacters(in: .whitespaces)
        let name2 = partner2Name.trimmingCharacters(in: .whitespaces)
        return !name1.isEmpty && !name2.isEmpty && (isWeddingDateTBD || weddingDate != nil)
    }
}

// MARK: - Onboarding Wedding Event

/// Wedding event captured during onboarding (simplified version of SettingsWeddingEvent)
struct OnboardingWeddingEvent: Codable, Equatable, Identifiable {
    let id: String
    var eventName: String
    var eventDate: Date?
    var eventTime: String
    var venueLocation: String
    var isMainEvent: Bool

    init(
        id: String = UUID().uuidString,
        eventName: String,
        eventDate: Date? = nil,
        eventTime: String = "",
        venueLocation: String = "",
        isMainEvent: Bool = false
    ) {
        self.id = id
        self.eventName = eventName
        self.eventDate = eventDate
        self.eventTime = eventTime
        self.venueLocation = venueLocation
        self.isMainEvent = isMainEvent
    }

    /// Creates default ceremony event
    static func defaultCeremony() -> OnboardingWeddingEvent {
        OnboardingWeddingEvent(
            id: "default-ceremony",
            eventName: "Wedding Ceremony",
            isMainEvent: true
        )
    }

    /// Creates default reception event
    static func defaultReception() -> OnboardingWeddingEvent {
        OnboardingWeddingEvent(
            id: "default-reception",
            eventName: "Wedding Reception",
            isMainEvent: false
        )
    }
}

// MARK: - Wedding Style

enum WeddingStyle: String, Codable, CaseIterable {
    case traditional = "traditional"
    case modern = "modern"
    case rustic = "rustic"
    case beach = "beach"
    case garden = "garden"
    case destination = "destination"
    case intimate = "intimate"
    case formal = "formal"

    var displayName: String {
        switch self {
        case .traditional: return "Traditional"
        case .modern: return "Modern"
        case .rustic: return "Rustic"
        case .beach: return "Beach"
        case .garden: return "Garden"
        case .destination: return "Destination"
        case .intimate: return "Intimate"
        case .formal: return "Formal"
        }
    }

    var icon: String {
        switch self {
        case .traditional: return "building.columns"
        case .modern: return "sparkles"
        case .rustic: return "leaf"
        case .beach: return "sun.max"
        case .garden: return "leaf.fill"
        case .destination: return "airplane"
        case .intimate: return "heart"
        case .formal: return "crown"
        }
    }
}

// MARK: - Onboarding Default Settings

/// Default settings configured during onboarding
struct OnboardingDefaultSettings: Codable, Equatable {
    var currency: String
    var timezone: String
    var themePreferences: ThemeSettings?
    var budgetPreferences: BudgetPreferences?
    var notificationPreferences: NotificationPreferences?
    var featurePreferences: FeaturePreferences?

    init(
        currency: String = "USD",
        timezone: String = "America/Los_Angeles",
        themePreferences: ThemeSettings? = nil,
        budgetPreferences: BudgetPreferences? = nil,
        notificationPreferences: NotificationPreferences? = nil,
        featurePreferences: FeaturePreferences? = nil
    ) {
        self.currency = currency
        self.timezone = timezone
        self.themePreferences = themePreferences
        self.budgetPreferences = budgetPreferences
        self.notificationPreferences = notificationPreferences
        self.featurePreferences = featurePreferences
    }
}

// MARK: - Feature Preferences

/// Feature-specific preferences configured during onboarding
struct FeaturePreferences: Codable, Equatable {
    var tasks: TasksSettings
    var vendors: VendorsSettings
    var guests: GuestsSettings
    var documents: DocumentsSettings

    init(
        tasks: TasksSettings = TasksSettings.default,
        vendors: VendorsSettings = VendorsSettings.default,
        guests: GuestsSettings = GuestsSettings.default,
        documents: DocumentsSettings = DocumentsSettings.default
    ) {
        self.tasks = tasks
        self.vendors = vendors
        self.guests = guests
        self.documents = documents
    }
}

// MARK: - Budget Preferences

struct BudgetPreferences: Codable, Equatable {
    var totalBudget: Double?
    var trackPayments: Bool
    var enableAlerts: Bool
    var alertThreshold: Double

    init(
        totalBudget: Double? = nil,
        trackPayments: Bool = true,
        enableAlerts: Bool = true,
        alertThreshold: Double = 0.9
    ) {
        self.totalBudget = totalBudget
        self.trackPayments = trackPayments
        self.enableAlerts = enableAlerts
        self.alertThreshold = alertThreshold
    }
}

// MARK: - Notification Preferences

struct NotificationPreferences: Codable, Equatable {
    var emailEnabled: Bool
    var pushEnabled: Bool
    var taskReminders: Bool
    var paymentReminders: Bool
    var eventReminders: Bool

    init(
        emailEnabled: Bool = true,
        pushEnabled: Bool = true,
        taskReminders: Bool = true,
        paymentReminders: Bool = true,
        eventReminders: Bool = true
    ) {
        self.emailEnabled = emailEnabled
        self.pushEnabled = pushEnabled
        self.taskReminders = taskReminders
        self.paymentReminders = paymentReminders
        self.eventReminders = eventReminders
    }
}

// MARK: - Import Status

/// Tracks the status of guest/vendor imports
struct ImportStatus: Codable, Equatable {
    var isStarted: Bool
    var isCompleted: Bool
    var totalRows: Int
    var successfulRows: Int
    var failedRows: Int
    var errors: [ImportError]

    init(
        isStarted: Bool = false,
        isCompleted: Bool = false,
        totalRows: Int = 0,
        successfulRows: Int = 0,
        failedRows: Int = 0,
        errors: [ImportError] = []
    ) {
        self.isStarted = isStarted
        self.isCompleted = isCompleted
        self.totalRows = totalRows
        self.successfulRows = successfulRows
        self.failedRows = failedRows
        self.errors = errors
    }

    var progress: Double {
        guard totalRows > 0 else { return 0 }
        return Double(successfulRows + failedRows) / Double(totalRows)
    }
}

// MARK: - Import Error

struct ImportError: Codable, Equatable, Identifiable {
    let id: UUID
    let lineNumber: Int
    let message: String
    let field: String?

    init(
        id: UUID = UUID(),
        lineNumber: Int,
        message: String,
        field: String? = nil
    ) {
        self.id = id
        self.lineNumber = lineNumber
        self.message = message
        self.field = field
    }
}

// MARK: - Budget Setup Status

struct BudgetSetupStatus: Codable, Equatable {
    var isStarted: Bool
    var isCompleted: Bool
    var totalBudget: Double?
    var categoriesCreated: Int

    init(
        isStarted: Bool = false,
        isCompleted: Bool = false,
        totalBudget: Double? = nil,
        categoriesCreated: Int = 0
    ) {
        self.isStarted = isStarted
        self.isCompleted = isCompleted
        self.totalBudget = totalBudget
        self.categoriesCreated = categoriesCreated
    }
}

// MARK: - Onboarding Mode

/// Determines the onboarding flow mode
enum OnboardingMode: String, Codable {
    case guided = "guided" // Full step-by-step onboarding
    case express = "express" // Quick setup with defaults

    var displayName: String {
        switch self {
        case .guided: return "Guided Setup"
        case .express: return "Express Setup"
        }
    }

    var description: String {
        switch self {
        case .guided:
            return "Walk through each step with detailed guidance"
        case .express:
            return "Quick setup with smart defaults"
        }
    }
}

// MARK: - Test Helpers

#if DEBUG
extension OnboardingProgress {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        currentStep: OnboardingStep = .welcome,
        completedSteps: Set<OnboardingStep> = [],
        isCompleted: Bool = false
    ) -> OnboardingProgress {
        OnboardingProgress(
            id: id,
            coupleId: coupleId,
            currentStep: currentStep,
            completedSteps: completedSteps,
            isCompleted: isCompleted
        )
    }
}

extension WeddingDetails {
    static func makeTest(
        weddingDate: Date? = Date().addingTimeInterval(365 * 24 * 60 * 60),
        venue: String = "Test Venue",
        partner1Name: String = "Partner One",
        partner2Name: String = "Partner Two",
        weddingStyle: WeddingStyle? = .modern
    ) -> WeddingDetails {
        WeddingDetails(
            weddingDate: weddingDate,
            venue: venue,
            partner1Name: partner1Name,
            partner2Name: partner2Name,
            weddingStyle: weddingStyle
        )
    }
}
#endif
