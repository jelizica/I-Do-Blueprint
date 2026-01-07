//
//  DashboardPage.swift
//  I Do Blueprint
//
//  Created by Claude on 1/6/26.
//  Centralized navigation state for Dashboards module
//

import SwiftUI

// MARK: - Dashboard Page Enum

enum DashboardPage: String, CaseIterable, Identifiable {
    // General Dashboard (Comprehensive wedding overview)
    case general = "General Dashboard"
    // Financial Dashboard (Budget-focused analytics)
    case financial = "Financial Dashboard"

    // Future dashboards can be added here:
    // case guest = "Guest Dashboard"
    // case vendor = "Vendor Dashboard"
    // case timeline = "Timeline Dashboard"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "square.grid.2x2"
        case .financial: return "chart.bar.xaxis"
        }
    }

    var description: String {
        switch self {
        case .general:
            return "Comprehensive wedding planning overview with all key metrics"
        case .financial:
            return "Budget analytics, spending trends, and financial insights"
        }
    }

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .general:
            DashboardsNavigationWrapper(selectedPage: .general)
        case .financial:
            DashboardsNavigationWrapper(selectedPage: .financial)
        }
    }
}
