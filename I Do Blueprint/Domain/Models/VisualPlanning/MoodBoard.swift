//
//  MoodBoard.swift
//  My Wedding Planning App
//
//  Core mood board model for visual planning
//

import Foundation
import SwiftUI

struct MoodBoard: Identifiable, Codable, Hashable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var tenantId: String
    var boardName: String
    var boardDescription: String?
    var styleCategory: StyleCategory
    var colorPaletteId: UUID?
    var canvasSize: CGSize
    var backgroundColor: Color
    var backgroundImage: String?
    var elements: [VisualElement]
    var isTemplate: Bool
    var isPublic: Bool
    var tags: [String]
    var inspirationUrls: [String]
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tenantId = "couple_id"
        case boardName = "board_name"
        case boardDescription = "board_description"
        case styleCategory = "style_category"
        case colorPaletteId = "color_palette_id"
        case canvasWidth = "canvas_width"
        case canvasHeight = "canvas_height"
        case backgroundColor = "background_color"
        case backgroundImage = "background_image"
        case elements
        case isTemplate = "is_template"
        case isPublic = "is_public"
        case tags
        case inspirationUrls = "inspiration_urls"
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        tenantId = try container.decode(String.self, forKey: .tenantId)
        boardName = try container.decode(String.self, forKey: .boardName)
        boardDescription = try container.decodeIfPresent(String.self, forKey: .boardDescription)
        styleCategory = try container.decode(StyleCategory.self, forKey: .styleCategory)
        colorPaletteId = try container.decodeIfPresent(UUID.self, forKey: .colorPaletteId)

        // Decode canvas width and height separately and combine into CGSize
        let width = try container.decode(Int.self, forKey: .canvasWidth)
        let height = try container.decode(Int.self, forKey: .canvasHeight)
        canvasSize = CGSize(width: width, height: height)

        backgroundColor = try container.decode(Color.self, forKey: .backgroundColor)
        backgroundImage = try container.decodeIfPresent(String.self, forKey: .backgroundImage)
        elements = try container.decode([VisualElement].self, forKey: .elements)
        isTemplate = try container.decode(Bool.self, forKey: .isTemplate)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        tags = try container.decode([String].self, forKey: .tags)
        inspirationUrls = try container.decode([String].self, forKey: .inspirationUrls)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(tenantId, forKey: .tenantId)
        try container.encode(boardName, forKey: .boardName)
        try container.encodeIfPresent(boardDescription, forKey: .boardDescription)
        try container.encode(styleCategory, forKey: .styleCategory)
        try container.encodeIfPresent(colorPaletteId, forKey: .colorPaletteId)

        // Encode CGSize as separate width and height
        try container.encode(Int(canvasSize.width), forKey: .canvasWidth)
        try container.encode(Int(canvasSize.height), forKey: .canvasHeight)

        try container.encode(backgroundColor, forKey: .backgroundColor)
        try container.encodeIfPresent(backgroundImage, forKey: .backgroundImage)
        try container.encode(elements, forKey: .elements)
        try container.encode(isTemplate, forKey: .isTemplate)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(tags, forKey: .tags)
        try container.encode(inspirationUrls, forKey: .inspirationUrls)
        try container.encodeIfPresent(notes, forKey: .notes)
    }

    init(
        id: UUID = UUID(),
        tenantId: String,
        boardName: String,
        boardDescription: String? = nil,
        styleCategory: StyleCategory,
        colorPaletteId: UUID? = nil,
        canvasSize: CGSize = CGSize(width: 800, height: 600),
        backgroundColor: Color = .white,
        backgroundImage: String? = nil,
        elements: [VisualElement] = [],
        isTemplate: Bool = false,
        isPublic: Bool = false,
        tags: [String] = [],
        inspirationUrls: [String] = [],
        notes: String? = nil) {
        self.id = id
        createdAt = Date()
        updatedAt = Date()
        self.tenantId = tenantId
        self.boardName = boardName
        self.boardDescription = boardDescription
        self.styleCategory = styleCategory
        self.colorPaletteId = colorPaletteId
        self.canvasSize = canvasSize
        self.backgroundColor = backgroundColor
        self.backgroundImage = backgroundImage
        self.elements = elements
        self.isTemplate = isTemplate
        self.isPublic = isPublic
        self.tags = tags
        self.inspirationUrls = inspirationUrls
        self.notes = notes
    }
}

// MARK: - MoodBoard Template Type

struct MoodBoardTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let category: StyleCategory
    let previewImage: String?
    let templateMoodBoard: MoodBoard

    init(
        name: String,
        description: String,
        category: StyleCategory,
        templateMoodBoard: MoodBoard,
        previewImage: String? = nil) {
        id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.previewImage = previewImage
        var template = templateMoodBoard
        template.isTemplate = true
        self.templateMoodBoard = template
    }
}

// MARK: - Codable Extensions for Color and CGSize

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    public init(from decoder: Decoder) throws {
        // Try to decode as hex string first (database format)
        if let container = try? decoder.singleValueContainer(),
           let hexString = try? container.decode(String.self) {
            self = Color(hex: hexString) ?? .gray
            return
        }

        // Fall back to RGBA format
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        let a = try container.decode(Double.self, forKey: .alpha)
        self.init(NSColor(red: r, green: g, blue: b, alpha: a))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.deviceRGB) else {
            try container.encode(0.0, forKey: .red)
            try container.encode(0.0, forKey: .green)
            try container.encode(0.0, forKey: .blue)
            try container.encode(1.0, forKey: .alpha)
            return
        }
        try container.encode(rgb.redComponent, forKey: .red)
        try container.encode(rgb.greenComponent, forKey: .green)
        try container.encode(rgb.blueComponent, forKey: .blue)
        try container.encode(rgb.alphaComponent, forKey: .alpha)
    }
}

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
