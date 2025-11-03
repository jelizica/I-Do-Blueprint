//
//  MoodBoardHelpers.swift
//  I Do Blueprint
//
//  Helper functions for mood board list view
//

import SwiftUI

// MARK: - Mood Board Helpers

extension MoodBoardListView {

    var filteredMoodBoards: [MoodBoard] {
        var boards = visualPlanningStore.moodBoards

        // Apply style filter
        if let styleFilter = selectedStyleFilter {
            boards = boards.filter { $0.styleCategory == styleFilter }
        }

        // Apply search filter
        if !searchText.isEmpty {
            boards = boards.filter { board in
                board.boardName.localizedCaseInsensitiveContains(searchText) ||
                    board.boardDescription?.localizedCaseInsensitiveContains(searchText) == true ||
                    board.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Apply sorting
        switch sortOption {
        case .dateCreated:
            return boards.sorted { $0.createdAt > $1.createdAt }
        case .dateModified:
            return boards.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return boards.sorted { $0.boardName < $1.boardName }
        case .style:
            return boards.sorted { $0.styleCategory.displayName < $1.styleCategory.displayName }
        }
    }

    var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)
        ]
    }
}
