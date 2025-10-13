//
//  ColorPaletteModel.swift
//  My Wedding Planning App
//
//  Model for color palettes in visual planning
//

import SwiftUI

struct ColorPalette: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colors: [String]  // Hex color values
    var description: String?
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colors: [String],
        description: String? = nil,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colors = colors
        self.description = description
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
