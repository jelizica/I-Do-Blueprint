//
//  NotesStoreV2.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/1/25.
//

import Combine
import Dependencies
import Foundation
import SwiftUI

// MARK: - Notes Store V2

@MainActor
class NotesStoreV2: ObservableObject {
    @Dependency(\.notesRepository) var repository

    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: NotesError?

    // Filtering and search
    @Published var searchText = ""
    @Published var selectedType: NoteRelatedType?

    var filteredNotes: [Note] {
        var result = notes

        // Filter by type
        if let type = selectedType {
            result = result.filter { $0.relatedType == type }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.title?.localizedCaseInsensitiveContains(searchText) == true ||
                    $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    // MARK: - Load Notes

    func loadNotes() async {
        isLoading = true
        error = nil

        do {
            notes = try await repository.fetchNotes()
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func loadNoteById(_ id: UUID) async -> Note? {
        do {
            return try await repository.fetchNoteById(id)
        } catch {
            self.error = .fetchFailed(underlying: error)
            return nil
        }
    }

    func loadNotesByType(_ type: NoteRelatedType) async {
        isLoading = true
        error = nil

        do {
            notes = try await repository.fetchNotesByType(type)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func loadNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async {
        isLoading = true
        error = nil

        do {
            notes = try await repository.fetchNotesByRelatedEntity(type: type, relatedId: relatedId)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    // MARK: - Create Note (with optimistic update)

    func createNote(_ data: NoteInsertData) async {
        // Optimistic update: create temporary note with placeholder ID
        let tempId = UUID()
        let now = Date()
        let optimisticNote = Note(
            id: tempId,
            coupleId: data.coupleId,
            title: data.title,
            content: data.content,
            relatedType: data.relatedType,
            relatedId: data.relatedId,
            createdAt: now,
            updatedAt: now,
            relatedEntity: nil)

        notes.insert(optimisticNote, at: 0)

        do {
            let createdNote = try await repository.createNote(data)

            // Replace optimistic note with real one
            if let index = notes.firstIndex(where: { $0.id == tempId }) {
                notes[index] = createdNote
            }
        } catch {
            // Rollback optimistic update
            notes.removeAll { $0.id == tempId }
            self.error = .createFailed(underlying: error)
        }
    }

    // MARK: - Update Note (with optimistic update)

    func updateNote(_ note: Note, data: NoteInsertData) async {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }

        // Store original for rollback
        let originalNote = notes[index]

        // Optimistic update
        var updatedNote = note
        updatedNote.title = data.title
        updatedNote.content = data.content
        updatedNote.relatedType = data.relatedType
        updatedNote.relatedId = data.relatedId
        updatedNote.updatedAt = Date()

        notes[index] = updatedNote

        do {
            let serverNote = try await repository.updateNote(id: note.id, data: data)
            notes[index] = serverNote
        } catch {
            // Rollback on error
            notes[index] = originalNote
            self.error = .updateFailed(underlying: error)
        }
    }

    // MARK: - Delete Note (with optimistic update)

    func deleteNote(_ note: Note) async {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }

        // Store for rollback
        let deletedNote = notes[index]
        let deletedIndex = index

        // Optimistic delete
        notes.remove(at: index)

        do {
            try await repository.deleteNote(id: note.id)
        } catch {
            // Rollback on error
            notes.insert(deletedNote, at: deletedIndex)
            self.error = .deleteFailed(underlying: error)
        }
    }

    // MARK: - Search

    func searchNotes(query: String) async {
        guard !query.isEmpty else {
            await loadNotes()
            return
        }

        isLoading = true
        error = nil

        do {
            notes = try await repository.searchNotes(query: query)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    // MARK: - Filtering and Grouping (Client-side)

    func filterByType(_ type: NoteRelatedType?) -> [Note] {
        guard let type else { return notes }
        return notes.filter { $0.relatedType == type }
    }

    func filterUnlinked() -> [Note] {
        notes.filter { $0.relatedType == nil }
    }

    func groupedNotesByType() -> [NoteRelatedType: [Note]] {
        var grouped: [NoteRelatedType: [Note]] = [:]

        for note in notes {
            guard let type = note.relatedType else { continue }
            if grouped[type] == nil {
                grouped[type] = []
            }
            grouped[type]?.append(note)
        }

        return grouped
    }

    // MARK: - Sorting

    func sortedNotes(by option: NoteSortOption) -> [Note] {
        switch option {
        case .createdDesc:
            notes.sorted { $0.createdAt > $1.createdAt }
        case .createdAsc:
            notes.sorted { $0.createdAt < $1.createdAt }
        case .updatedDesc:
            notes.sorted { $0.updatedAt > $1.updatedAt }
        case .updatedAsc:
            notes.sorted { $0.updatedAt < $1.updatedAt }
        case .titleAsc:
            notes.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .titleDesc:
            notes.sorted { ($0.title ?? "") > ($1.title ?? "") }
        }
    }

    // MARK: - Convenience Methods for View Compatibility

    func load() async {
        await loadNotes()
    }

    func refresh() async {
        await loadNotes()
    }

    func applyFilters() {
        // No-op: filteredNotes is now a computed property
        // This method exists for API compatibility with old NotesViewModel
    }

    func ungroupedNotes() -> [Note] {
        filteredNotes.filter { $0.relatedType == nil }
    }

    func updateNote(_ id: UUID, data: NoteInsertData) async {
        // Find the note
        guard let note = notes.first(where: { $0.id == id }) else { return }

        // Use the existing updateNote method
        await updateNote(note, data: data)
    }

    func deleteNote(_ id: UUID) async {
        // Find the note
        guard let note = notes.first(where: { $0.id == id }) else { return }

        // Use the existing deleteNote method
        await deleteNote(note)
    }

    func searchNotes() async {
        // Use searchText property
        await searchNotes(query: searchText)
    }
}
