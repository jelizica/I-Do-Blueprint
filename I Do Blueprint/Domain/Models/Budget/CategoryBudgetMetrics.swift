//
//  CategoryBudgetMetrics.swift
//  I Do Blueprint
//
//  Created for budget chart calculations - data from get_category_budget_metrics RPC
//  Part of I Do Blueprint-63e0: Update Budget Category Chart calculations
//

import Foundation

/// Calculated budget metrics per category from the database RPC function.
/// These values are computed from actual data sources:
/// - allocated: Sum of budget_development_items.vendor_estimate_with_tax per category
/// - spent: Sum of paid payment_plans linked to vendors in each category
/// - forecasted: Sum of vendor_information.quoted_amount per category
struct CategoryBudgetMetrics: Identifiable, Codable, Sendable, Hashable {
    let categoryId: UUID
    let categoryName: String
    let parentCategoryId: UUID?
    let color: String
    let allocated: Double
    let spent: Double
    let forecasted: Double

    var id: UUID { categoryId }

    /// Remaining budget (allocated - spent)
    var remaining: Double {
        allocated - spent
    }

    /// Whether spending exceeds allocation
    var isOverBudget: Bool {
        spent > allocated
    }

    /// Percentage of allocated budget that has been spent (0-100+)
    var percentageSpent: Double {
        guard allocated > 0 else { return 0 }
        return (spent / allocated) * 100
    }

    /// Whether this is a parent category (has children)
    var isParentCategory: Bool {
        parentCategoryId == nil
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
        case parentCategoryId = "parent_category_id"
        case color
        case allocated
        case spent
        case forecasted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        categoryId = try container.decode(UUID.self, forKey: .categoryId)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        parentCategoryId = try container.decodeIfPresent(UUID.self, forKey: .parentCategoryId)
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#3B82F6"

        // Handle numeric values that may come as strings from PostgreSQL
        if let allocatedString = try? container.decode(String.self, forKey: .allocated) {
            allocated = Double(allocatedString) ?? 0
        } else {
            allocated = try container.decodeIfPresent(Double.self, forKey: .allocated) ?? 0
        }

        if let spentString = try? container.decode(String.self, forKey: .spent) {
            spent = Double(spentString) ?? 0
        } else {
            spent = try container.decodeIfPresent(Double.self, forKey: .spent) ?? 0
        }

        if let forecastedString = try? container.decode(String.self, forKey: .forecasted) {
            forecasted = Double(forecastedString) ?? 0
        } else {
            forecasted = try container.decodeIfPresent(Double.self, forKey: .forecasted) ?? 0
        }
    }

    // Memberwise initializer for testing
    init(
        categoryId: UUID,
        categoryName: String,
        parentCategoryId: UUID? = nil,
        color: String = "#3B82F6",
        allocated: Double,
        spent: Double,
        forecasted: Double
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.parentCategoryId = parentCategoryId
        self.color = color
        self.allocated = allocated
        self.spent = spent
        self.forecasted = forecasted
    }
}
