//
//  SupabaseDataModels.swift
//  My Wedding Planning App
//
//  Data Transfer Objects for Supabase integration
//

import Foundation
import SwiftUI

// MARK: - Mood Board DTO

struct MoodBoardDTO: Codable {
    let id: String
    let couple_id: String
    let board_name: String
    let board_description: String?
    let style_category: String
    let canvas_width: Double
    let canvas_height: Double
    let background_color: String
    let is_template: Bool
    let template_category: String?
    let tags: [String]?
    let created_at: String
    let updated_at: String

    // Enhanced fields from migration
    let version: Int?
    let is_favorite: Bool?
    let shared_with: [String]?
    let completion_percentage: Double?
    let last_accessed_at: String?
    let export_count: Int?
    let collaboration_enabled: Bool?
    let style_preferences: [String: String]?
    let inspiration_images: [String]?

    init(from moodBoard: MoodBoard) {
        id = moodBoard.id.uuidString
        couple_id = moodBoard.tenantId
        board_name = moodBoard.boardName
        board_description = moodBoard.boardDescription
        style_category = moodBoard.styleCategory.rawValue
        canvas_width = moodBoard.canvasSize.width
        canvas_height = moodBoard.canvasSize.height
        background_color = moodBoard.backgroundColor.hexString
        is_template = moodBoard.isTemplate
        template_category = nil
        tags = moodBoard.tags
        created_at = ISO8601DateFormatter().string(from: moodBoard.createdAt)
        updated_at = ISO8601DateFormatter().string(from: moodBoard.updatedAt)

        // Initialize enhanced fields with default values
        version = nil
        is_favorite = nil
        shared_with = nil
        completion_percentage = nil
        last_accessed_at = nil
        export_count = nil
        collaboration_enabled = nil
        style_preferences = nil
        inspiration_images = nil
    }

    func toMoodBoard(with elements: [VisualElement]) -> MoodBoard {
        var moodBoard = MoodBoard(
            id: UUID(uuidString: id) ?? UUID(),
            tenantId: couple_id,
            boardName: board_name,
            boardDescription: board_description,
            styleCategory: StyleCategory(rawValue: style_category) ?? .modern,
            canvasSize: CGSize(width: canvas_width, height: canvas_height),
            backgroundColor: Color.fromHex(background_color),
            isTemplate: is_template)

        // Can't assign to id since it's a let constant, already set in init
        moodBoard.tags = tags ?? []
        moodBoard.elements = elements // Assign the loaded elements
        moodBoard.createdAt = ISO8601DateFormatter().date(from: created_at) ?? Date()
        moodBoard.updatedAt = ISO8601DateFormatter().date(from: updated_at) ?? Date()

        return moodBoard
    }
}

// MARK: - Visual Element DTO

struct VisualElementDTO: Codable {
    let id: String
    let mood_board_id: String
    let couple_id: String
    let element_type: String
    let element_data: ElementDataDTO
    let position_x: Double
    let position_y: Double
    let width: Double
    let height: Double
    let rotation: Double
    let opacity: Double
    let z_index: Int
    let created_at: String
    let updated_at: String
    let is_locked: Bool?
    let notes: String?

    // Enhanced fields from migration
    let layer_name: String?
    let is_visible: Bool?
    let blend_mode: String?
    let filters: [String: AnyCodable]?
    let animation_settings: [String: AnyCodable]?
    let interaction_settings: [String: AnyCodable]?
    let metadata: [String: AnyCodable]?

    init(from element: VisualElement) {
        id = element.id.uuidString
        mood_board_id = element.moodBoardId.uuidString
        couple_id = "c507b4c9-7ef4-4b76-a71a-63887984b9ab" // Admin couple ID
        element_type = element.elementType.rawValue
        element_data = ElementDataDTO(from: element.elementData)
        position_x = element.position.x
        position_y = element.position.y
        width = element.size.width
        height = element.size.height
        rotation = element.rotation
        opacity = element.opacity
        z_index = element.zIndex
        created_at = ISO8601DateFormatter().string(from: element.createdAt)
        updated_at = ISO8601DateFormatter().string(from: element.updatedAt)
        is_locked = false
        notes = nil

        // Initialize enhanced fields with default values
        layer_name = nil
        is_visible = true
        blend_mode = nil
        filters = nil
        animation_settings = nil
        interaction_settings = nil
        metadata = nil
    }

    func toVisualElement() -> VisualElement {
        let elementData = element_data.toElementData()

        var element = VisualElement(
            id: UUID(uuidString: id) ?? UUID(),
            moodBoardId: UUID(uuidString: mood_board_id) ?? UUID(),
            elementType: ElementType(rawValue: element_type) ?? .image,
            elementData: elementData,
            position: CGPoint(x: position_x, y: position_y),
            size: CGSize(width: width, height: height),
            rotation: rotation,
            opacity: opacity,
            zIndex: z_index)

        element.createdAt = ISO8601DateFormatter().date(from: created_at) ?? Date()
        element.updatedAt = ISO8601DateFormatter().date(from: updated_at) ?? Date()

        return element
    }
}

// MARK: - Element Data DTO (for JSONB storage)

struct ElementDataDTO: Codable {
    let imageUrl: String?
    let thumbnailUrl: String?
    let color: String?
    let text: String?
    let fontSize: Double?
    let fontName: String?
    let textAlignment: String?
    let sourceUrl: String?
    let originalFilename: String?
    let fileSize: Int64?
    let dimensions: DimensionsDTO?
    let alt: String?

    init(from data: VisualElement.ElementData) {
        imageUrl = data.imageUrl
        thumbnailUrl = data.thumbnailUrl
        color = data.color?.hexString
        text = data.text
        fontSize = data.fontSize
        fontName = data.fontName
        textAlignment = data.textAlignment?.rawValue
        sourceUrl = data.sourceUrl
        originalFilename = data.originalFilename
        fileSize = data.fileSize
        dimensions = data.dimensions.map { DimensionsDTO(width: $0.width, height: $0.height) }
        alt = data.alt
    }

    func toElementData() -> VisualElement.ElementData {
        VisualElement.ElementData(
            imageUrl: imageUrl,
            thumbnailUrl: thumbnailUrl,
            color: color.flatMap { Color.fromHex($0) },
            text: text,
            fontSize: fontSize,
            fontName: fontName,
            textAlignment: textAlignment.flatMap { VisualElement.ElementData.TextAlignment(rawValue: $0) },
            sourceUrl: sourceUrl,
            originalFilename: originalFilename,
            fileSize: fileSize,
            dimensions: dimensions.map { CGSize(width: $0.width, height: $0.height) },
            alt: alt)
    }
}

struct DimensionsDTO: Codable {
    let width: Double
    let height: Double
}

// Helper for encoding arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = try container.decode([String: AnyCodable].self)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let dict = value as? [String: AnyCodable] {
            try container.encode(dict)
        }
    }
}

// MARK: - Color Palette DTO

struct ColorPaletteDTO: Codable {
    let id: String
    let couple_id: String
    let palette_name: String
    let palette_description: String?
    let primary_color: String
    let secondary_color: String
    let accent_color: String
    let neutral_color: String
    let season: String?
    let mood: String?
    let is_favorite: Bool
    let created_at: String
    let updated_at: String

    // Enhanced fields from migration
    let inspiration_source: String?
    let dominant_hue: Int?
    let saturation_level: Double?
    let brightness_level: Double?
    let temperature: String?
    let harmony_description: String?
    let export_formats: [String]?

    init(from palette: ColorPalette) {
        id = palette.id.uuidString
        couple_id = "" // New ColorPalette doesn't have tenantId
        palette_name = palette.name
        palette_description = palette.description

        // Extract colors from the colors array
        let colors = palette.colors.compactMap { Color.fromHexString($0) }
        primary_color = colors.first?.toHex() ?? "#000000"
        secondary_color = colors.count > 1 ? colors[1].toHex() : "#000000"
        accent_color = colors.count > 2 ? colors[2].toHex() : "#000000"
        neutral_color = colors.count > 3 ? colors[3].toHex() : "#FFFFFF"

        season = nil // New ColorPalette doesn't have season
        mood = nil // New ColorPalette doesn't have mood
        is_favorite = palette.isDefault // Use isDefault as favorite indicator
        created_at = ISO8601DateFormatter().string(from: palette.createdAt)
        updated_at = ISO8601DateFormatter().string(from: palette.updatedAt)

        // Initialize enhanced fields with default values
        inspiration_source = nil
        dominant_hue = nil
        saturation_level = nil
        brightness_level = nil
        temperature = nil
        harmony_description = nil
        export_formats = nil
    }

    func toColorPalette() -> ColorPalette {
        // Combine all color fields into a colors array
        var colorArray: [String] = []
        if !primary_color.isEmpty { colorArray.append(primary_color) }
        if !secondary_color.isEmpty { colorArray.append(secondary_color) }
        if !accent_color.isEmpty { colorArray.append(accent_color) }
        if !neutral_color.isEmpty { colorArray.append(neutral_color) }

        var palette = ColorPalette(
            id: UUID(uuidString: id) ?? UUID(),
            name: palette_name,
            colors: colorArray,
            description: palette_description,
            isDefault: is_favorite,
            createdAt: ISO8601DateFormatter().date(from: created_at) ?? Date(),
            updatedAt: ISO8601DateFormatter().date(from: updated_at) ?? Date())

        return palette
    }
}

// MARK: - Seating Chart DTO

struct SeatingChartDTO: Codable {
    let id: String
    let couple_id: String
    let chart_name: String
    let event_id: String?
    let notes: String?
    let canvas_width: Int?
    let canvas_height: Int?
    let is_finalized: Bool?
    let total_tables: Int?
    let total_seats: Int?
    let created_at: String?
    let updated_at: String?

    init(from chart: SeatingChart) {
        id = chart.id.uuidString
        couple_id = chart.tenantId
        chart_name = chart.chartName
        event_id = chart.eventId?.uuidString
        notes = chart.chartDescription
        canvas_width = Int(chart.venueConfiguration.dimensions.width)
        canvas_height = Int(chart.venueConfiguration.dimensions.height)
        is_finalized = chart.isFinalized
        total_tables = chart.tables.count
        total_seats = chart.tables.reduce(0) { $0 + $1.capacity }
        created_at = ISO8601DateFormatter().string(from: chart.createdAt)
        updated_at = ISO8601DateFormatter().string(from: chart.updatedAt)
    }

    func toSeatingChart(with tables: [Table], seatingGuests: [SeatingGuest]) -> SeatingChart {
        var venueConfig = VenueConfiguration()
        venueConfig.dimensions = CGSize(
            width: Double(canvas_width ?? 1200),
            height: Double(canvas_height ?? 800))

        var chart = SeatingChart(
            tenantId: couple_id,
            chartName: chart_name,
            eventId: event_id.flatMap { UUID(uuidString: $0) },
            venueLayoutType: .rectangular,
            venueConfiguration: venueConfig,
            chartDescription: notes,
            isFinalized: is_finalized ?? false)

        // Assign mutable properties
        chart.tables = tables
        chart.guests = seatingGuests
        chart.createdAt = ISO8601DateFormatter().date(from: created_at ?? "") ?? Date()
        chart.updatedAt = ISO8601DateFormatter().date(from: updated_at ?? "") ?? Date()

        return chart
    }
}

// MARK: - Table DTO

struct TableDTO: Codable {
    let id: String
    let couple_id: String
    let seating_chart_id: String?
    let table_number: Int
    let table_name: String?
    let position_x: Double?
    let position_y: Double?
    let table_shape: String?
    let seat_capacity: Int
    let rotation: Double?
    let created_at: String?
    let updated_at: String?

    init(from table: Table, chartId: UUID, coupleId: String) {
        id = table.id.uuidString
        couple_id = coupleId
        seating_chart_id = chartId.uuidString
        table_number = table.tableNumber
        table_name = table.tableName
        position_x = table.position.x
        position_y = table.position.y
        table_shape = table.tableShape.rawValue
        seat_capacity = table.capacity
        rotation = table.rotation
        created_at = nil
        updated_at = nil
    }

    func toTable() -> Table {
        var table = Table(
            tableNumber: table_number,
            position: CGPoint(x: position_x ?? 100, y: position_y ?? 100),
            shape: TableShape(rawValue: table_shape ?? "round") ?? .round,
            capacity: seat_capacity)
        table.rotation = rotation ?? 0
        if let name = table_name {
            table.tableName = name
        }
        return table
    }
}

// MARK: - Seat Assignment DTO

struct SeatAssignmentDTO: Codable {
    let id: String
    let couple_id: String
    let guest_id: String?
    let table_id: String?
    let seat_number: Int
    let notes: String?
    let assigned_at: String?
    let created_at: String?
    let updated_at: String?

    init(from assignment: SeatingAssignment, coupleId: String) {
        id = assignment.id.uuidString
        couple_id = coupleId
        guest_id = assignment.guestId.uuidString
        table_id = assignment.tableId.uuidString
        seat_number = assignment.seatNumber ?? 0
        notes = assignment.notes
        assigned_at = ISO8601DateFormatter().string(from: assignment.assignedAt)
        created_at = nil
        updated_at = nil
    }

    func toSeatingAssignment() -> SeatingAssignment {
        var assignment = SeatingAssignment(
            guestId: UUID(uuidString: guest_id ?? "") ?? UUID(),
            tableId: UUID(uuidString: table_id ?? "") ?? UUID(),
            seatNumber: seat_number)

        assignment.assignedAt = ISO8601DateFormatter().date(from: assigned_at ?? "") ?? Date()
        assignment.notes = notes ?? ""
        return assignment
    }
}

// MARK: - Style Preferences DTO

struct StylePreferencesDTO: Codable {
    let id: String
    let couple_id: String
    let primary_style: String?
    let style_influences: [String]
    let formality_level: String?
    let season: String?
    let primary_colors: [String]
    let color_harmony: String?
    let preferred_textures: [String]
    let inspiration_keywords: [String]
    let visual_themes: String? // JSON encoded VisualTheme array
    let style_guidelines: String? // JSON encoded StyleGuidelines
    let created_at: String
    let updated_at: String

    init(from preferences: StylePreferences) {
        id = UUID().uuidString // Generate new ID for upsert
        couple_id = preferences.tenantId
        primary_style = preferences.primaryStyle?.rawValue
        style_influences = preferences.styleInfluences.map(\.rawValue)
        formality_level = preferences.formalityLevel?.rawValue
        season = preferences.season?.rawValue
        primary_colors = preferences.primaryColors.map { $0.toHex() }
        color_harmony = preferences.colorHarmony?.rawValue
        preferred_textures = preferences.preferredTextures.map(\.rawValue)
        inspiration_keywords = preferences.inspirationKeywords

        if let themes = try? JSONEncoder().encode(preferences.visualThemes) {
            visual_themes = String(data: themes, encoding: .utf8)
        } else {
            visual_themes = nil
        }

        if let guidelines = try? JSONEncoder().encode(preferences.guidelines) {
            style_guidelines = String(data: guidelines, encoding: .utf8)
        } else {
            style_guidelines = nil
        }

        created_at = ISO8601DateFormatter().string(from: preferences.createdAt)
        updated_at = ISO8601DateFormatter().string(from: preferences.updatedAt)
    }

    func toStylePreferences() -> StylePreferences {
        var preferences = StylePreferences(tenantId: couple_id)

        preferences.primaryStyle = primary_style.flatMap { StyleCategory(rawValue: $0) }
        preferences.styleInfluences = style_influences.compactMap { StyleCategory(rawValue: $0) }
        preferences.formalityLevel = formality_level.flatMap { FormalityLevel(rawValue: $0) }
        preferences.season = season.flatMap { WeddingSeason(rawValue: $0) }
        preferences.primaryColors = primary_colors.compactMap { Color.fromHex($0) }
        preferences.colorHarmony = color_harmony.flatMap { ColorHarmonyType(rawValue: $0) }
        preferences.preferredTextures = preferred_textures.compactMap { TextureType(rawValue: $0) }
        preferences.inspirationKeywords = inspiration_keywords

        if let themesData = visual_themes?.data(using: .utf8),
           let themes = try? JSONDecoder().decode([VisualTheme].self, from: themesData) {
            preferences.visualThemes = themes
        }

        if let guidelinesData = style_guidelines?.data(using: .utf8),
           let guidelines = try? JSONDecoder().decode(StyleGuidelines.self, from: guidelinesData) {
            preferences.guidelines = guidelines
        }

        preferences.createdAt = ISO8601DateFormatter().date(from: created_at) ?? Date()
        preferences.updatedAt = ISO8601DateFormatter().date(from: updated_at) ?? Date()

        return preferences
    }
}

// MARK: - Guest DTO (for integration with existing guest system)

struct GuestDTO: Codable {
    let id: String
    let couple_id: String
    let first_name: String
    let last_name: String
    let email: String?
    let phone: String?
    let rsvp_status: String
    let dietary_restrictions: String?
    let plus_one_name: String?
    let table_assignment: String?
    let created_at: String
    let updated_at: String

    /// Converts GuestDTO to Guest model
    /// - Throws: ConversionError if required fields are invalid
    /// - Returns: Guest model instance
    func toGuest() throws -> Guest {
        // Validate UUID format
        guard let guestId = UUID(uuidString: id) else {
            throw ConversionError.invalidUUID(id)
        }

        guard let coupleId = UUID(uuidString: couple_id) else {
            throw ConversionError.invalidUUID(couple_id)
        }

        // Parse dates
        let formatter = ISO8601DateFormatter()
        let createdDate = formatter.date(from: created_at) ?? Date()
        let updatedDate = formatter.date(from: updated_at) ?? Date()

        // Parse RSVP status
        let rsvpStatus = RSVPStatus(rawValue: rsvp_status) ?? .pending

        // Parse table assignment
        let tableNumber: Int? = table_assignment.flatMap { Int($0) }

        // Create Guest instance with all required fields
        return Guest(
            id: guestId,
            createdAt: createdDate,
            updatedAt: updatedDate,
            firstName: first_name,
            lastName: last_name,
            email: email,
            phone: phone,
            guestGroupId: nil,
            relationshipToCouple: nil,
            invitedBy: nil,
            rsvpStatus: rsvpStatus,
            rsvpDate: nil,
            plusOneAllowed: plus_one_name != nil,
            plusOneName: plus_one_name,
            plusOneAttending: false,
            attendingCeremony: true,
            attendingReception: true,
            attendingOtherEvents: nil,
            dietaryRestrictions: dietary_restrictions,
            accessibilityNeeds: nil,
            tableAssignment: tableNumber,
            seatNumber: nil,
            preferredContactMethod: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            invitationNumber: nil,
            isWeddingParty: false,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: coupleId,
            mealOption: nil,
            giftReceived: false,
            notes: nil,
            hairDone: false,
            makeupDone: false
        )
    }

    /// Converts GuestDTO to Guest model, returning nil on failure
    /// - Returns: Guest model instance or nil if conversion fails
    func toGuestOrNil() -> Guest? {
        do {
            return try toGuest()
        } catch {
            AppLogger.database.error("Failed to convert GuestDTO to Guest", error: error)
            return nil
        }
    }
}

// MARK: - Color Extensions for Hex Conversion

extension Color {
    func toHex() -> String {
        let components = cgColor?.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    // Note: hexString and fromHex are defined in AccessibilityAudit.swift Color extension
}
