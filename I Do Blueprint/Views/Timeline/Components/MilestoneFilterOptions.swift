//
//  MilestoneFilterOptions.swift
//  I Do Blueprint
//
//  Extracted from AllMilestonesView.swift as part of complexity reduction refactoring
//

import Foundation

/// Filter options for milestones
enum MilestoneFilter: String, CaseIterable {
    case all = "all"
    case upcoming = "upcoming"
    case past = "past"
    case completed = "completed"
    case incomplete = "incomplete"
    
    var displayName: String {
        switch self {
        case .all: "All"
        case .upcoming: "Upcoming"
        case .past: "Past"
        case .completed: "Completed"
        case .incomplete: "Incomplete"
        }
    }
}

/// Sort order options for milestones
enum MilestoneSortOrder: String, CaseIterable {
    case dateAscending = "dateAscending"
    case dateDescending = "dateDescending"
    case nameAscending = "nameAscending"
    case nameDescending = "nameDescending"
    
    var displayName: String {
        switch self {
        case .dateAscending: "Date (Earliest First)"
        case .dateDescending: "Date (Latest First)"
        case .nameAscending: "Name (A-Z)"
        case .nameDescending: "Name (Z-A)"
        }
    }
    
    var shortName: String {
        switch self {
        case .dateAscending: "Date ↑"
        case .dateDescending: "Date ↓"
        case .nameAscending: "Name ↑"
        case .nameDescending: "Name ↓"
        }
    }
}
