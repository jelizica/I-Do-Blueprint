//
//  SettingsModels.swift
//  I Do Blueprint
//
//  Shared models for settings navigation
//

import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case global = "Global"
    case theme = "Theme"
    case budget = "Budget"
    case tasks = "Tasks"
    case vendors = "Vendors"
    case vendorCategories = "Categories"
    case guests = "Guests"
    case documents = "Documents"
    case collaboration = "Collaboration"
    case notifications = "Notifications"
    case links = "Links"
    case apiKeys = "API Keys"
    case account = "Account"
    case featureFlags = "Feature Flags"
    case danger = "Danger Zone"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .global: "globe"
        case .theme: "paintpalette"
        case .budget: "dollarsign.circle"
        case .tasks: "checklist"
        case .vendors: "person.2"
        case .vendorCategories: "star"
        case .guests: "person.3"
        case .documents: "doc"
        case .collaboration: "person.2.badge.gearshape"
        case .notifications: "bell"
        case .links: "link"
        case .apiKeys: "key.fill"
        case .account: "person.circle"
        case .featureFlags: "flag.fill"
        case .danger: "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .danger: .red
        case .featureFlags: .orange
        default: .accentColor
        }
    }
    
    var hasSubsections: Bool {
        switch self {
        case .global: true
        default: false
        }
    }
}

enum GlobalSubsection: String, CaseIterable, Identifiable {
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
