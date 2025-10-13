//
//  StylePreferences.swift
//  My Wedding Planning App
//
//  Comprehensive style preferences and wedding aesthetic data models
//

import Foundation
import SwiftUI

// MARK: - Main Style Preferences Model

struct StylePreferences: Codable, Identifiable {
    let id = UUID()
    var tenantId: String
    var primaryStyle: StyleCategory?
    var styleInfluences: [StyleCategory] = []
    var formalityLevel: FormalityLevel?
    var season: WeddingSeason?
    var primaryColors: [Color] = []
    var colorHarmony: ColorHarmonyType?
    var preferredTextures: [TextureType] = []
    var inspirationKeywords: [String] = []
    var visualThemes: [VisualTheme] = []
    var guidelines: StyleGuidelines?
    var createdAt = Date()
    var updatedAt = Date()

    init(tenantId: String = "default") {
        self.tenantId = tenantId
        guidelines = StyleGuidelines()
    }
}

enum TextureCategory: String, CaseIterable, Codable {
    case fabric
    case natural
    case organic
    case industrial

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Visual Themes

struct VisualTheme: Codable, Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var primaryColor: Color
    var secondaryColor: Color
    var accentColor: Color
    var associatedTextures: [TextureType]
    var moodKeywords: [String]
    var isActive: Bool = true

    static let predefinedThemes: [VisualTheme] = [
        VisualTheme(
            name: "Ethereal Romance",
            description: "Soft, dreamy, and otherworldly",
            primaryColor: .white,
            secondaryColor: .pink,
            accentColor: .gold,
            associatedTextures: [.chiffon, .tulle, .organza],
            moodKeywords: ["dreamy", "soft", "flowing", "delicate"]),
        VisualTheme(
            name: "Urban Sophistication",
            description: "Modern, sleek, and cosmopolitan",
            primaryColor: .black,
            secondaryColor: .white,
            accentColor: .silver,
            associatedTextures: [.silk, .satin, .metal, .glass],
            moodKeywords: ["sleek", "modern", "sophisticated", "urban"]),
        VisualTheme(
            name: "Natural Harmony",
            description: "Organic, grounded, and earth-connected",
            primaryColor: .green,
            secondaryColor: .brown,
            accentColor: .gold,
            associatedTextures: [.linen, .wood, .stone, .cotton],
            moodKeywords: ["organic", "natural", "grounded", "peaceful"])
    ]
}

// MARK: - Style Guidelines

struct StyleGuidelines: Codable {
    var doElements: [String] = []
    var avoidElements: [String] = []
    var colorGuidelines: String = ""
    var textureGuidelines: String = ""
    var inspirationSources: [String] = []
    var budgetConsiderations: String = ""
    var seasonalAdaptations: String = ""

    static func generateGuidelines(for preferences: StylePreferences) -> StyleGuidelines {
        var guidelines = StyleGuidelines()

        // Generate based on primary style
        if let primaryStyle = preferences.primaryStyle {
            switch primaryStyle {
            case .romantic:
                guidelines.doElements = ["Soft fabrics", "Flowing lines", "Delicate details", "Candlelight"]
                guidelines.avoidElements = ["Sharp angles", "Industrial materials", "Bright neon colors"]
                guidelines.colorGuidelines = "Use soft pastels, creams, and muted tones"

            case .modern:
                guidelines.doElements = ["Clean lines", "Minimal decor", "Quality materials", "Geometric shapes"]
                guidelines.avoidElements = ["Excessive ornamentation", "Cluttered arrangements", "Too many patterns"]
                guidelines.colorGuidelines = "Stick to a limited palette with bold accents"

            case .rustic:
                guidelines.doElements = [
                    "Natural materials",
                    "Vintage elements",
                    "Handmade touches",
                    "Outdoor settings"
                ]
                guidelines.avoidElements = ["Overly formal elements", "Synthetic materials", "Perfect symmetry"]
                guidelines.colorGuidelines = "Earth tones, warm colors, and natural variations"

            default:
                guidelines.doElements = ["Elements that reflect your chosen style"]
                guidelines.avoidElements = ["Elements that conflict with your vision"]
                guidelines.colorGuidelines = "Colors that complement your overall aesthetic"
            }
        }

        return guidelines
    }
}

// MARK: - Style Activity

struct StyleActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let date: Date

    enum ActivityType: String, CaseIterable {
        case styleSelected = "style_selected"
        case colorPaletteCreated = "color_palette_created"
        case moodBoardCreated = "mood_board_created"
        case themeAdded = "theme_added"
        case guidelinesUpdated = "guidelines_updated"

        var icon: String {
            switch self {
            case .styleSelected: "star.square"
            case .colorPaletteCreated: "paintpalette"
            case .moodBoardCreated: "photo.on.rectangle.angled"
            case .themeAdded: "sparkles"
            case .guidelinesUpdated: "doc.text"
            }
        }

        var color: Color {
            switch self {
            case .styleSelected: .orange
            case .colorPaletteCreated: .purple
            case .moodBoardCreated: .blue
            case .themeAdded: .pink
            case .guidelinesUpdated: .green
            }
        }
    }
}

// MARK: - Preferences Sections

enum PreferencesSection: String, CaseIterable {
    case overview
    case colors
    case style
    case themes
    case inspiration
    case guidelines

    var title: String {
        switch self {
        case .overview: "Overview"
        case .colors: "Colors"
        case .style: "Style"
        case .themes: "Themes"
        case .inspiration: "Inspiration"
        case .guidelines: "Guidelines"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: "Your style summary"
        case .colors: "Color palette & harmony"
        case .style: "Primary style & influences"
        case .themes: "Visual themes"
        case .inspiration: "Ideas & references"
        case .guidelines: "Do's and don'ts"
        }
    }

    var icon: String {
        switch self {
        case .overview: "chart.pie"
        case .colors: "paintpalette"
        case .style: "star.square"
        case .themes: "sparkles"
        case .inspiration: "lightbulb"
        case .guidelines: "doc.text"
        }
    }

    func completionPercentage(_ preferences: StylePreferences) -> Double {
        switch self {
        case .overview:
            var completed = 0.0
            if preferences.primaryStyle != nil { completed += 0.5 }
            if !preferences.primaryColors.isEmpty { completed += 0.5 }
            return completed

        case .colors:
            var completed = 0.0
            if !preferences.primaryColors.isEmpty { completed += 0.4 }
            if preferences.colorHarmony != nil { completed += 0.3 }
            if preferences.season != nil { completed += 0.3 }
            return completed

        case .style:
            var completed = 0.0
            if preferences.primaryStyle != nil { completed += 0.5 }
            if !preferences.styleInfluences.isEmpty { completed += 0.25 }
            if preferences.formalityLevel != nil { completed += 0.25 }
            return completed

        case .themes:
            return preferences.visualThemes.isEmpty ? 0.0 : 1.0

        case .inspiration:
            return preferences.inspirationKeywords.isEmpty ? 0.0 : 1.0

        case .guidelines:
            return (preferences.guidelines?.doElements.isEmpty ?? true) ? 0.0 : 1.0
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let dustyRose = Color(red: 0.8, green: 0.6, blue: 0.6)
    static let sage = Color(red: 0.6, green: 0.7, blue: 0.6)
    static let cream = Color(red: 0.9, green: 0.9, blue: 0.8)
    static let sand = Color(red: 0.8, green: 0.7, blue: 0.6)
    static let coral = Color(red: 1.0, green: 0.5, blue: 0.3)
    static let lavender = Color(red: 0.7, green: 0.6, blue: 0.8)
    static let evergreen = Color(red: 0.2, green: 0.4, blue: 0.3)
    static let copper = Color(red: 0.7, green: 0.4, blue: 0.2)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.75)

    var hexString: String {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.deviceRGB) else { return "#000000" }
        let red = Int(rgb.redComponent * 255)
        let green = Int(rgb.greenComponent * 255)
        let blue = Int(rgb.blueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
