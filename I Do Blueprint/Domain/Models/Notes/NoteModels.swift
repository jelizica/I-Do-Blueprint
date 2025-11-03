//
//  NoteModels.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation

// MARK: - Note Model

struct Note: Codable, Equatable, Identifiable {
    let id: UUID
    let coupleId: UUID
    var title: String?
    var content: String
    var relatedType: NoteRelatedType?
    var relatedId: String?
    let createdAt: Date
    var updatedAt: Date

    // Related entity details (populated via joins)
    var relatedEntity: RelatedEntity?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case title = "title"
        case content = "content"
        case relatedType = "related_type"
        case relatedId = "related_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case relatedEntity = "related_entity"
    }

    var displayTitle: String {
        title ?? "Untitled Note"
    }

    var contentPreview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<index]) + "..."
    }

    var characterCount: Int {
        content.count
    }
}

// MARK: - Note Related Types

enum NoteRelatedType: String, Codable, CaseIterable {
    case vendor = "vendor"
    case guest = "guest"
    case task = "task"
    case milestone = "milestone"
    case budget = "budget"
    case visualElement = "visual_element"
    case payment = "payment"
    case document = "document"

    var displayName: String {
        switch self {
        case .vendor: "Vendor"
        case .guest: "Guest"
        case .task: "Task"
        case .milestone: "Milestone"
        case .budget: "Budget"
        case .visualElement: "Visual Element"
        case .payment: "Payment"
        case .document: "Document"
        }
    }

    var iconName: String {
        switch self {
        case .vendor: "person.2.fill"
        case .guest: "person.fill"
        case .task: "checklist"
        case .milestone: "star.fill"
        case .budget: "dollarsign.circle.fill"
        case .visualElement: "paintpalette.fill"
        case .payment: "creditcard.fill"
        case .document: "doc.fill"
        }
    }
}

// MARK: - Related Entity

struct RelatedEntity: Codable, Equatable {
    let id: String
    let name: String
    let type: NoteRelatedType
}

// MARK: - Note Insert/Update Data

struct NoteInsertData: Codable {
    var coupleId: UUID
    var title: String?
    var content: String
    var relatedType: NoteRelatedType?
    var relatedId: String?

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case title = "title"
        case content = "content"
        case relatedType = "related_type"
        case relatedId = "related_id"
    }

    func validate() -> [String] {
        var errors: [String] = []

        // Content is required
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Content is required")
        }

        // Content max length
        if content.count > 10000 {
            errors.append("Content must be 10,000 characters or less")
        }

        // Title max length
        if let title, title.count > 255 {
            errors.append("Title must be 255 characters or less")
        }

        // If related type is specified, related ID must be provided
        if relatedType != nil, relatedId == nil || relatedId?.isEmpty == true {
            errors.append("Related ID is required when specifying a related type")
        }

        // If related ID is specified, related type must be provided
        if relatedId != nil, !relatedId!.isEmpty, relatedType == nil {
            errors.append("Related type is required when specifying a related ID")
        }

        return errors
    }
}

// MARK: - Note Filter Options

enum NoteFilterType {
    case all
    case relatedType(NoteRelatedType)
    case recent
    case unlinked

    var displayName: String {
        switch self {
        case .all: "All Notes"
        case .relatedType(let type): type.displayName
        case .recent: "Recent"
        case .unlinked: "Unlinked"
        }
    }
}

// MARK: - Note Sort Options

enum NoteSortOption {
    case createdDesc
    case createdAsc
    case updatedDesc
    case updatedAsc
    case titleAsc
    case titleDesc

    var displayName: String {
        switch self {
        case .createdDesc: "Newest First"
        case .createdAsc: "Oldest First"
        case .updatedDesc: "Recently Updated"
        case .updatedAsc: "Least Recently Updated"
        case .titleAsc: "Title (A-Z)"
        case .titleDesc: "Title (Z-A)"
        }
    }
}
