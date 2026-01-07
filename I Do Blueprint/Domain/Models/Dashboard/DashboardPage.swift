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
    // Financial Dashboard (Budget-focused analytics)
    case financial = "Financial Dashboard"

    // Future dashboards can be added here:
    // case guest = "Guest Dashboard"
    // case vendor = "Vendor Dashboard"
    // case timeline = "Timeline Dashboard"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .financial: return "chart.bar.xaxis"
        }
    }

    var description: String {
        switch self {
        case .financial:
            return "Budget analytics, spending trends, and financial insights"
        }
    }

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .financial:
            DashboardsNavigationWrapper(selectedPage: .financial)
        }
    }
}
