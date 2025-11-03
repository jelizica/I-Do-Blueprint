//
//  SupabaseVisualPlanningService.swift
//  My Wedding Planning App
//
//  Supabase integration service for visual planning data persistence and sync
//

import Combine
import Foundation
import Supabase
import SwiftUI

@MainActor
class SupabaseVisualPlanningService: ObservableObject {
    private let supabase: SupabaseClient?

    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [SupabaseError] = []
    @Published var configurationError: ConfigurationError?
    private let logger = AppLogger.api

    init() {
        // Try to initialize, but don't crash on failure
        do {
            self.supabase = try Self.createSupabaseClient()
            self.configurationError = nil
        } catch let error as ConfigurationError {
            logger.error("Configuration error during SupabaseVisualPlanningService initialization", error: error)
            self.supabase = nil
            self.configurationError = error
        } catch {
            logger.error("Unexpected error during SupabaseVisualPlanningService initialization", error: error)
            self.supabase = nil
            self.configurationError = .configFileUnreadable
        }
    }

    // MARK: - Client Creation (Throwing)

    private static func createSupabaseClient() throws -> SupabaseClient {
        let logger = AppLogger.api

        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            logger.error("Config.plist file not found in bundle")
            throw ConfigurationError.configFileNotFound
        }

        guard let config = NSDictionary(contentsOfFile: configPath) else {
            logger.error("Could not read Config.plist contents")
            throw ConfigurationError.configFileUnreadable
        }

        guard let supabaseURLString = config["SUPABASE_URL"] as? String else {
            logger.error("SUPABASE_URL not found or not a string")
            throw ConfigurationError.missingSupabaseURL
        }

        guard let supabaseAnonKey = config["SUPABASE_ANON_KEY"] as? String else {
            logger.error("SUPABASE_ANON_KEY not found or not a string")
            throw ConfigurationError.missingSupabaseAnonKey
        }

        guard let supabaseURL = URL(string: supabaseURLString) else {
            logger.error("Invalid URL format")
            throw ConfigurationError.invalidURLFormat(supabaseURLString)
        }

        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                db: .init(schema: "public"),
                auth: .init(flowType: .pkce),
                global: .init(
                    headers: ["x-client-info": "wedding-app-visual-planning/1.0.0"])))
    }

    // MARK: - Mood Board Operations

    func saveMoodBoard(_ moodBoard: MoodBoard) async throws {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        logger.debug("SupabaseService: Preparing to save mood board \(moodBoard.id)")
        let moodBoardData = MoodBoardDTO(from: moodBoard)
        logger.debug("SupabaseService: Created DTO with name: \(moodBoardData.board_name), tenant: \(moodBoardData.couple_id)")

        do {
            try await supabase
                .from("mood_boards")
                .upsert(moodBoardData)
                .execute()
            logger.debug("SupabaseService: Mood board data saved")
        } catch {
            logger.error("SupabaseService: Failed to save mood board", error: error)
            throw error
        }

        // Save elements separately
        logger.debug("SupabaseService: Saving \(moodBoard.elements.count) elements")
        for (index, element) in moodBoard.elements.enumerated() {
            let elementData = VisualElementDTO(from: element)
            logger.debug("SupabaseService: Element \(index + 1) - mood_board_id: \(elementData.mood_board_id), element_id: \(elementData.id)")
            do {
                try await supabase
                    .from("visual_elements")
                    .upsert(elementData)
                    .execute()
                logger.debug("SupabaseService: Element \(index + 1)/\(moodBoard.elements.count) saved")
            } catch {
                logger.error("SupabaseService: Failed to save element \(index + 1)", error: error)
                logger.error("Element data: mood_board_id=\(elementData.mood_board_id), id=\(elementData.id)")
                throw error
            }
        }

        lastSyncDate = Date()
        logger.info("SupabaseService: All data saved successfully")
    }

    func fetchMoodBoards(for tenantId: String) async throws -> [MoodBoard] {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        let response: [MoodBoardDTO] = try await supabase
            .from("mood_boards")
            .select("*")
            .eq("couple_id", value: tenantId)
            .order("created_at", ascending: false)
            .execute()
            .value

        var moodBoards: [MoodBoard] = []

        for dto in response {
            let elements = try await fetchElements(for: dto.id)
            let moodBoard = dto.toMoodBoard(with: elements)
            moodBoards.append(moodBoard)
        }

        return moodBoards
    }

    func deleteMoodBoard(id: UUID) async throws {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        // Delete elements first
        try await supabase
            .from("visual_elements")
            .delete()
            .eq("mood_board_id", value: id.uuidString)
            .execute()

        // Delete mood board
        try await supabase
            .from("mood_boards")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        lastSyncDate = Date()
    }

    // MARK: - Color Palette Operations

    func saveColorPalette(_ palette: ColorPalette) async throws {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        let paletteData = ColorPaletteDTO(from: palette)

        try await supabase
            .from("color_palettes")
            .upsert(paletteData)
            .execute()

        lastSyncDate = Date()
    }

    func fetchColorPalettes(for tenantId: String) async throws -> [ColorPalette] {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        let response: [ColorPaletteDTO] = try await supabase
            .from("color_palettes")
            .select("*")
            .eq("couple_id", value: tenantId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response.map { $0.toColorPalette() }
    }

    func deleteColorPalette(id: UUID) async throws {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        try await supabase
            .from("color_palettes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        lastSyncDate = Date()
    }

    // MARK: - Seating Chart Operations

    func saveSeatingChart(_ chart: SeatingChart) async throws {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        let chartData = SeatingChartDTO(from: chart)

        try await supabase
            .from("seating_charts")
            .upsert(chartData)
            .execute()

        // Save tables and assignments
        for table in chart.tables {
            let tableData = TableDTO(from: table, chartId: chart.id, coupleId: chart.tenantId)
            try await supabase
                .from("seating_tables")
                .upsert(tableData)
                .execute()
        }

        for assignment in chart.seatingAssignments {
            let assignmentData = SeatAssignmentDTO(from: assignment, coupleId: chart.tenantId)
            try await supabase
                .from("seat_assignments")
                .upsert(assignmentData)
                .execute()
        }

        lastSyncDate = Date()
    }

    func fetchSeatingCharts(for tenantId: String) async throws -> [SeatingChart] {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        let response: [SeatingChartDTO] = try await supabase
            .from("seating_charts")
            .select("*")
            .eq("couple_id", value: tenantId)
            .order("created_at", ascending: false)
            .execute()
            .value

        var charts: [SeatingChart] = []

        // Fetch all guests once for all charts
        let allGuests = try await fetchSeatingGuests(for: tenantId)

        for dto in response {
            let tables = try await fetchTables(for: dto.id)
            let chart = dto.toSeatingChart(with: tables, seatingGuests: allGuests)
            charts.append(chart)
        }

        return charts
    }

    // MARK: - Style Preferences Operations

    func saveStylePreferences(_ preferences: StylePreferences) async throws {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        let preferencesData = StylePreferencesDTO(from: preferences)

        try await supabase
            .from("style_preferences")
            .upsert(preferencesData)
            .execute()

        lastSyncDate = Date()
    }

    func fetchStylePreferences(for tenantId: String) async throws -> StylePreferences? {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        isLoading = true
        defer { isLoading = false }

        let response: [StylePreferencesDTO] = try await supabase
            .from("style_preferences")
            .select("*")
            .eq("couple_id", value: tenantId)
            .limit(1)
            .execute()
            .value

        return response.first?.toStylePreferences()
    }

    // MARK: - Real-time Sync

    func setupRealtimeSync(for _: String) {
        // Real-time collaboration: Requires Supabase Realtime setup
        // Future implementation:
        // 1. Subscribe to changes on mood_boards, color_palettes, seating_charts tables
        // 2. Listen for INSERT, UPDATE, DELETE events
        // 3. Update local state when remote changes detected
        // 4. Implement conflict resolution for simultaneous edits
        // 5. Show presence indicators for active collaborators
        // Note: Real-time functionality currently disabled due to API changes
        // Task {
        //     let moodBoardChannel = await supabase.channel("mood-boards-\(tenantId)")
        //     // Configure real-time subscriptions here
        // }
    }

    private func handleMoodBoardChange(_ payload: [String: Any]) async {
        // Handle real-time updates from other users
        if let eventType = payload["eventType"] as? String {
            switch eventType {
            case "INSERT", "UPDATE":
                // Refresh mood boards
                NotificationCenter.default.post(name: .moodBoardUpdated, object: payload["new"])
            case "DELETE":
                NotificationCenter.default.post(name: .moodBoardDeleted, object: payload["old"])
            default:
                break
            }
        }
    }

    // MARK: - Helper Methods

    private func fetchElements(for moodBoardId: String) async throws -> [VisualElement] {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        let response: [VisualElementDTO] = try await supabase
            .from("visual_elements")
            .select("*")
            .eq("mood_board_id", value: moodBoardId)
            .execute()
            .value

        return response.map { $0.toVisualElement() }
    }

    private func fetchTables(for chartId: String) async throws -> [Table] {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        let response: [TableDTO] = try await supabase
            .from("seating_tables")
            .select("*")
            .eq("seating_chart_id", value: chartId)
            .execute()
            .value

        return response.map { $0.toTable() }
    }

    private func fetchSeatAssignments(for chartId: String) async throws -> [SeatingAssignment] {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        let response: [SeatAssignmentDTO] = try await supabase
            .from("seat_assignments")
            .select("*")
            .eq("table_id", value: chartId)
            .execute()
            .value

        return response.map { $0.toSeatingAssignment() }
    }

    func fetchSeatingGuests(for tenantId: String) async throws -> [SeatingGuest] {
        guard let supabase = supabase else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        // Fetch from guest_list table
        struct GuestListDTO: Codable {
            let id: String
            let first_name: String
            let last_name: String
            let guest_group_id: String?
            let rsvp_status: String?
            let dietary_restrictions: String?
            let accessibility_needs: String?
            let attending_reception: Bool?
        }

        let response: [GuestListDTO] = try await supabase
            .from("guest_list")
            .select(
                "id, first_name, last_name, guest_group_id, rsvp_status, dietary_restrictions, accessibility_needs, attending_reception")
            .eq("couple_id", value: tenantId)
            .eq("attending_reception", value: true)
            .execute()
            .value

        return response.map { dto in
            var guest = SeatingGuest(
                firstName: dto.first_name,
                lastName: dto.last_name,
                relationship: .friend // Default, could be enhanced based on data
            )

            // Set group if available
            guest.group = dto.guest_group_id

            // Parse dietary restrictions
            if let restrictions = dto.dietary_restrictions, !restrictions.isEmpty {
                guest.dietaryRestrictions = restrictions
            }

            // Set accessibility needs if available
            if let needs = dto.accessibility_needs, !needs.isEmpty {
                var accessibility = AccessibilityNeeds()
                accessibility.wheelchairAccessible = needs.lowercased().contains("wheelchair")
                accessibility.hearingImpaired = needs.lowercased().contains("hearing")
                accessibility.visuallyImpaired = needs.lowercased().contains("visual")
                accessibility.mobilityLimited = needs.lowercased().contains("mobility")
                accessibility.other = needs
                guest.accessibility = accessibility
            }

            return guest
        }
    }

    // MARK: - Batch Operations

    func syncAllData(for tenantId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        async let moodBoards = fetchMoodBoards(for: tenantId)
        async let colorPalettes = fetchColorPalettes(for: tenantId)
        async let seatingCharts = fetchSeatingCharts(for: tenantId)
        async let stylePreferences = fetchStylePreferences(for: tenantId)

        let (boards, palettes, charts, preferences) = try await (
            moodBoards,
            colorPalettes,
            seatingCharts,
            stylePreferences)

        // Update local stores
        NotificationCenter.default.post(name: .dataFullSync, object: [
            "moodBoards": boards,
            "colorPalettes": palettes,
            "seatingCharts": charts,
            "stylePreferences": preferences as Any
        ])

        lastSyncDate = Date()
    }

    func clearLocalCache() {
        // Clear any local caching if implemented
        lastSyncDate = nil
        syncErrors.removeAll()
    }
}

// MARK: - Error Handling

enum SupabaseError: Error, LocalizedError {
    case connectionFailed
    case invalidData
    case unauthorized
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            "Unable to connect to the server"
        case .invalidData:
            "Invalid data format"
        case .unauthorized:
            "You don't have permission to access this data"
        case .syncFailed(let message):
            "Sync failed: \(message)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let moodBoardUpdated = Notification.Name("moodBoardUpdated")
    static let moodBoardDeleted = Notification.Name("moodBoardDeleted")
    static let dataFullSync = Notification.Name("dataFullSync")
    static let syncError = Notification.Name("syncError")
}
