//
//  TaxInfo.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for tax information by region
//

import Foundation

struct TaxInfo: Identifiable, Codable {
    let id: Int64
    let createdAt: Date?
    var region: String
    var taxRate: Double

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case createdAt = "created_at"
        case region = "region"
        case taxRate = "tax_rate"
    }

    init(id: Int64 = 0, createdAt: Date? = nil, region: String, taxRate: Double) {
        self.id = id
        self.createdAt = createdAt
        self.region = region
        self.taxRate = taxRate
    }
}
