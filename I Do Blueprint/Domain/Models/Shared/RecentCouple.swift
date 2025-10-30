//
//  RecentCouple.swift
//  I Do Blueprint
//
//  Model for tracking recently viewed couples/weddings
//  Phase 3.2: Recently Viewed Couples
//

import Foundation

/// Represents a recently accessed couple/wedding for quick access
struct RecentCouple: Codable, Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let weddingDate: Date?
    let lastAccessedAt: Date
    
    /// Creates a new recent couple entry
    init(id: UUID, displayName: String, weddingDate: Date?, lastAccessedAt: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.weddingDate = weddingDate
        self.lastAccessedAt = lastAccessedAt
    }
    
    /// Formatted wedding date string for display
    var formattedWeddingDate: String? {
        guard let weddingDate = weddingDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: weddingDate)
    }
    
    /// Relative time since last access (e.g., "2 hours ago")
    var relativeAccessTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastAccessedAt, relativeTo: Date())
    }
}

// MARK: - Test Helpers

extension RecentCouple {
    /// Creates a test recent couple
    static func makeTest(
        id: UUID = UUID(),
        displayName: String = "Test Couple",
        weddingDate: Date? = Date().addingTimeInterval(365 * 24 * 60 * 60),
        lastAccessedAt: Date = Date()
    ) -> RecentCouple {
        RecentCouple(
            id: id,
            displayName: displayName,
            weddingDate: weddingDate,
            lastAccessedAt: lastAccessedAt
        )
    }
}
