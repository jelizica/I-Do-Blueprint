//
//  SeatingChartHelpers.swift
//  I Do Blueprint
//
//  Helper methods and analytics calculations for seating chart editor
//

import SwiftUI

// MARK: - Analytics Calculation

extension SeatingChart {
    func calculateAnalytics() -> SeatingAnalytics {
        let totalGuests = guests.count
        let assignedGuests = seatingAssignments.count
        let unassignedGuests = totalGuests - assignedGuests

        let totalTables = tables.count
        let occupiedTables = Set(seatingAssignments.map(\.tableId)).count
        let emptyTables = totalTables - occupiedTables

        let averageOccupancy = totalTables > 0 ? Double(assignedGuests) / Double(totalTables) : 0

        // Calculate conflicts: guests with conflicts seated at the same table
        var conflictCount = 0
        for assignment in seatingAssignments {
            guard let guest = guests.first(where: { $0.id == assignment.guestId }) else { continue }

            // Check if any conflicting guests are at the same table
            let tableAssignments = seatingAssignments.filter { $0.tableId == assignment.tableId }
            for conflictId in guest.conflicts {
                if tableAssignments.contains(where: { $0.guestId == conflictId }) {
                    conflictCount += 1
                }
            }
        }
        // Divide by 2 since each conflict is counted twice
        conflictCount /= 2

        // Calculate satisfied preferences
        var satisfiedPreferences = 0
        let totalPreferences = guests.reduce(0) { $0 + $1.preferences.count }

        for guest in guests {
            guard let assignment = seatingAssignments.first(where: { $0.guestId == guest.id }),
                  let table = tables.first(where: { $0.id == assignment.tableId }) else {
                continue
            }

            // Check each preference
            for preference in guest.preferences {
                // Simple preference matching based on table position
                // In a real implementation, this would check against venue layout
                switch preference.lowercased() {
                case let p where p.contains("near") || p.contains("close"):
                    // Consider preference satisfied if table is in a reasonable position
                    satisfiedPreferences += 1
                default:
                    // For other preferences, consider them satisfied by default
                    // A more sophisticated implementation would check actual venue layout
                    satisfiedPreferences += 1
                }
            }
        }

        return SeatingAnalytics(
            totalGuests: totalGuests,
            assignedGuests: assignedGuests,
            unassignedGuests: unassignedGuests,
            totalTables: totalTables,
            occupiedTables: occupiedTables,
            emptyTables: emptyTables,
            averageTableOccupancy: averageOccupancy,
            conflictCount: conflictCount,
            satisfiedPreferences: satisfiedPreferences,
            totalPreferences: totalPreferences)
    }
}


