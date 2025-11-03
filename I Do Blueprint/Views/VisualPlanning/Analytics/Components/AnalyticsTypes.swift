//
//  AnalyticsTypes.swift
//  I Do Blueprint
//
//  Types and enums for analytics dashboard
//

import SwiftUI

// MARK: - Time Frame

enum TimeFrame: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"
    case quarter = "quarter"

    var displayName: String {
        switch self {
        case .day: "Today"
        case .week: "This Week"
        case .month: "This Month"
        case .quarter: "This Quarter"
        }
    }
}

// MARK: - Metric Type

enum MetricType {
    case overview
    case moodBoards
    case colorPalettes
    case seatingCharts
}

// MARK: - Metric Status

enum MetricStatus {
    case good
    case caution
    case warning

    var color: Color {
        switch self {
        case .good: .green
        case .caution: .orange
        case .warning: .red
        }
    }
}
