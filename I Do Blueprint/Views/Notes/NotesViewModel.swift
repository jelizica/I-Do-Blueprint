//
//  NotesViewModel.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var filteredNotes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedType: NoteRelatedType?

    private let notesAPI = NotesAPI()

    // MARK: - Load Data

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            notes = try await notesAPI.fetchNotes()
            applyFilters()
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refresh() async {
        await load()
    }

    // MARK: - Filtering and Search

    func applyFilters() {
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

        filteredNotes = result
    }

    func clearFilters() {
        searchText = ""
        selectedType = nil
        applyFilters()
    }

    // MARK: - Grouping

    func groupedNotesByType() -> [NoteRelatedType: [Note]] {
        var grouped: [NoteRelatedType: [Note]] = [:]

        for note in filteredNotes {
            guard let type = note.relatedType else { continue }
            if grouped[type] == nil {
                grouped[type] = []
            }
            grouped[type]?.append(note)
        }

        return grouped
    }

    func ungroupedNotes() -> [Note] {
        filteredNotes.filter { $0.relatedType == nil }
    }

    // MARK: - CRUD Operations

    func createNote(_ data: NoteInsertData) async {
        do {
            let newNote = try await notesAPI.createNote(data)
            notes.insert(newNote, at: 0) // Add to beginning
            applyFilters()
        } catch {
            errorMessage = "Failed to create note: \(error.localizedDescription)"
        }
    }

    func updateNote(_ id: UUID, data: NoteInsertData) async {
        do {
            let updatedNote = try await notesAPI.updateNote(id, data: data)
            if let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index] = updatedNote
            }
            applyFilters()
        } catch {
            errorMessage = "Failed to update note: \(error.localizedDescription)"
        }
    }

    func deleteNote(_ id: UUID) async {
        do {
            try await notesAPI.deleteNote(id)
            notes.removeAll { $0.id == id }
            applyFilters()
        } catch {
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
        }
    }

    func searchNotes() async {
        guard !searchText.isEmpty else {
            applyFilters()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let results = try await notesAPI.searchNotes(query: searchText)
            notes = results
            applyFilters()
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
