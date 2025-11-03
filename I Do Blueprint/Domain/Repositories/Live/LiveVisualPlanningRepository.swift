//
//  LiveVisualPlanningRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of visual planning repository
//

import Foundation
import Supabase

actor LiveVisualPlanningRepository: VisualPlanningRepositoryProtocol {
    private let client: SupabaseClient?
    private let logger = AppLogger.api

    init(client: SupabaseClient? = SupabaseManager.shared.client) {
        self.client = client
    }

    private func getClient() throws -> SupabaseClient {
        guard let client = client else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return client
    }

    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }

    // MARK: - Mood Boards

    func fetchMoodBoards() async throws -> [MoodBoard] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        return try await client
            .from("mood_boards")
            .select("*, elements:visual_elements(*)")
            .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchMoodBoard(id: UUID) async throws -> MoodBoard? {
        let client = try getClient()
        let boards: [MoodBoard] = try await client
            .from("mood_boards")
            .select("*, elements:visual_elements(*)")
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return boards.first
    }

    func createMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        do {
            let client = try getClient()
            let board: MoodBoard = try await client
                .from("mood_boards")
                .insert(moodBoard)
                .select()
                .single()
                .execute()
                .value

            logger.info("Created mood board: \(moodBoard.boardName)")
            return board
        } catch {
            logger.error("Failed to create mood board", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createMoodBoard",
                "repository": "LiveVisualPlanningRepository"
            ])
            throw VisualPlanningError.createFailed(underlying: error)
        }
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        do {
            let client = try getClient()
            let board: MoodBoard = try await client
                .from("mood_boards")
                .update(moodBoard)
                .eq("id", value: moodBoard.id)
                .select()
                .single()
                .execute()
                .value

            logger.info("Updated mood board: \(moodBoard.boardName)")
            return board
        } catch {
            logger.error("Failed to update mood board", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateMoodBoard",
                "repository": "LiveVisualPlanningRepository",
                "boardId": moodBoard.id.uuidString
            ])
            throw VisualPlanningError.updateFailed(underlying: error)
        }
    }

    func deleteMoodBoard(id: UUID) async throws {
        do {
            let client = try getClient()
            try await client
                .from("mood_boards")
                .delete()
                .eq("id", value: id)
                .execute()

            logger.info("Deleted mood board: \(id)")
        } catch {
            logger.error("Failed to delete mood board", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteMoodBoard",
                "repository": "LiveVisualPlanningRepository",
                "boardId": id.uuidString
            ])
            throw VisualPlanningError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Color Palettes

    func fetchColorPalettes() async throws -> [ColorPalette] {
        let client = try getClient()
        return try await client
            .from("color_palettes")
            .select()
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchColorPalette(id: UUID) async throws -> ColorPalette? {
        let client = try getClient()
        let palettes: [ColorPalette] = try await client
            .from("color_palettes")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return palettes.first
    }

    func createColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        do {
            let client = try getClient()
            let created: ColorPalette = try await client
                .from("color_palettes")
                .insert(palette)
                .select()
                .single()
                .execute()
                .value

            logger.info("Created color palette: \(palette.name)")
            return created
        } catch {
            logger.error("Failed to create color palette", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createColorPalette",
                "repository": "LiveVisualPlanningRepository"
            ])
            throw VisualPlanningError.createFailed(underlying: error)
        }
    }

    func updateColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        do {
            let client = try getClient()
            let updated: ColorPalette = try await client
                .from("color_palettes")
                .update(palette)
                .eq("id", value: palette.id)
                .select()
                .single()
                .execute()
                .value

            logger.info("Updated color palette: \(palette.name)")
            return updated
        } catch {
            logger.error("Failed to update color palette", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateColorPalette",
                "repository": "LiveVisualPlanningRepository",
                "paletteId": palette.id.uuidString
            ])
            throw VisualPlanningError.updateFailed(underlying: error)
        }
    }

    func deleteColorPalette(id: UUID) async throws {
        do {
            let client = try getClient()
            try await client
                .from("color_palettes")
                .delete()
                .eq("id", value: id)
                .execute()

            logger.info("Deleted color palette: \(id)")
        } catch {
            logger.error("Failed to delete color palette", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteColorPalette",
                "repository": "LiveVisualPlanningRepository",
                "paletteId": id.uuidString
            ])
            throw VisualPlanningError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Seating Charts

    func fetchSeatingCharts() async throws -> [SeatingChart] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        return try await client
            .from("seating_charts")
            .select()
            .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchSeatingChart(id: UUID) async throws -> SeatingChart? {
        let client = try getClient()
        let charts: [SeatingChart] = try await client
            .from("seating_charts")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return charts.first
    }

    func createSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        do {
            let client = try getClient()
            let created: SeatingChart = try await client
                .from("seating_charts")
                .insert(chart)
                .select()
                .single()
                .execute()
                .value

            logger.info("Created seating chart: \(chart.chartName)")
            return created
        } catch {
            logger.error("Failed to create seating chart", error: error)
            throw VisualPlanningError.createFailed(underlying: error)
        }
    }

    func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        let client = try getClient()
        // Save the base chart
        let updated: SeatingChart = try await client
            .from("seating_charts")
            .update(chart)
            .eq("id", value: chart.id)
            .select()
            .single()
            .execute()
            .value

        // Delete existing tables first to avoid duplicate key constraint
        try await client
            .from("seating_tables")
            .delete()
            .eq("seating_chart_id", value: chart.id)
            .execute()

        // Save tables to seating_tables
        for table in chart.tables {
            do {
                let tableData = TableDTO(from: table, chartId: chart.id, coupleId: chart.tenantId)
                try await client
                    .from("seating_tables")
                    .upsert(tableData)
                    .execute()
            } catch {
                logger.error("Error saving table \(table.tableNumber) for chart \(chart.id)", error: error)
                throw error
            }
        }

        // Delete existing assignments first to avoid conflicts
        try await client
            .from("seat_assignments")
            .delete()
            .eq("seating_chart_id", value: chart.id)
            .execute()

        // Save assignments to seat_assignments
        for assignment in chart.seatingAssignments {
            do {
                let assignmentData = SeatAssignmentDTO(from: assignment, coupleId: chart.tenantId)
                try await client
                    .from("seat_assignments")
                    .upsert(assignmentData)
                    .execute()
            } catch {
                logger.error("Error saving seat assignment for guest \(assignment.guestId)", error: error)
                throw error
            }
        }

        // Reload tables and assignments to return complete chart
        var completeChart = updated
        completeChart.tables = try await fetchTables(for: chart.id)
        completeChart.seatingAssignments = try await fetchSeatAssignments(for: chart.id)

        // Keep the guests from the original chart
        completeChart.guests = chart.guests

        // Log important mutation
        logger.info("Updated seating chart: \(chart.id) with \(chart.tables.count) tables and \(chart.seatingAssignments.count) assignments")

        return completeChart
    }

    func deleteSeatingChart(id: UUID) async throws {
        do {
            let client = try getClient()
            // Delete related data first (cascading delete via foreign keys should handle this, but being explicit)
            try await client
                .from("seat_assignments")
                .delete()
                .eq("table_id", value: id)
                .execute()

            try await client
                .from("seating_tables")
                .delete()
                .eq("seating_chart_id", value: id)
                .execute()

            try await client
                .from("seating_charts")
                .delete()
                .eq("id", value: id)
                .execute()

            logger.info("Deleted seating chart: \(id)")
        } catch {
            logger.error("Failed to delete seating chart", error: error)
            throw VisualPlanningError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Seating Chart Details (Tables, Assignments, Guests)

    func fetchSeatingGuests(for tenantId: String) async throws -> [SeatingGuest] {
        let client = try getClient()
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

        let response: [GuestListDTO] = try await client
            .from("guest_list")
            .select("id, first_name, last_name, guest_group_id, rsvp_status, dietary_restrictions, accessibility_needs, attending_reception")
            .eq("couple_id", value: tenantId)
            .eq("attending_reception", value: true)
            .execute()
            .value

        return response.compactMap { dto in
            guard let guestId = UUID(uuidString: dto.id) else { return nil }

            var guest = SeatingGuest(
                firstName: dto.first_name,
                lastName: dto.last_name,
                relationship: .friend
            )

            guest.group = dto.guest_group_id

            if let restrictions = dto.dietary_restrictions, !restrictions.isEmpty {
                guest.dietaryRestrictions = restrictions
            }

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

    func fetchTables(for chartId: UUID) async throws -> [Table] {
        let client = try getClient()
        let response: [TableDTO] = try await client
            .from("seating_tables")
            .select()
            .eq("seating_chart_id", value: chartId)
            .execute()
            .value

        return response.map { $0.toTable() }
    }

    func fetchSeatAssignments(for chartId: UUID) async throws -> [SeatingAssignment] {
        let client = try getClient()
        let response: [SeatAssignmentDTO] = try await client
            .from("seat_assignments")
            .select()
            .eq("seating_chart_id", value: chartId)
            .execute()
            .value

        return response.map { $0.toSeatingAssignment() }
    }
}
