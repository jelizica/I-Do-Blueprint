//
//  MoodBoardHistoryManager.swift
//  My Wedding Planning App
//
//  Undo/redo history management for mood board editing
//

import Foundation

@Observable
class MoodBoardHistoryManager {
    private var history: [MoodBoard] = []
    private var currentIndex: Int = -1
    private let maxHistorySize = 50

    var canUndo: Bool {
        currentIndex > 0
    }

    var canRedo: Bool {
        currentIndex < history.count - 1
    }

    func addSnapshot(_ moodBoard: MoodBoard) {
        // Remove any redo history when adding a new snapshot
        if currentIndex < history.count - 1 {
            history.removeSubrange((currentIndex + 1)...)
        }

        // Add the new snapshot
        history.append(moodBoard)
        currentIndex = history.count - 1

        // Limit history size
        if history.count > maxHistorySize {
            history.removeFirst()
            currentIndex -= 1
        }
    }

    func undo() -> MoodBoard? {
        guard canUndo else { return nil }
        currentIndex -= 1
        return history[currentIndex]
    }

    func redo() -> MoodBoard? {
        guard canRedo else { return nil }
        currentIndex += 1
        return history[currentIndex]
    }

    func clear() {
        history.removeAll()
        currentIndex = -1
    }

    func getCurrentSnapshot() -> MoodBoard? {
        guard currentIndex >= 0, currentIndex < history.count else { return nil }
        return history[currentIndex]
    }

    var historyCount: Int {
        history.count
    }

    var currentPosition: Int {
        currentIndex + 1
    }
}
