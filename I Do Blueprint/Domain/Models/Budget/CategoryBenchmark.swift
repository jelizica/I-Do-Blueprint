//
//  CategoryBenchmark.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for category spending benchmarks and industry standards
//

import Foundation

struct CategoryBenchmark: Identifiable, Codable {
    let id: UUID
    let categoryName: String
    var typicalPercentage: Double
    var minPercentage: Double
    var maxPercentage: Double
    var description: String?
    var region: String?
    var lastUpdated: Date

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case categoryName = "category_name"
        case typicalPercentage = "typical_percentage"
        case minPercentage = "min_percentage"
        case maxPercentage = "max_percentage"
        case description = "description"
        case region = "region"
        case lastUpdated = "last_updated"
    }
}
