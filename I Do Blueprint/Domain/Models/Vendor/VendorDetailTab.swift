//
//  VendorDetailTab.swift
//  I Do Blueprint
//
//  Tab definitions for vendor detail view
//

import Foundation

/// Tabs available in the vendor detail view
enum VendorDetailTab: Int, CaseIterable, Identifiable {
    case overview = 0
    case financial = 1
    case documents = 2
    case notes = 3

    var id: Int { rawValue }

    /// Display title for the tab
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .financial: return "Financial"
        case .documents: return "Documents"
        case .notes: return "Notes"
        }
    }

    /// SF Symbol icon name for the tab
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .financial: return "dollarsign.circle"
        case .documents: return "doc.text"
        case .notes: return "note.text"
        }
    }

    /// Filled icon variant for selected state
    var iconFilled: String {
        switch self {
        case .overview: return "info.circle.fill"
        case .financial: return "dollarsign.circle.fill"
        case .documents: return "doc.text.fill"
        case .notes: return "note.text.fill"
        }
    }

    /// Accessibility label for the tab
    var accessibilityLabel: String {
        switch self {
        case .overview: return "Overview tab"
        case .financial: return "Financial information tab"
        case .documents: return "Documents tab"
        case .notes: return "Notes tab"
        }
    }

    /// Accessibility hint for the tab
    var accessibilityHint: String {
        switch self {
        case .overview: return "View vendor overview and contact information"
        case .financial: return "View expenses and payment schedules"
        case .documents: return "View linked documents and contracts"
        case .notes: return "View vendor notes"
        }
    }
}
