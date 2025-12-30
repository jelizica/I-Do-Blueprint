//
//  BudgetCategory.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Category model for budget organization and tracking
//

import Foundation

struct BudgetCategory: Identifiable, Codable, Hashable {
    let id: UUID
    let coupleId: UUID
    var categoryName: String
    var parentCategoryId: UUID?
    var allocatedAmount: Double
    var spentAmount: Double
    var typicalPercentage: Double?
    var priorityLevel: Int
    var isEssential: Bool
    var notes: String?
    var forecastedAmount: Double
    var confidenceLevel: Double
    var lockedAllocation: Bool
    var description: String?
    var createdAt: Date
    var updatedAt: Date?

    // Computed properties for backward compatibility
    var priority: BudgetPriority {
        switch priorityLevel {
        case 1: .high
        case 2: .medium
        default: .low
        }
    }

    var color: String {
        // Generate a color based on category name hash for consistency
        let colors = [
            "#3B82F6",
            "#10B981",
            "#8B5CF6",
            "#F59E0B",
            "#EF4444",
            "#06B6D4",
            "#84CC16",
            "#F97316",
            "#EC4899",
            "#6366F1"
        ]
        let index = abs(categoryName.hashValue) % colors.count
        return colors[index]
    }

    var remainingAmount: Double {
        allocatedAmount - spentAmount
    }

    var percentageSpent: Double {
        guard allocatedAmount > 0 else { return 0 }
        return (spentAmount / allocatedAmount) * 100
    }

    var isOverBudget: Bool {
        spentAmount > allocatedAmount
    }

    // Explicit memberwise initializer
    init(
        id: UUID,
        coupleId: UUID,
        categoryName: String,
        parentCategoryId: UUID? = nil,
        allocatedAmount: Double,
        spentAmount: Double,
        typicalPercentage: Double? = nil,
        priorityLevel: Int,
        isEssential: Bool,
        notes: String? = nil,
        forecastedAmount: Double,
        confidenceLevel: Double,
        lockedAllocation: Bool,
        description: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.coupleId = coupleId
        self.categoryName = categoryName
        self.parentCategoryId = parentCategoryId
        self.allocatedAmount = allocatedAmount
        self.spentAmount = spentAmount
        self.typicalPercentage = typicalPercentage
        self.priorityLevel = priorityLevel
        self.isEssential = isEssential
        self.notes = notes
        self.forecastedAmount = forecastedAmount
        self.confidenceLevel = confidenceLevel
        self.lockedAllocation = lockedAllocation
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoding to handle different date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        parentCategoryId = try container.decodeIfPresent(UUID.self, forKey: .parentCategoryId)
        allocatedAmount = try container.decode(Double.self, forKey: .allocatedAmount)
        spentAmount = try container.decode(Double.self, forKey: .spentAmount)
        typicalPercentage = try container.decodeIfPresent(Double.self, forKey: .typicalPercentage)
        priorityLevel = try container.decode(Int.self, forKey: .priorityLevel)
        isEssential = try container.decode(Bool.self, forKey: .isEssential)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        forecastedAmount = try container.decode(Double.self, forKey: .forecastedAmount)
        confidenceLevel = try container.decode(Double.self, forKey: .confidenceLevel)
        lockedAllocation = try container.decode(Bool.self, forKey: .lockedAllocation)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        // Custom date decoding using shared DateDecodingHelpers (refactored from duplicated code)
        createdAt = try DateDecodingHelpers.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case categoryName = "category_name"
        case parentCategoryId = "parent_category_id"
        case allocatedAmount = "allocated_amount"
        case spentAmount = "spent_amount"
        case typicalPercentage = "typical_percentage"
        case priorityLevel = "priority_level"
        case isEssential = "is_essential"
        case notes = "notes"
        case forecastedAmount = "forecasted_amount"
        case confidenceLevel = "confidence_level"
        case lockedAllocation = "locked_allocation"
        case description = "description"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
