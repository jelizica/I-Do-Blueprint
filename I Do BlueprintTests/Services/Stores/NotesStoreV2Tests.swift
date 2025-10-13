//
//  NotesStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for NotesStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class NotesStoreV2Tests: XCTestCase {
    var store: NotesStoreV2!
    var mockRepository: MockNotesRepository!

    override func setUp() async throws {
        mockRepository = MockNotesRepository()
        store = withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Notes Tests

    func testLoadNotes_Success() async throws {
        // Given
        let mockNotes = [
            createMockNote(title: "Vendor Notes", type: .vendor),
            createMockNote(title: "Guest Notes", type: .guest),
        ]
        mockRepository.notes = mockNotes

        // When
        await store.loadNotes()

        // Then
        XCTAssertEqual(store.notes.count, 2)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadNotes_EmptyResult() async throws {
        // Given
        mockRepository.notes = []

        // When
        await store.loadNotes()

        // Then
        XCTAssertTrue(store.notes.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadNotes_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadNotes()

        // Then
        XCTAssertTrue(store.notes.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Note Tests

    func testCreateNote_Success() async throws {
        // Given
        let insertData = NoteInsertData(
            coupleId: UUID(),
            title: "New Note",
            content: "Content",
            relatedType: .vendor,
            relatedId: "123"
        )
        let newNote = createMockNote(title: "New Note")
        mockRepository.createdNote = newNote

        // When
        await store.createNote(insertData)

        // Then
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes[0].title, "New Note")
        XCTAssertNil(store.error)
    }

    func testCreateNote_OptimisticUpdateAndRollback() async throws {
        // Given
        let insertData = NoteInsertData(
            coupleId: UUID(),
            title: "New Note",
            content: "Content",
            relatedType: nil,
            relatedId: nil
        )
        mockRepository.shouldThrowError = true

        // When
        await store.createNote(insertData)

        // Then - should rollback
        XCTAssertTrue(store.notes.isEmpty)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Update Note Tests

    func testUpdateNote_Success() async throws {
        // Given
        let originalNote = createMockNote(title: "Original")
        store.notes = [originalNote]

        let updateData = NoteInsertData(
            coupleId: originalNote.coupleId,
            title: "Updated",
            content: "Updated Content",
            relatedType: .vendor,
            relatedId: "456"
        )

        var updatedNote = originalNote
        updatedNote.title = "Updated"
        mockRepository.updatedNote = updatedNote

        // When
        await store.updateNote(originalNote, data: updateData)

        // Then
        XCTAssertEqual(store.notes[0].title, "Updated")
        XCTAssertNil(store.error)
    }

    func testUpdateNote_RollbackOnError() async throws {
        // Given
        let originalNote = createMockNote(title: "Original")
        store.notes = [originalNote]

        let updateData = NoteInsertData(
            coupleId: originalNote.coupleId,
            title: "Updated",
            content: "Content",
            relatedType: nil,
            relatedId: nil
        )
        mockRepository.shouldThrowError = true

        // When
        await store.updateNote(originalNote, data: updateData)

        // Then
        XCTAssertEqual(store.notes[0].title, "Original")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Note Tests

    func testDeleteNote_Success() async throws {
        // Given
        let note = createMockNote(title: "To Delete")
        store.notes = [note]

        // When
        await store.deleteNote(note)

        // Then
        XCTAssertTrue(store.notes.isEmpty)
        XCTAssertNil(store.error)
    }

    func testDeleteNote_RollbackOnError() async throws {
        // Given
        let note = createMockNote(title: "To Delete")
        store.notes = [note]
        mockRepository.shouldThrowError = true

        // When
        await store.deleteNote(note)

        // Then
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Filtering Tests

    func testFilteredNotes_ByType() {
        // Given
        store.notes = [
            createMockNote(title: "Vendor", type: .vendor),
            createMockNote(title: "Guest", type: .guest),
            createMockNote(title: "Task", type: .task),
        ]
        store.selectedType = .vendor

        // When
        let filtered = store.filteredNotes

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].relatedType, .vendor)
    }

    func testFilteredNotes_BySearchText() {
        // Given
        store.notes = [
            createMockNote(title: "Vendor Meeting", type: .vendor),
            createMockNote(title: "Guest List", type: .guest),
        ]
        store.searchText = "vendor"

        // When
        let filtered = store.filteredNotes

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Vendor Meeting")
    }

    func testFilteredNotes_BySearchInContent() {
        // Given
        store.notes = [
            createMockNote(title: "Note 1", content: "Important details", type: .vendor),
            createMockNote(title: "Note 2", content: "Other info", type: .guest),
        ]
        store.searchText = "important"

        // When
        let filtered = store.filteredNotes

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Note 1")
    }

    // MARK: - Grouping Tests

    func testGroupedNotesByType() {
        // Given
        store.notes = [
            createMockNote(title: "V1", type: .vendor),
            createMockNote(title: "V2", type: .vendor),
            createMockNote(title: "G1", type: .guest),
        ]

        // When
        let grouped = store.groupedNotesByType()

        // Then
        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[.vendor]?.count, 2)
        XCTAssertEqual(grouped[.guest]?.count, 1)
    }

    func testFilterUnlinked() {
        // Given
        store.notes = [
            createMockNote(title: "Linked", type: .vendor),
            createMockNote(title: "Unlinked", type: nil),
        ]

        // When
        let unlinked = store.filterUnlinked()

        // Then
        XCTAssertEqual(unlinked.count, 1)
        XCTAssertEqual(unlinked[0].title, "Unlinked")
    }

    // MARK: - Search Tests

    func testSearchNotes_WithQuery() async throws {
        // Given
        let mockNotes = [
            createMockNote(title: "Found", type: .vendor),
        ]
        mockRepository.searchResults = mockNotes

        // When
        await store.searchNotes(query: "found")

        // Then
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes[0].title, "Found")
        XCTAssertFalse(store.isLoading)
    }

    func testSearchNotes_EmptyQuery_LoadsAll() async throws {
        // Given
        mockRepository.notes = [
            createMockNote(title: "Note 1"),
            createMockNote(title: "Note 2"),
        ]

        // When
        await store.searchNotes(query: "")

        // Then
        XCTAssertEqual(store.notes.count, 2)
    }

    // MARK: - Helper Methods

    private func createMockNote(
        title: String?,
        content: String = "Content",
        type: NoteRelatedType? = nil
    ) -> Note {
        Note(
            id: UUID(),
            coupleId: UUID(),
            title: title,
            content: content,
            relatedType: type,
            relatedId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            relatedEntity: nil
        )
    }
}

// MARK: - Mock Repository

class MockNotesRepository: NotesRepositoryProtocol {
    var notes: [Note] = []
    var createdNote: Note?
    var updatedNote: Note?
    var searchResults: [Note] = []
    var shouldThrowError = false

    func fetchNotes() async throws -> [Note] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return notes
    }

    func fetchNoteById(_ id: UUID) async throws -> Note {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        guard let note = notes.first(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: -1)
        }
        return note
    }

    func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return notes.filter { $0.relatedType == type }
    }

    func fetchNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async throws -> [Note] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return notes.filter { $0.relatedType == type && $0.relatedId == relatedId }
    }

    func createNote(_ data: NoteInsertData) async throws -> Note {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return createdNote ?? Note(
            id: UUID(),
            coupleId: data.coupleId,
            title: data.title,
            content: data.content,
            relatedType: data.relatedType,
            relatedId: data.relatedId,
            createdAt: Date(),
            updatedAt: Date(),
            relatedEntity: nil
        )
    }

    func updateNote(id: UUID, data: NoteInsertData) async throws -> Note {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        guard let note = notes.first(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: -1)
        }
        return updatedNote ?? Note(
            id: note.id,
            coupleId: data.coupleId,
            title: data.title,
            content: data.content,
            relatedType: data.relatedType,
            relatedId: data.relatedId,
            createdAt: note.createdAt,
            updatedAt: Date(),
            relatedEntity: nil
        )
    }

    func deleteNote(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func searchNotes(query: String) async throws -> [Note] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return searchResults
    }

    func invalidateCache() async {
        // No-op for mock
    }
}
