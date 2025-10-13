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
    case modern
    case classic
    case rustic
    case bohemian
    case vintage
    case romantic
    case minimalist
    case industrial
    case garden
    case beach
    case mountain
    case urban
    case destination
    case cultural
    case seasonal
    case custom
    case glamorous
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
}

// MARK: - Color Harmony Type

enum ColorHarmonyType: String, CaseIterable, Codable, Hashable {
    case monochromatic
    case complementary
    case triadic
    case analogous
    case splitComplementary = "split-complementary"
    case tetradic
    case custom

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
    case image
    case color
    case text
    case inspiration

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
    case round
    case rectangular
    case square
    case oval

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
    case spring
    case summer
    case fall
    case winter

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
    case casual
    case semiCasual = "semi_casual"
    case semiformal
    case formal
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
    case smooth
    case rough
    case soft
    case metallic
    case wood
    case fabric
    case glass
    case stone
    case silk
    case lace
    case chiffon
    case velvet
    case linen
    case tulle
    case satin
    case organza
    case burlap
    case cotton
    case metal

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Trend Direction

enum TrendDirection: String, CaseIterable, Codable, Hashable {
    case up
    case down
    case stable

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
    case overspending
    case savings
    case seasonality
    case vendor
    case category
    case timeline
    case recommendation
    case warning
    case alert
    case info

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
    case shared

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
    case round
    case rectangular
    case uShape = "u_shape"
    case theater
    case cocktail
    case garden

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
