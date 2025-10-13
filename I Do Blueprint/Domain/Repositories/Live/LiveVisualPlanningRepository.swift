//
//  LiveVisualPlanningRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of visual planning repository
//

import Foundation
import Supabase

actor LiveVisualPlanningRepository: VisualPlanningRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    private let logger = AppLogger.api

    // MARK: - Mood Boards

    func fetchMoodBoards() async throws -> [MoodBoard] {
        return try await client
            .from("mood_boards")
            .select("*, elements:visual_elements(*)")
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchMoodBoard(id: UUID) async throws -> MoodBoard? {
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
        return try await client
            .from("mood_boards")
            .insert(moodBoard)
            .select()
            .single()
            .execute()
            .value
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        return try await client
            .from("mood_boards")
            .update(moodBoard)
            .eq("id", value: moodBoard.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteMoodBoard(id: UUID) async throws {
        try await client
            .from("mood_boards")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Color Palettes

    func fetchColorPalettes() async throws -> [ColorPalette] {
        return try await client
            .from("color_palettes")
            .select()
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchColorPalette(id: UUID) async throws -> ColorPalette? {
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
        return try await client
            .from("color_palettes")
            .insert(palette)
            .select()
            .single()
            .execute()
            .value
    }

    func updateColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        return try await client
            .from("color_palettes")
            .update(palette)
            .eq("id", value: palette.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteColorPalette(id: UUID) async throws {
        try await client
            .from("color_palettes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Seating Charts

    func fetchSeatingCharts() async throws -> [SeatingChart] {
        return try await client
            .from("seating_charts")
            .select()
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchSeatingChart(id: UUID) async throws -> SeatingChart? {
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
        return try await client
            .from("seating_charts")
            .insert(chart)
            .select()
            .single()
            .execute()
            .value
    }

    func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        logger.debug("[REPO] updateSeatingChart called")
        logger.debug("[REPO] Chart ID: \(chart.id)")
        logger.debug("[REPO] Number of tables to save: \(chart.tables.count)")
        logger.debug("[REPO] Number of assignments to save: \(chart.seatingAssignments.count)")

        // Save the base chart
        logger.debug("[REPO] Saving base chart to seating_charts table...")
        let updated: SeatingChart = try await client
            .from("seating_charts")
            .update(chart)
            .eq("id", value: chart.id)
            .select()
            .single()
            .execute()
            .value
        logger.debug("[REPO] Base chart saved successfully")

        // Delete existing tables first to avoid duplicate key constraint
        logger.debug("[REPO] Deleting existing tables for chart...")
        try await client
            .from("seating_tables")
            .delete()
            .eq("seating_chart_id", value: chart.id)
            .execute()
        logger.debug("[REPO] Existing tables deleted")

        // Save tables to seating_tables
        logger.debug("[REPO] Saving \(chart.tables.count) tables to seating_tables...")
        for (index, table) in chart.tables.enumerated() {
            do {
                let tableData = TableDTO(from: table, chartId: chart.id, coupleId: chart.tenantId)
                logger.debug("[REPO] Saving table \(index + 1): ID=\(table.id), Number=\(table.tableNumber)")
                logger.debug("[REPO] TableDTO for table \(index + 1): id=\(tableData.id), couple_id=\(tableData.couple_id)")

                let response = try await client
                    .from("seating_tables")
                    .upsert(tableData)
                    .execute()

                logger.debug("[REPO] Table \(index + 1) saved successfully - Response status: \(response.response.statusCode)")
            } catch {
                logger.error("[REPO] ERROR saving table \(index + 1)", error: error)
                logger.error("[REPO] Error details: \(String(describing: error))")
                throw error
            }
        }
        logger.debug("[REPO] All tables saved successfully")

        // Delete existing assignments first to avoid conflicts
        logger.debug("[REPO] Deleting existing seat assignments for chart...")
        try await client
            .from("seat_assignments")
            .delete()
            .eq("seating_chart_id", value: chart.id)
            .execute()
        logger.debug("[REPO] Existing assignments deleted")

        // Save assignments to seat_assignments
        logger.debug("[REPO] Saving \(chart.seatingAssignments.count) assignments to seat_assignments...")
        for (index, assignment) in chart.seatingAssignments.enumerated() {
            do {
                let assignmentData = SeatAssignmentDTO(from: assignment, coupleId: chart.tenantId)
                logger.debug("[REPO] Saving assignment \(index + 1): Guest=\(assignment.guestId), Table=\(assignment.tableId)")
                try await client
                    .from("seat_assignments")
                    .upsert(assignmentData)
                    .execute()
                logger.debug("[REPO] Assignment \(index + 1) saved successfully")
            } catch {
                logger.error("[REPO] ERROR saving assignment \(index + 1)", error: error)
                throw error
            }
        }
        logger.debug("[REPO] All assignments saved successfully")

        // Reload tables and assignments to return complete chart
        logger.debug("[REPO] Reloading tables from database...")
        var completeChart = updated
        completeChart.tables = try await fetchTables(for: chart.id)
        logger.debug("[REPO] Loaded \(completeChart.tables.count) tables")

        logger.debug("[REPO] Reloading assignments from database...")
        completeChart.seatingAssignments = try await fetchSeatAssignments(for: chart.id)
        logger.debug("[REPO] Loaded \(completeChart.seatingAssignments.count) assignments")

        // Keep the guests from the original chart
        completeChart.guests = chart.guests

        logger.info("[REPO] updateSeatingChart completed successfully")
        return completeChart
    }

    func deleteSeatingChart(id: UUID) async throws {
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
    }

    // MARK: - Seating Chart Details (Tables, Assignments, Guests)

    func fetchSeatingGuests(for tenantId: String) async throws -> [SeatingGuest] {
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
        let response: [TableDTO] = try await client
            .from("seating_tables")
            .select()
            .eq("seating_chart_id", value: chartId)
            .execute()
            .value

        return response.map { $0.toTable() }
    }

    func fetchSeatAssignments(for chartId: UUID) async throws -> [SeatingAssignment] {
        let response: [SeatAssignmentDTO] = try await client
            .from("seat_assignments")
            .select()
            .eq("seating_chart_id", value: chartId)
            .execute()
            .value

        return response.map { $0.toSeatingAssignment() }
    }
}
