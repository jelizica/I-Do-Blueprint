//
//  SharedEnums.swift
//  My Wedding Planning App
//
//  Shared enum definitions for visual planning components
//

import Foundation
import SwiftUI

// MARK: - Style Category

enum StyleCategory: String, CaseIterable, Codable, Hashable {
    case modern = "modern"
    case classic = "classic"
    case rustic = "rustic"
    case bohemian = "bohemian"
    case vintage = "vintage"
    case romantic = "romantic"
    case minimalist = "minimalist"
    case industrial = "industrial"
    case garden = "garden"
    case beach = "beach"
    case mountain = "mountain"
    case urban = "urban"
    case destination = "destination"
    case cultural = "cultural"
    case seasonal = "seasonal"
    case custom = "custom"
    case glamorous = "glamorous"
    case beachCoastal = "beach_coastal"

    var displayName: String {
        switch self {
        case .modern: "Modern"
        case .classic: "Classic"
        case .rustic: "Rustic"
        case .bohemian: "Bohemian"
        case .vintage: "Vintage"
        case .romantic: "Romantic"
        case .minimalist: "Minimalist"
        case .industrial: "Industrial"
        case .garden: "Garden"
        case .beach: "Beach"
        case .mountain: "Mountain"
        case .urban: "Urban"
        case .destination: "Destination"
        case .cultural: "Cultural"
        case .seasonal: "Seasonal"
        case .custom: "Custom"
        case .glamorous: "Glamorous"
        case .beachCoastal: "Beach & Coastal"
        }
    }

    var icon: String {
        switch self {
        case .modern: "building"
        case .classic: "leaf"
        case .rustic: "tree"
        case .bohemian: "star"
        case .vintage: "clock"
        case .romantic: "heart"
        case .minimalist: "square"
        case .industrial: "gear"
        case .garden: "leaf.arrow.circlepath"
        case .beach: "sun.max"
        case .mountain: "mountain.2"
        case .urban: "building.2"
        case .destination: "airplane"
        case .cultural: "globe"
        case .seasonal: "calendar"
        case .custom: "pencil"
        case .glamorous: "sparkle"
        case .beachCoastal: "water.waves"
        }
    }

    var iconName: String {
        icon
    }

    /// Suggested color palette for this wedding style
    var suggestedColors: [Color] {
        switch self {
        case .classic:
            return [
                Color(red: 1.0, green: 1.0, blue: 1.0),      // White
                Color(red: 0.96, green: 0.96, blue: 0.86),   // Beige
                Color(red: 0.75, green: 0.75, blue: 0.75),   // Silver
                Color(red: 1.0, green: 0.84, blue: 0.0)      // Gold
            ]
        case .rustic:
            return [
                Color(red: 0.55, green: 0.27, blue: 0.07),   // Brown
                Color(red: 0.96, green: 0.64, blue: 0.38),   // Sandy Brown
                Color(red: 0.87, green: 0.72, blue: 0.53),   // Burlywood
                Color(red: 0.33, green: 0.42, blue: 0.18)    // Dark Olive Green
            ]
        case .modern:
            return [
                Color(red: 0.0, green: 0.0, blue: 0.0),      // Black
                Color(red: 1.0, green: 1.0, blue: 1.0),      // White
                Color(red: 0.5, green: 0.5, blue: 0.5),      // Gray
                Color(red: 1.0, green: 0.42, blue: 0.42)     // Coral
            ]
        case .bohemian:
            return [
                Color(red: 0.90, green: 0.72, blue: 0.61),   // Peach
                Color(red: 0.62, green: 0.51, blue: 0.54),   // Mauve
                Color(red: 0.29, green: 0.34, blue: 0.35),   // Slate
                Color(red: 0.96, green: 0.91, blue: 0.76)    // Cream
            ]
        case .vintage:
            return [
                Color(red: 1.0, green: 0.71, blue: 0.76),    // Light Pink
                Color(red: 0.90, green: 0.90, blue: 0.98),   // Lavender
                Color(red: 0.94, green: 0.90, blue: 0.55),   // Khaki
                Color(red: 0.87, green: 0.63, blue: 0.87)    // Plum
            ]
        case .beach, .beachCoastal:
            return [
                Color(red: 0.53, green: 0.81, blue: 0.92),   // Sky Blue
                Color(red: 0.94, green: 0.90, blue: 0.55),   // Khaki
                Color(red: 1.0, green: 1.0, blue: 1.0),      // White
                Color(red: 1.0, green: 0.89, blue: 0.71)     // Moccasin
            ]
        case .garden:
            return [
                Color(red: 0.56, green: 0.93, blue: 0.56),   // Light Green
                Color(red: 1.0, green: 0.71, blue: 0.76),    // Light Pink
                Color(red: 1.0, green: 0.98, blue: 0.80),    // Lemon Chiffon
                Color(red: 0.88, green: 1.0, blue: 1.0)      // Light Cyan
            ]
        case .glamorous:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),     // Gold
                Color(red: 0.0, green: 0.0, blue: 0.0),      // Black
                Color(red: 1.0, green: 1.0, blue: 1.0),      // White
                Color(red: 0.75, green: 0.75, blue: 0.75)    // Silver
            ]
        case .romantic:
            return [
                Color(red: 1.0, green: 0.75, blue: 0.80),    // Pink
                Color(red: 0.96, green: 0.96, blue: 0.86),   // Cream
                Color(red: 0.93, green: 0.51, blue: 0.93),   // Violet
                Color(red: 1.0, green: 0.84, blue: 0.0)      // Gold
            ]
        case .minimalist:
            return [
                Color(red: 1.0, green: 1.0, blue: 1.0),      // White
                Color(red: 0.0, green: 0.0, blue: 0.0),      // Black
                Color(red: 0.9, green: 0.9, blue: 0.9),      // Light Gray
                Color(red: 0.3, green: 0.3, blue: 0.3)       // Dark Gray
            ]
        case .industrial:
            return [
                Color(red: 0.3, green: 0.3, blue: 0.3),      // Charcoal
                Color(red: 0.5, green: 0.5, blue: 0.5),      // Gray
                Color(red: 0.7, green: 0.4, blue: 0.2),      // Copper
                Color(red: 0.2, green: 0.2, blue: 0.2)       // Dark Gray
            ]
        case .mountain:
            return [
                Color(red: 0.4, green: 0.5, blue: 0.4),      // Forest Green
                Color(red: 0.55, green: 0.47, blue: 0.37),   // Brown
                Color(red: 0.9, green: 0.9, blue: 0.9),      // Snow White
                Color(red: 0.4, green: 0.5, blue: 0.6)       // Slate Blue
            ]
        case .urban:
            return [
                Color(red: 0.2, green: 0.2, blue: 0.2),      // Dark Gray
                Color(red: 0.9, green: 0.9, blue: 0.9),      // Light Gray
                Color(red: 0.0, green: 0.5, blue: 0.8),      // Blue
                Color(red: 1.0, green: 0.5, blue: 0.0)       // Orange
            ]
        case .destination:
            return [
                Color(red: 0.0, green: 0.7, blue: 0.9),      // Tropical Blue
                Color(red: 1.0, green: 0.8, blue: 0.0),      // Sunshine Yellow
                Color(red: 1.0, green: 0.4, blue: 0.4),      // Coral
                Color(red: 0.2, green: 0.8, blue: 0.6)       // Turquoise
            ]
        case .cultural:
            return [
                Color(red: 0.8, green: 0.2, blue: 0.2),      // Red
                Color(red: 1.0, green: 0.84, blue: 0.0),     // Gold
                Color(red: 0.4, green: 0.2, blue: 0.6),      // Purple
                Color(red: 0.0, green: 0.5, blue: 0.3)       // Green
            ]
        case .seasonal:
            return [
                Color(red: 0.8, green: 0.4, blue: 0.2),      // Autumn Orange
                Color(red: 0.6, green: 0.2, blue: 0.2),      // Burgundy
                Color(red: 0.9, green: 0.7, blue: 0.3),      // Golden Yellow
                Color(red: 0.3, green: 0.5, blue: 0.3)       // Evergreen
            ]
        case .custom:
            return [
                Color(red: 0.5, green: 0.5, blue: 0.8),      // Periwinkle
                Color(red: 0.8, green: 0.6, blue: 0.8),      // Lavender
                Color(red: 0.6, green: 0.8, blue: 0.8),      // Aqua
                Color(red: 0.9, green: 0.8, blue: 0.6)       // Champagne
            ]
        }
    }
}

// MARK: - Color Harmony Type

enum ColorHarmonyType: String, CaseIterable, Codable, Hashable {
    case monochromatic = "monochromatic"
    case complementary = "complementary"
    case triadic = "triadic"
    case analogous = "analogous"
    case splitComplementary = "split-complementary"
    case tetradic = "tetradic"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .monochromatic: "Monochromatic"
        case .complementary: "Complementary"
        case .triadic: "Triadic"
        case .analogous: "Analogous"
        case .splitComplementary: "Split-Complementary"
        case .tetradic: "Tetradic"
        case .custom: "Custom"
        }
    }

    var description: String {
        switch self {
        case .monochromatic: "Uses variations of a single color"
        case .complementary: "Uses colors opposite on the color wheel"
        case .triadic: "Uses three evenly spaced colors"
        case .analogous: "Uses colors next to each other"
        case .splitComplementary: "Uses a base color and two adjacent to its complement"
        case .tetradic: "Uses four colors forming a rectangle"
        case .custom: "Custom color combination"
        }
    }
}

// MARK: - Element Type

enum ElementType: String, CaseIterable, Codable, Hashable {
    case image = "image"
    case color = "color"
    case text = "text"
    case inspiration = "inspiration"

    var displayName: String {
        switch self {
        case .image: "Image"
        case .color: "Color"
        case .text: "Text"
        case .inspiration: "Inspiration"
        }
    }

    var icon: String {
        switch self {
        case .image: "photo"
        case .color: "paintbrush"
        case .text: "textformat"
        case .inspiration: "lightbulb"
        }
    }
}

// MARK: - Table Shape

enum TableShape: String, CaseIterable, Codable, Hashable {
    case round = "round"
    case rectangular = "rectangular"
    case square = "square"
    case oval = "oval"

    var displayName: String {
        switch self {
        case .round: "Round"
        case .rectangular: "Rectangular"
        case .square: "Square"
        case .oval: "Oval"
        }
    }
}

// MARK: - Wedding Season

enum WeddingSeason: String, CaseIterable, Codable, Hashable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"

    var displayName: String {
        switch self {
        case .spring: "Spring"
        case .summer: "Summer"
        case .fall: "Fall"
        case .winter: "Winter"
        }
    }

    var colors: [Color] {
        switch self {
        case .spring:
            [.green, .pink, .yellow, .purple]
        case .summer:
            [.blue, .cyan, .yellow, .orange]
        case .fall:
            [.orange, .red, .brown, .yellow]
        case .winter:
            [.blue, .white, .gray, .purple]
        }
    }
}

// MARK: - Formality Level

enum FormalityLevel: String, CaseIterable, Codable, Hashable {
    case casual = "casual"
    case semiCasual = "semi_casual"
    case semiformal = "semiformal"
    case formal = "formal"
    case blackTie = "black_tie"
    case whiteTie = "white_tie"

    var displayName: String {
        switch self {
        case .casual: "Casual"
        case .semiCasual: "Semi-Casual"
        case .semiformal: "Semi-Formal"
        case .formal: "Formal"
        case .blackTie: "Black Tie"
        case .whiteTie: "White Tie"
        }
    }
}

// MARK: - Texture Type

enum TextureType: String, CaseIterable, Codable, Hashable {
    case smooth = "smooth"
    case rough = "rough"
    case soft = "soft"
    case metallic = "metallic"
    case wood = "wood"
    case fabric = "fabric"
    case glass = "glass"
    case stone = "stone"
    case silk = "silk"
    case lace = "lace"
    case chiffon = "chiffon"
    case velvet = "velvet"
    case linen = "linen"
    case tulle = "tulle"
    case satin = "satin"
    case organza = "organza"
    case burlap = "burlap"
    case cotton = "cotton"
    case metal = "metal"

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Trend Direction

enum TrendDirection: String, CaseIterable, Codable, Hashable {
    case up = "up"
    case down = "down"
    case stable = "stable"

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .stable: "minus"
        }
    }

    var iconName: String {
        icon
    }

    var color: Color {
        switch self {
        case .up: .green
        case .down: .red
        case .stable: .gray
        }
    }
}

// MARK: - Insight Type

enum InsightType: String, CaseIterable, Codable, Hashable {
    case overspending = "overspending"
    case savings = "savings"
    case seasonality = "seasonality"
    case vendor = "vendor"
    case category = "category"
    case timeline = "timeline"
    case recommendation = "recommendation"
    case warning = "warning"
    case alert = "alert"
    case info = "info"

    var displayName: String {
        switch self {
        case .overspending: "Overspending Alert"
        case .savings: "Savings Opportunity"
        case .seasonality: "Seasonal Trend"
        case .vendor: "Vendor Insight"
        case .category: "Category Analysis"
        case .timeline: "Timeline Impact"
        case .recommendation: "Recommendation"
        case .warning: "Warning"
        case .alert: "Alert"
        case .info: "Info"
        }
    }

    var icon: String {
        switch self {
        case .overspending: "exclamationmark.triangle"
        case .savings: "dollarsign.circle"
        case .seasonality: "calendar"
        case .vendor: "person.circle"
        case .category: "folder"
        case .timeline: "clock"
        case .recommendation: "lightbulb"
        case .warning: "exclamationmark.triangle"
        case .alert: "bell"
        case .info: "info.circle"
        }
    }

    var color: Color {
        switch self {
        case .overspending, .warning, .alert: .red
        case .savings: .green
        case .seasonality, .timeline: .blue
        case .vendor, .category: .orange
        case .recommendation, .info: .blue
        }
    }
}

// MARK: - Palette Visibility

enum PaletteVisibility: String, CaseIterable, Codable, Hashable {
    case publicPalette = "public"
    case privatePalette = "private"
    case shared = "shared"

    var displayName: String {
        switch self {
        case .publicPalette: "Public"
        case .privatePalette: "Private"
        case .shared: "Shared"
        }
    }

    var iconName: String {
        switch self {
        case .privatePalette: "lock"
        case .shared: "person.2"
        case .publicPalette: "globe"
        }
    }

    var description: String {
        switch self {
        case .privatePalette: "Only visible to you"
        case .shared: "Shared with specific users"
        case .publicPalette: "Publicly accessible"
        }
    }
}

// MARK: - Venue Layout

enum VenueLayout: String, CaseIterable, Codable, Hashable {
    case round = "round"
    case rectangular = "rectangular"
    case uShape = "u_shape"
    case theater = "theater"
    case cocktail = "cocktail"
    case garden = "garden"

    var displayName: String {
        switch self {
        case .round: "Round Tables"
        case .rectangular: "Rectangular Tables"
        case .uShape: "U-Shape"
        case .theater: "Theater Style"
        case .cocktail: "Cocktail Style"
        case .garden: "Garden Style"
        }
    }
}
