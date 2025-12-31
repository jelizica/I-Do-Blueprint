//
//  ExportTemplate.swift
//  I Do Blueprint
//
//  Data models for export templates
//

import Foundation
import SwiftUI

// MARK: - Export Template

struct ExportTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: ExportCategory
    let outputFormat: ExportFormat
    let features: [TemplateFeature]
    let previewImage: String?
    let isCustom: Bool
    let customLayout: TemplateLayout?

    init(
        id: String,
        name: String,
        description: String,
        category: ExportCategory,
        outputFormat: ExportFormat,
        features: [TemplateFeature],
        previewImage: String? = nil,
        isCustom: Bool = false,
        customLayout: TemplateLayout? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.outputFormat = outputFormat
        self.features = features
        self.previewImage = previewImage
        self.isCustom = isCustom
        self.customLayout = customLayout
    }
}

// MARK: - Export Category

enum ExportCategory: String, CaseIterable, Codable {
    case moodBoard = "mood_board"
    case colorPalette = "color_palette"
    case seatingChart = "seating_chart"
    case comprehensive = "comprehensive"

    var displayName: String {
        switch self {
        case .moodBoard: "Mood Board"
        case .colorPalette: "Color Palette"
        case .seatingChart: "Seating Chart"
        case .comprehensive: "Comprehensive"
        }
    }

    var icon: String {
        switch self {
        case .moodBoard: "photo.on.rectangle.angled"
        case .colorPalette: "paintpalette"
        case .seatingChart: "tablecells"
        case .comprehensive: "doc.richtext"
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Codable {
    case pdf = "pdf"
    case png = "png"
    case jpeg = "jpeg"
    case svg = "svg"

    var displayName: String {
        rawValue.uppercased()
    }

    var fileExtension: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .pdf: "doc.richtext"
        case .png, .jpeg: "photo"
        case .svg: "square.and.pencil"
        }
    }
}

// MARK: - Export Quality

enum ExportQuality: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var title: String {
        switch self {
        case .low: "Low (72 DPI)"
        case .medium: "Medium (150 DPI)"
        case .high: "High (300 DPI)"
        case .ultra: "Ultra (600 DPI)"
        }
    }
    
    var dpi: CGFloat {
        switch self {
        case .low: 72
        case .medium: 150
        case .high: 300
        case .ultra: 600
        }
    }
    
    var scale: CGFloat {
        dpi / 72.0 // 72 DPI is the default screen resolution
    }
}

// MARK: - Template Feature

enum TemplateFeature: String, CaseIterable, Codable {
    case coverPage = "cover_page"
    case tableOfContents = "table_of_contents"
    case metadata = "metadata"
    case descriptions = "descriptions"
    case colorPalette = "color_palette"
    case styleGuide = "style_guide"
    case hexCodes = "hex_codes"
    case colorNames = "color_names"
    case usageGuide = "usage_guide"
    case accessibility = "accessibility"
    case printing = "printing"
    case cmykValues = "cmyk_values"
    case pantoneMatching = "pantone_matching"
    case printOptimized = "print_optimized"
    case guestList = "guest_list"
    case tableDetails = "table_details"
    case specialRequirements = "special_requirements"
    case decorativeElements = "decorative_elements"
    case measurements = "measurements"
    case staffNotes = "staff_notes"
    case accessibilityInfo = "accessibility_info"
    case emergencyExits = "emergency_exits"
    case specifications = "specifications"
    case requirements = "requirements"
    case contactInfo = "contact_info"
    case timeline = "timeline"
    case vendorContacts = "vendor_contacts"
    case budgetAllocation = "budget_allocation"
    case moodBoards = "mood_boards"
    case colorPalettes = "color_palettes"
    case seatingCharts = "seating_charts"
    case collageLayout = "collage_layout"
    case socialOptimized = "social_optimized"
    case branding = "branding"

    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var description: String {
        switch self {
        case .coverPage: "Professional cover page with title and branding"
        case .tableOfContents: "Organized table of contents for navigation"
        case .metadata: "Detailed information about each element"
        case .descriptions: "Comprehensive descriptions and inspiration notes"
        case .colorPalette: "Color swatches and palette information"
        case .styleGuide: "Complete style guide with guidelines"
        case .hexCodes: "Precise hex color codes for reproduction"
        case .guestList: "Complete guest list with seating assignments"
        case .socialOptimized: "Optimized dimensions for social media sharing"
        case .branding: "Custom branding and watermarks"
        default: displayName
        }
    }
}

// MARK: - Template Layout

struct TemplateLayout: Codable {
    var pageSize: CGSize
    var margins: CodableEdgeInsets
    var columns: Int
    var spacing: CGFloat
    var headerHeight: CGFloat
    var footerHeight: CGFloat
}

// MARK: - Codable Edge Insets

struct CodableEdgeInsets: Codable {
    var top: CGFloat
    var leading: CGFloat
    var bottom: CGFloat
    var trailing: CGFloat

    init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    var edgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}
