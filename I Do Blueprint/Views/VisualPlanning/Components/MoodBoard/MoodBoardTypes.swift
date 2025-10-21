//
//  MoodBoardTypes.swift
//  I Do Blueprint
//
//  Types and enums for mood board list view
//

import Foundation

// MARK: - View Mode

enum ViewMode {
    case grid
    case list
}

// MARK: - Mood Board Sort Option

enum MoodBoardSortOption: CaseIterable {
    case dateCreated
    case dateModified
    case name
    case style

    var displayName: String {
        switch self {
        case .dateCreated: "Date Created"
        case .dateModified: "Date Modified"
        case .name: "Name"
        case .style: "Style"
        }
    }
}
