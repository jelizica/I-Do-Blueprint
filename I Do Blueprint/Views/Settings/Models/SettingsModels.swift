//
//  SettingsModels.swift
//  I Do Blueprint
//
//  Shared models for settings navigation
//

import SwiftUI

// MARK: - Subsection Protocol

protocol SettingsSubsection: RawRepresentable, CaseIterable, Identifiable where RawValue == String {
    var icon: String { get }
}

// MARK: - Settings Section

enum SettingsSection: String, CaseIterable, Identifiable {
    case global = "Wedding Setup"
    case account = "Account"
    case budgetVendors = "Budget & Vendors"
    case guestsTasks = "Guests & Tasks"
    case appearance = "Appearance & Notifications"
    case dataContent = "Data & Content"
    case developer = "Developer & Advanced"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .global: "globe"
        case .account: "person.circle"
        case .budgetVendors: "dollarsign.circle"
        case .guestsTasks: "person.3"
        case .appearance: "paintpalette"
        case .dataContent: "doc"
        case .developer: "hammer.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .developer: .orange
        default: .accentColor
        }
    }
    
    var hasSubsections: Bool {
        // All sections now have subsections
        return true
    }
}

// MARK: - Global Subsection

enum GlobalSubsection: String, CaseIterable, Identifiable, SettingsSubsection {
    case overview = "Overview"
    case weddingEvents = "Wedding Events"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: "info.circle"
        case .weddingEvents: "calendar.badge.plus"
        }
    }
}

// MARK: - Account Subsection

enum AccountSubsection: String, CaseIterable, Identifiable, SettingsSubsection {
    case profile = "Profile & Authentication"
    case collaboration = "Collaboration & Team"
    case dataPrivacy = "Data & Privacy"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .profile: "person.circle"
        case .collaboration: "person.2.badge.gearshape"
        case .dataPrivacy: "shield.fill"
        }
    }
}

// MARK: - Budget & Vendors Subsection

enum BudgetVendorsSubsection: String, CaseIterable, Identifiable, SettingsSubsection {
    case budgetConfiguration = "Budget Configuration"
    case budgetCategories = "Budget Categories"
    case vendorManagement = "Vendor Management"
    case vendorCategories = "Vendor Categories"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .budgetConfiguration: "dollarsign.circle"
        case .budgetCategories: "folder.fill"
        case .vendorManagement: "person.2"
        case .vendorCategories: "star"
        }
    }
}

// MARK: - Guests & Tasks Subsection

enum GuestsTasksSubsection: String, CaseIterable, Identifiable, SettingsSubsection {
    case guestPreferences = "Guest Preferences"
    case taskPreferences = "Task Preferences"
    case teamMembers = "Team Members"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .guestPreferences: "person.3"
        case .taskPreferences: "checklist"
        case .teamMembers: "person.2.badge.gearshape"
        }
    }
}

// MARK: - Appearance Subsection

enum AppearanceSubsection: String, CaseIterable, Identifiable, SettingsSubsection {
    case theme = "Theme"
    case notifications = "Notifications"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .theme: "paintpalette"
        case .notifications: "bell"
        }
    }
}

// MARK: - Data & Content Subsection

enum DataContentSubsection: String, CaseIterable, Identifiable, SettingsSubsection {
    case documents = "Documents"
    case importantLinks = "Important Links"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .documents: "doc"
        case .importantLinks: "link"
        }
    }
}

// MARK: - Developer Subsection

enum DeveloperSubsection: String, CaseIterable, Identifiable, SettingsSubsection {
    case apiKeys = "API Keys"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .apiKeys: "key.fill"
        }
    }
}

// MARK: - Subsection Wrapper

enum AnySubsection: Hashable {
    case global(GlobalSubsection)
    case account(AccountSubsection)
    case budgetVendors(BudgetVendorsSubsection)
    case guestsTasks(GuestsTasksSubsection)
    case appearance(AppearanceSubsection)
    case dataContent(DataContentSubsection)
    case developer(DeveloperSubsection)
    
    var rawValue: String {
        switch self {
        case .global(let sub): sub.rawValue
        case .account(let sub): sub.rawValue
        case .budgetVendors(let sub): sub.rawValue
        case .guestsTasks(let sub): sub.rawValue
        case .appearance(let sub): sub.rawValue
        case .dataContent(let sub): sub.rawValue
        case .developer(let sub): sub.rawValue
        }
    }
    
    var icon: String {
        switch self {
        case .global(let sub): sub.icon
        case .account(let sub): sub.icon
        case .budgetVendors(let sub): sub.icon
        case .guestsTasks(let sub): sub.icon
        case .appearance(let sub): sub.icon
        case .dataContent(let sub): sub.icon
        case .developer(let sub): sub.icon
        }
    }
}
