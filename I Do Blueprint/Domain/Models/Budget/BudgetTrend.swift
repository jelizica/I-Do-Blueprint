//
//  BudgetTrend.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for budget trend visualization
//

import Foundation

struct BudgetTrend {
    let direction: TrendDirection
    let percentage: Double
    let label: String
}
