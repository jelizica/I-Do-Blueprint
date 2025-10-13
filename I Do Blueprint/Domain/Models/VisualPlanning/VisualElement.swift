//
//  VisualElement.swift
//  My Wedding Planning App
//
//  Visual element model for mood boards
//

import Foundation
import SwiftUI

struct VisualElement: Identifiable, Codable, Hashable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var moodBoardId: UUID
    var elementType: ElementType
    var elementData: ElementData
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    var opacity: Double
    var zIndex: Int
    var isLocked: Bool
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case moodBoardId = "mood_board_id"
        case elementType = "element_type"
        case elementData = "element_data"
        case positionX = "position_x"
        case positionY = "position_y"
        case width
        case height
        case rotation
        case opacity
        case zIndex = "z_index"
        case isLocked = "is_locked"
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        moodBoardId = try container.decode(UUID.self, forKey: .moodBoardId)
        elementType = try container.decode(ElementType.self, forKey: .elementType)
        elementData = try container.decode(ElementData.self, forKey: .elementData)

        let x = try container.decode(Double.self, forKey: .positionX)
        let y = try container.decode(Double.self, forKey: .positionY)
        position = CGPoint(x: x, y: y)

        let w = try container.decode(Double.self, forKey: .width)
        let h = try container.decode(Double.self, forKey: .height)
        size = CGSize(width: w, height: h)

        rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        zIndex = try container.decode(Int.self, forKey: .zIndex)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(moodBoardId, forKey: .moodBoardId)
        try container.encode(elementType, forKey: .elementType)
        try container.encode(elementData, forKey: .elementData)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(zIndex, forKey: .zIndex)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encodeIfPresent(notes, forKey: .notes)
    }

    init(
        id: UUID = UUID(),
        moodBoardId: UUID,
        elementType: ElementType,
        elementData: ElementData,
        position: CGPoint = CGPoint(x: 100, y: 100),
        size: CGSize = CGSize(width: 200, height: 200),
        rotation: Double = 0,
        opacity: Double = 1.0,
        zIndex: Int = 0,
        isLocked: Bool = false,
        notes: String? = nil) {
        self.id = id
        createdAt = Date()
        updatedAt = Date()
        self.moodBoardId = moodBoardId
        self.elementType = elementType
        self.elementData = elementData
        self.position = position
        self.size = size
        self.rotation = rotation
        self.opacity = opacity
        self.zIndex = zIndex
        self.isLocked = isLocked
        self.notes = notes
    }

    struct ElementData: Codable, Hashable {
        var imageUrl: String?
        var thumbnailUrl: String?
        var color: Color?
        var text: String?
        var fontSize: Double?
        var fontName: String?
        var textAlignment: TextAlignment?
        var sourceUrl: String?
        var originalFilename: String?
        var fileSize: Int64?
        var dimensions: CGSize?
        var alt: String?

        enum TextAlignment: String, Codable, Hashable {
            case leading, center, trailing
        }

        enum CodingKeys: String, CodingKey {
            case imageUrl = "url"
            case assetUrl = "asset_url"
            case thumbnailUrl = "thumbnail_url"
            case color
            case text
            case fontSize = "font_size"
            case fontName = "font_name"
            case textAlignment = "text_alignment"
            case sourceUrl = "source_url"
            case originalFilename = "original_filename"
            case fileSize = "file_size"
            case dimensions
            case alt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Handle multiple possible URL keys
            if let url = try container.decodeIfPresent(String.self, forKey: .imageUrl) {
                imageUrl = url
            } else if let assetUrl = try container.decodeIfPresent(String.self, forKey: .assetUrl) {
                imageUrl = assetUrl
            }

            thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
            color = try container.decodeIfPresent(Color.self, forKey: .color)
            text = try container.decodeIfPresent(String.self, forKey: .text)
            fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize)
            fontName = try container.decodeIfPresent(String.self, forKey: .fontName)
            textAlignment = try container.decodeIfPresent(TextAlignment.self, forKey: .textAlignment)
            sourceUrl = try container.decodeIfPresent(String.self, forKey: .sourceUrl)
            originalFilename = try container.decodeIfPresent(String.self, forKey: .originalFilename)
            fileSize = try container.decodeIfPresent(Int64.self, forKey: .fileSize)
            alt = try container.decodeIfPresent(String.self, forKey: .alt)

            // Decode dimensions from {width: x, height: y} object
            if let dimensionsContainer = try? container.nestedContainer(keyedBy: DimensionKeys.self, forKey: .dimensions) {
                let width = try dimensionsContainer.decode(Double.self, forKey: .width)
                let height = try dimensionsContainer.decode(Double.self, forKey: .height)
                dimensions = CGSize(width: width, height: height)
            } else {
                dimensions = nil
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
            try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
            try container.encodeIfPresent(color, forKey: .color)
            try container.encodeIfPresent(text, forKey: .text)
            try container.encodeIfPresent(fontSize, forKey: .fontSize)
            try container.encodeIfPresent(fontName, forKey: .fontName)
            try container.encodeIfPresent(textAlignment, forKey: .textAlignment)
            try container.encodeIfPresent(sourceUrl, forKey: .sourceUrl)
            try container.encodeIfPresent(originalFilename, forKey: .originalFilename)
            try container.encodeIfPresent(fileSize, forKey: .fileSize)
            try container.encodeIfPresent(alt, forKey: .alt)

            // Encode dimensions as {width: x, height: y}
            if let size = dimensions {
                var dimensionsContainer = container.nestedContainer(keyedBy: DimensionKeys.self, forKey: .dimensions)
                try dimensionsContainer.encode(size.width, forKey: .width)
                try dimensionsContainer.encode(size.height, forKey: .height)
            }
        }

        private enum DimensionKeys: String, CodingKey {
            case width, height
        }

        init(
            imageUrl: String? = nil,
            thumbnailUrl: String? = nil,
            color: Color? = nil,
            text: String? = nil,
            fontSize: Double? = nil,
            fontName: String? = nil,
            textAlignment: TextAlignment? = nil,
            sourceUrl: String? = nil,
            originalFilename: String? = nil,
            fileSize: Int64? = nil,
            dimensions: CGSize? = nil,
            alt: String? = nil
        ) {
            self.imageUrl = imageUrl
            self.thumbnailUrl = thumbnailUrl
            self.color = color
            self.text = text
            self.fontSize = fontSize
            self.fontName = fontName
            self.textAlignment = textAlignment
            self.sourceUrl = sourceUrl
            self.originalFilename = originalFilename
            self.fileSize = fileSize
            self.dimensions = dimensions
            self.alt = alt
        }
    }

    // Computed properties for convenience
    var frame: CGRect {
        CGRect(origin: position, size: size)
    }

    var center: CGPoint {
        CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)
    }

    func contains(point: CGPoint) -> Bool {
        frame.contains(point)
    }

    mutating func updatePosition(_ newPosition: CGPoint) {
        position = newPosition
        updatedAt = Date()
    }

    mutating func updateSize(_ newSize: CGSize) {
        size = newSize
        updatedAt = Date()
    }

    mutating func updateRotation(_ newRotation: Double) {
        rotation = newRotation
        updatedAt = Date()
    }
}

// MARK: - Codable Extensions for CGPoint

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
