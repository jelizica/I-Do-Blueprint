//
//  MockNotesRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of NotesRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockNotesRepository: NotesRepositoryProtocol {
    var notes: [Note] = []
    var shouldThrowError = false
    var errorToThrow: NotesError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchNotes() async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes
    }

    func fetchNoteById(_ id: UUID) async throws -> Note {
        if shouldThrowError { throw errorToThrow }
        guard let note = notes.first(where: { $0.id == id }) else {
            throw NotesError.notFound(id: id)
        }
        return note
    }

    func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes.filter { $0.relatedType == type }
    }

    func fetchNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes.filter { $0.relatedType == type && $0.relatedId == relatedId }
    }

    func createNote(_ data: NoteInsertData) async throws -> Note {
        if shouldThrowError { throw errorToThrow }
        let note = Note.makeTest(content: data.content, relatedType: data.relatedType)
        notes.append(note)
        return note
    }

    func updateNote(id: UUID, data: NoteInsertData) async throws -> Note {
        if shouldThrowError { throw errorToThrow }
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw NotesError.notFound(id: id)
        }
        var note = notes[index]
        note.content = data.content
        notes[index] = note
        return note
    }

    func deleteNote(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        notes.removeAll(where: { $0.id == id })
    }

    func searchNotes(query: String) async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }
}
