//
//  NotesRepositoryProtocol.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/1/25.
//

import Foundation

// MARK: - Notes Repository Protocol

protocol NotesRepositoryProtocol {
    // MARK: - Fetch Operations

    func fetchNotes() async throws -> [Note]
    func fetchNoteById(_ id: UUID) async throws -> Note
    func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note]
    func fetchNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async throws -> [Note]

    // MARK: - Create, Update, Delete

    func createNote(_ data: NoteInsertData) async throws -> Note
    func updateNote(id: UUID, data: NoteInsertData) async throws -> Note
    func deleteNote(id: UUID) async throws

    // MARK: - Search

    func searchNotes(query: String) async throws -> [Note]
}
