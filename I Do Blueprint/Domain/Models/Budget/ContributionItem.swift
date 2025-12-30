//
//  ContributionItem.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for tracking contributions to wedding budget
//

import Foundation

struct ContributionItem: Identifiable, Codable {
    let id: UUID
    let scenarioId: UUID
    var contributorName: String
    var amount: Double
    var contributionDate: Date
    var contributionType: ContributionType
    var notes: String?
    let coupleId: UUID
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case scenarioId = "scenario_id"
        case contributorName = "contributor_name"
        case amount = "amount"
        case contributionDate = "contribution_date"
        case contributionType = "contribution_type"
        case notes = "notes"
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        scenarioId = try container.decode(UUID.self, forKey: .scenarioId)
        contributorName = try container.decode(String.self, forKey: .contributorName)
        contributionType = try container.decode(ContributionType.self, forKey: .contributionType)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)

        // Handle amount - might be string or double from Supabase
        if let amountString = try? container.decode(String.self, forKey: .amount) {
            amount = Double(amountString) ?? 0
        } else {
            amount = try container.decode(Double.self, forKey: .amount)
        }

        // Handle dates using shared DateDecodingHelpers (refactored from duplicated code)
        contributionDate = try DateDecodingHelpers.decodeDate(from: container, forKey: .contributionDate)
        createdAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .createdAt)
        updatedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    init(
        id: UUID = UUID(),
        scenarioId: UUID,
        contributorName: String,
        amount: Double,
        contributionDate: Date,
        contributionType: ContributionType,
        notes: String? = nil,
        coupleId: UUID,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.scenarioId = scenarioId
        self.contributorName = contributorName
        self.amount = amount
        self.contributionDate = contributionDate
        self.contributionType = contributionType
        self.notes = notes
        self.coupleId = coupleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum ContributionType: String, Codable, CaseIterable {
    case gift = "gift"
    case external = "external_contribution"

    var displayName: String {
        switch self {
        case .gift: return "Gift"
        case .external: return "External"
        }
    }
}
