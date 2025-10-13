//
//  MockNotesRepository.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/1/25.
//

import Foundation

// MARK: - Mock Notes Repository

class MockNotesRepository: NotesRepositoryProtocol {
    var notes: [Note] = []
    var shouldThrowError = false
    var errorToThrow: Error = MockNotesRepositoryError.operationFailed

    // MARK: - Fetch Operations

    func fetchNotes() async throws -> [Note] {
        if shouldThrowError {
            throw errorToThrow
        }
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchNoteById(_ id: UUID) async throws -> Note {
        if shouldThrowError {
            throw errorToThrow
        }
        guard let note = notes.first(where: { $0.id == id }) else {
            throw MockNotesRepositoryError.noteNotFound
        }
        return note
    }

    func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note] {
        if shouldThrowError {
            throw errorToThrow
        }
        return notes
            .filter { $0.relatedType == type }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async throws -> [Note] {
        if shouldThrowError {
            throw errorToThrow
        }
        return notes
            .filter { $0.relatedType == type && $0.relatedId == relatedId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Create, Update, Delete

    func createNote(_ data: NoteInsertData) async throws -> Note {
        if shouldThrowError {
            throw errorToThrow
        }

        let now = Date()
        let newNote = Note(
            id: UUID(),
            coupleId: data.coupleId,
            title: data.title,
            content: data.content,
            relatedType: data.relatedType,
            relatedId: data.relatedId,
            createdAt: now,
            updatedAt: now,
            relatedEntity: nil)
        notes.append(newNote)
        return newNote
    }

    func updateNote(id: UUID, data: NoteInsertData) async throws -> Note {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw MockNotesRepositoryError.noteNotFound
        }

        var updatedNote = notes[index]
        updatedNote.title = data.title
        updatedNote.content = data.content
        updatedNote.relatedType = data.relatedType
        updatedNote.relatedId = data.relatedId
        updatedNote.updatedAt = Date()

        notes[index] = updatedNote
        return updatedNote
    }

    func deleteNote(id: UUID) async throws {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw MockNotesRepositoryError.noteNotFound
        }

        notes.remove(at: index)
    }

    // MARK: - Search

    func searchNotes(query: String) async throws -> [Note] {
        if shouldThrowError {
            throw errorToThrow
        }

        let lowercaseQuery = query.lowercased()
        return notes
            .filter {
                $0.title?.lowercased().contains(lowercaseQuery) == true ||
                    $0.content.lowercased().contains(lowercaseQuery)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Mock Errors

enum MockNotesRepositoryError: Error, LocalizedError {
    case operationFailed
    case noteNotFound

    var errorDescription: String? {
        switch self {
        case .operationFailed:
            "Mock operation failed"
        case .noteNotFound:
            "Note not found"
        }
    }
}
