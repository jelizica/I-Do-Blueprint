//
//  NotesAPITests.swift
//  I Do BlueprintTests
//
//  Integration tests for NotesAPI
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class NotesAPITests: XCTestCase {
    var mockSupabase: MockNotesSupabaseClient!
    var api: NotesAPI!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSupabase = MockNotesSupabaseClient()
        api = NotesAPI(supabase: mockSupabase)
    }
    
    override func tearDown() async throws {
        mockSupabase = nil
        api = nil
        try await super.tearDown()
    }
    
    // MARK: - Fetch Notes Tests
    
    func test_fetchNotes_success() async throws {
        // Given
        let note1 = Note.makeTest(title: "Note 1", content: "Content 1")
        let note2 = Note.makeTest(title: "Note 2", content: "Content 2")
        mockSupabase.mockNotes = [note1, note2]
        
        // When
        let notes = try await api.fetchNotes()
        
        // Then
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].title, "Note 1")
        XCTAssertEqual(notes[1].title, "Note 2")
    }
    
    func test_fetchNotes_emptyData_returnsEmptyArray() async throws {
        // Given
        mockSupabase.mockNotes = []
        
        // When
        let notes = try await api.fetchNotes()
        
        // Then
        XCTAssertTrue(notes.isEmpty)
    }
    
    func test_fetchNoteById_success() async throws {
        // Given
        let noteId = UUID()
        let mockNote = Note.makeTest(id: noteId, title: "Test Note")
        mockSupabase.mockNote = mockNote
        
        // When
        let note = try await api.fetchNoteById(noteId)
        
        // Then
        XCTAssertEqual(note.id, noteId)
        XCTAssertEqual(note.title, "Test Note")
    }
    
    func test_fetchNotesByType_success() async throws {
        // Given
        let note1 = Note.makeTest(title: "Vendor Note", relatedType: .vendor)
        let note2 = Note.makeTest(title: "Another Vendor Note", relatedType: .vendor)
        mockSupabase.mockNotes = [note1, note2]
        
        // When
        let notes = try await api.fetchNotesByType(.vendor)
        
        // Then
        XCTAssertEqual(notes.count, 2)
        XCTAssertTrue(notes.allSatisfy { $0.relatedType == .vendor })
    }
    
    func test_fetchNotesByRelatedEntity_success() async throws {
        // Given
        let relatedId = "vendor-123"
        let note1 = Note.makeTest(
            title: "Note 1",
            relatedType: .vendor,
            relatedId: relatedId
        )
        let note2 = Note.makeTest(
            title: "Note 2",
            relatedType: .vendor,
            relatedId: relatedId
        )
        mockSupabase.mockNotes = [note1, note2]
        
        // When
        let notes = try await api.fetchNotesByRelatedEntity(type: .vendor, relatedId: relatedId)
        
        // Then
        XCTAssertEqual(notes.count, 2)
        XCTAssertTrue(notes.allSatisfy { $0.relatedType == .vendor && $0.relatedId == relatedId })
    }
    
    // MARK: - Create Note Tests
    
    func test_createNote_success() async throws {
        // Given
        let insertData = NoteInsertData(
            coupleId: UUID(),
            title: "New Note",
            content: "New content",
            relatedType: .vendor,
            relatedId: "vendor-123"
        )
        
        let mockNote = Note.makeTest(
            title: insertData.title,
            content: insertData.content,
            relatedType: insertData.relatedType,
            relatedId: insertData.relatedId
        )
        mockSupabase.mockNote = mockNote
        
        // When
        let note = try await api.createNote(insertData)
        
        // Then
        XCTAssertEqual(note.title, "New Note")
        XCTAssertEqual(note.content, "New content")
        XCTAssertEqual(note.relatedType, .vendor)
        XCTAssertEqual(note.relatedId, "vendor-123")
    }
    
    func test_createNote_withoutRelatedEntity_success() async throws {
        // Given
        let insertData = NoteInsertData(
            coupleId: UUID(),
            title: "General Note",
            content: "General content",
            relatedType: nil,
            relatedId: nil
        )
        
        let mockNote = Note.makeTest(
            title: insertData.title,
            content: insertData.content,
            relatedType: nil,
            relatedId: nil
        )
        mockSupabase.mockNote = mockNote
        
        // When
        let note = try await api.createNote(insertData)
        
        // Then
        XCTAssertEqual(note.title, "General Note")
        XCTAssertNil(note.relatedType)
        XCTAssertNil(note.relatedId)
    }
    
    // MARK: - Update Note Tests
    
    func test_updateNote_success() async throws {
        // Given
        let noteId = UUID()
        let updateData = NoteInsertData(
            coupleId: UUID(),
            title: "Updated Note",
            content: "Updated content",
            relatedType: .expense,
            relatedId: "expense-456"
        )
        
        let mockNote = Note.makeTest(
            id: noteId,
            title: updateData.title,
            content: updateData.content,
            relatedType: updateData.relatedType,
            relatedId: updateData.relatedId
        )
        mockSupabase.mockNote = mockNote
        
        // When
        let note = try await api.updateNote(noteId, data: updateData)
        
        // Then
        XCTAssertEqual(note.id, noteId)
        XCTAssertEqual(note.title, "Updated Note")
        XCTAssertEqual(note.content, "Updated content")
        XCTAssertEqual(note.relatedType, .expense)
    }
    
    func test_updateNote_changeRelatedEntity_success() async throws {
        // Given
        let noteId = UUID()
        let updateData = NoteInsertData(
            coupleId: UUID(),
            title: "Note",
            content: "Content",
            relatedType: .guest,
            relatedId: "guest-789"
        )
        
        let mockNote = Note.makeTest(
            id: noteId,
            title: updateData.title,
            content: updateData.content,
            relatedType: updateData.relatedType,
            relatedId: updateData.relatedId
        )
        mockSupabase.mockNote = mockNote
        
        // When
        let note = try await api.updateNote(noteId, data: updateData)
        
        // Then
        XCTAssertEqual(note.relatedType, .guest)
        XCTAssertEqual(note.relatedId, "guest-789")
    }
    
    // MARK: - Delete Note Tests
    
    func test_deleteNote_success() async throws {
        // Given
        let noteId = UUID()
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.deleteNote(noteId)
        // Should not throw
    }
    
    // MARK: - Search Notes Tests
    
    func test_searchNotes_success() async throws {
        // Given
        let query = "important"
        let note1 = Note.makeTest(title: "Important Note", content: "Content")
        let note2 = Note.makeTest(title: "Note", content: "Important content")
        mockSupabase.mockNotes = [note1, note2]
        
        // When
        let notes = try await api.searchNotes(query: query)
        
        // Then
        XCTAssertEqual(notes.count, 2)
        XCTAssertTrue(
            notes.allSatisfy { note in
                note.title?.lowercased().contains(query) == true ||
                note.content.lowercased().contains(query)
            }
        )
    }
    
    func test_searchNotes_noResults_returnsEmptyArray() async throws {
        // Given
        let query = "nonexistent"
        mockSupabase.mockNotes = []
        
        // When
        let notes = try await api.searchNotes(query: query)
        
        // Then
        XCTAssertTrue(notes.isEmpty)
    }
    
    func test_searchNotes_caseInsensitive_success() async throws {
        // Given
        let query = "IMPORTANT"
        let note = Note.makeTest(title: "important note", content: "content")
        mockSupabase.mockNotes = [note]
        
        // When
        let notes = try await api.searchNotes(query: query)
        
        // Then
        XCTAssertEqual(notes.count, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func test_fetchNotes_networkError_throwsError() async {
        // Given
        mockSupabase.shouldThrowError = true
        mockSupabase.errorToThrow = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When/Then
        do {
            _ = try await api.fetchNotes()
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_createNote_networkError_throwsError() async {
        // Given
        mockSupabase.shouldThrowError = true
        mockSupabase.errorToThrow = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let insertData = NoteInsertData(
            coupleId: UUID(),
            title: "Note",
            content: "Content",
            relatedType: nil,
            relatedId: nil
        )
        
        // When/Then
        do {
            _ = try await api.createNote(insertData)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_updateNote_networkError_throwsError() async {
        // Given
        mockSupabase.shouldThrowError = true
        mockSupabase.errorToThrow = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let updateData = NoteInsertData(
            coupleId: UUID(),
            title: "Note",
            content: "Content",
            relatedType: nil,
            relatedId: nil
        )
        
        // When/Then
        do {
            _ = try await api.updateNote(UUID(), data: updateData)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_deleteNote_networkError_throwsError() async {
        // Given
        mockSupabase.shouldThrowError = true
        mockSupabase.errorToThrow = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When/Then
        do {
            try await api.deleteNote(UUID())
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Mock Supabase Client for Notes

class MockNotesSupabaseClient {
    var shouldThrowError = false
    var errorToThrow: Error?
    var deleteSucceeds = true
    
    // Mock data
    var mockNotes: [Note] = []
    var mockNote: Note?
}

// MARK: - Note Test Helper

extension Note {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        title: String? = "Test Note",
        content: String = "Test content",
        relatedType: NoteRelatedType? = nil,
        relatedId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Note {
        Note(
            id: id,
            coupleId: coupleId,
            title: title,
            content: content,
            relatedType: relatedType,
            relatedId: relatedId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
