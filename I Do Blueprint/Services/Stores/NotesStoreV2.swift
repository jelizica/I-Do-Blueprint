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

    @Published var loadingState: LoadingState<[Note]> = .idle

    // Filtering and search
    @Published var searchText = ""
    @Published var selectedType: NoteRelatedType?
    
    // MARK: - Computed Properties for Backward Compatibility
    
    var notes: [Note] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var error: NotesError? {
        if case .error(let err) = loadingState {
            return err as? NotesError ?? .fetchFailed(underlying: err)
        }
        return nil
    }

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
        guard loadingState.isIdle || loadingState.hasError else { return }
        
        loadingState = .loading

        do {
            let fetchedNotes = try await repository.fetchNotes()
            loadingState = .loaded(fetchedNotes)
        } catch {
            loadingState = .error(NotesError.fetchFailed(underlying: error))
        }
    }

    func loadNoteById(_ id: UUID) async -> Note? {
        do {
            return try await repository.fetchNoteById(id)
        } catch {
            loadingState = .error(NotesError.fetchFailed(underlying: error))
            return nil
        }
    }

    func loadNotesByType(_ type: NoteRelatedType) async {
        loadingState = .loading

        do {
            let fetchedNotes = try await repository.fetchNotesByType(type)
            loadingState = .loaded(fetchedNotes)
        } catch {
            loadingState = .error(NotesError.fetchFailed(underlying: error))
        }
    }

    func loadNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async {
        loadingState = .loading

        do {
            let fetchedNotes = try await repository.fetchNotesByRelatedEntity(type: type, relatedId: relatedId)
            loadingState = .loaded(fetchedNotes)
        } catch {
            loadingState = .error(NotesError.fetchFailed(underlying: error))
        }
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

        if case .loaded(var currentNotes) = loadingState {
            currentNotes.insert(optimisticNote, at: 0)
            loadingState = .loaded(currentNotes)
        }

        do {
            let createdNote = try await repository.createNote(data)

            // Replace optimistic note with real one
            if case .loaded(var notes) = loadingState,
               let index = notes.firstIndex(where: { $0.id == tempId }) {
                notes[index] = createdNote
                loadingState = .loaded(notes)
            }
            
            showSuccess("Note created successfully")
        } catch {
            // Rollback optimistic update
            if case .loaded(var notes) = loadingState {
                notes.removeAll { $0.id == tempId }
                loadingState = .loaded(notes)
            }
            loadingState = .error(NotesError.createFailed(underlying: error))
            await handleError(error, operation: "create note") { [weak self] in
                await self?.createNote(data)
            }
        }
    }

    // MARK: - Update Note (with optimistic update)

    func updateNote(_ note: Note, data: NoteInsertData) async {
        guard case .loaded(var currentNotes) = loadingState,
              let index = currentNotes.firstIndex(where: { $0.id == note.id }) else {
            return
        }

        // Store original for rollback
        let originalNote = currentNotes[index]

        // Optimistic update
        var updatedNote = note
        updatedNote.title = data.title
        updatedNote.content = data.content
        updatedNote.relatedType = data.relatedType
        updatedNote.relatedId = data.relatedId
        updatedNote.updatedAt = Date()

        currentNotes[index] = updatedNote
        loadingState = .loaded(currentNotes)

        do {
            let serverNote = try await repository.updateNote(id: note.id, data: data)
            
            if case .loaded(var notes) = loadingState,
               let idx = notes.firstIndex(where: { $0.id == note.id }) {
                notes[idx] = serverNote
                loadingState = .loaded(notes)
            }
            
            showSuccess("Note updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var notes) = loadingState,
               let idx = notes.firstIndex(where: { $0.id == note.id }) {
                notes[idx] = originalNote
                loadingState = .loaded(notes)
            }
            loadingState = .error(NotesError.updateFailed(underlying: error))
            await handleError(error, operation: "update note") { [weak self] in
                await self?.updateNote(note, data: data)
            }
        }
    }

    // MARK: - Delete Note (with optimistic update)

    func deleteNote(_ note: Note) async {
        guard case .loaded(var currentNotes) = loadingState,
              let index = currentNotes.firstIndex(where: { $0.id == note.id }) else {
            return
        }

        // Store for rollback
        let deletedNote = currentNotes[index]
        let deletedIndex = index

        // Optimistic delete
        currentNotes.remove(at: index)
        loadingState = .loaded(currentNotes)

        do {
            try await repository.deleteNote(id: note.id)
            showSuccess("Note deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var notes) = loadingState {
                notes.insert(deletedNote, at: deletedIndex)
                loadingState = .loaded(notes)
            }
            loadingState = .error(NotesError.deleteFailed(underlying: error))
            await handleError(error, operation: "delete note") { [weak self] in
                await self?.deleteNote(note)
            }
        }
    }

    // MARK: - Search

    func searchNotes(query: String) async {
        guard !query.isEmpty else {
            await loadNotes()
            return
        }

        loadingState = .loading

        do {
            let fetchedNotes = try await repository.searchNotes(query: query)
            loadingState = .loaded(fetchedNotes)
        } catch {
            loadingState = .error(NotesError.fetchFailed(underlying: error))
        }
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
    
    // MARK: - Retry Helper
    
    func retryLoad() async {
        await loadNotes()
    }
}
