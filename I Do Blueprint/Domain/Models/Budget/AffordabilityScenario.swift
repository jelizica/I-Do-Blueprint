//
//  AffordabilityScenario.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for affordability calculator scenarios
//

import Foundation

struct AffordabilityScenario: Identifiable, Codable {
    let id: UUID
    var scenarioName: String
    var partner1Monthly: Double
    var partner2Monthly: Double
    var calculationStartDate: Date?
    var isPrimary: Bool
    let coupleId: UUID
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case scenarioName = "scenario_name"
        case partner1Monthly = "partner1_monthly"
        case partner2Monthly = "partner2_monthly"
        case calculationStartDate = "calculation_start_date"
        case isPrimary = "is_primary"
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        scenarioName = try container.decode(String.self, forKey: .scenarioName)
        isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)

        // Handle dates using shared DateDecodingHelpers (refactored from duplicated code)
        createdAt = try DateDecodingHelpers.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .updatedAt)
        calculationStartDate = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .calculationStartDate)

        // Handle numeric fields that might come as strings from Supabase
        if let p1String = try? container.decode(String.self, forKey: .partner1Monthly) {
            partner1Monthly = Double(p1String) ?? 0
        } else {
            partner1Monthly = try container.decode(Double.self, forKey: .partner1Monthly)
        }

        if let p2String = try? container.decode(String.self, forKey: .partner2Monthly) {
            partner2Monthly = Double(p2String) ?? 0
        } else {
            partner2Monthly = try container.decode(Double.self, forKey: .partner2Monthly)
        }
    }

    init(
        id: UUID = UUID(),
        scenarioName: String,
        partner1Monthly: Double,
        partner2Monthly: Double,
        calculationStartDate: Date? = nil,
        isPrimary: Bool = false,
        coupleId: UUID,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.scenarioName = scenarioName
        self.partner1Monthly = partner1Monthly
        self.partner2Monthly = partner2Monthly
        self.calculationStartDate = calculationStartDate
        self.isPrimary = isPrimary
        self.coupleId = coupleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
