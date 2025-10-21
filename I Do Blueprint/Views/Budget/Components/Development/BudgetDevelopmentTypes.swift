//
//  BudgetDevelopmentTypes.swift
//  I Do Blueprint
//
//  Data models for budget development view
//

import Foundation

// MARK: - Custom Tax Rate Data

struct CustomTaxRateData {
    var region: String = ""
    var taxRate: String = ""
}

// MARK: - Scenario Dialog Data

struct ScenarioDialogData {
    var id: String = ""
    var name: String = ""
}

// MARK: - Budget Export Data

struct BudgetExportData: Codable {
    let name: String
    let items: [BudgetItem]
    let totals: BudgetTotals
    let exportDate: Date
}

// MARK: - Budget Totals

struct BudgetTotals: Codable {
    let totalWithoutTax: Double
    let totalTax: Double
    let totalWithTax: Double
}
