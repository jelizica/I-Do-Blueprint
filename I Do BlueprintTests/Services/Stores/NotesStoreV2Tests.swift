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
    var mockRepository: MockNotesRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockNotesRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadNotes_Success() async throws {
        // Given
        let testNotes = [
            Note.makeTest(id: UUID(), coupleId: coupleId, title: "Wedding Plan", content: "Initial plan"),
            Note.makeTest(id: UUID(), coupleId: coupleId, title: "Vendor Notes", content: "Vendors to contact")
        ]
        mockRepository.notes = testNotes

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.notes.count, 2)
        XCTAssertEqual(store.notes[0].title, "Wedding Plan")
    }

    func testLoadNotes_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.notes.count, 0)
    }

    func testLoadNotes_Empty() async throws {
        // Given
        mockRepository.notes = []

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.notes.count, 0)
    }

    // MARK: - Create Tests

    func testCreateNote_OptimisticUpdate() async throws {
        // Given
        let existingNote = Note.makeTest(coupleId: coupleId, title: "Existing Note")
        mockRepository.notes = [existingNote]

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        let insertData = NoteInsertData(
            coupleId: coupleId,
            title: "New Note",
            content: "New content",
            relatedType: nil,
            relatedId: nil
        )
        await store.createNote(insertData)

        // Then
        XCTAssertEqual(store.notes.count, 2)
        XCTAssertTrue(store.notes.contains(where: { $0.title == "New Note" }))
    }

    func testCreateNote_Failure_RollsBack() async throws {
        // Given
        let existingNote = Note.makeTest(coupleId: coupleId, title: "Existing Note")
        mockRepository.notes = [existingNote]

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        mockRepository.shouldThrowError = true

        let insertData = NoteInsertData(
            coupleId: coupleId,
            title: "New Note",
            content: "New content",
            relatedType: nil,
            relatedId: nil
        )
        await store.createNote(insertData)

        // Then - Should rollback on error
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes.first?.title, "Existing Note")
    }

    // MARK: - Update Tests

    func testUpdateNote_Success() async throws {
        // Given
        let note = Note.makeTest(id: UUID(), coupleId: coupleId, title: "Original Title", content: "Original content")
        mockRepository.notes = [note]

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        let updateData = NoteInsertData(
            coupleId: coupleId,
            title: "Updated Title",
            content: "Updated content",
            relatedType: nil,
            relatedId: nil
        )
        await store.updateNote(note, data: updateData)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.notes.first?.title, "Updated Title")
        XCTAssertEqual(store.notes.first?.content, "Updated content")
    }

    func testUpdateNote_Failure_RollsBack() async throws {
        // Given
        let note = Note.makeTest(id: UUID(), coupleId: coupleId, title: "Original Title", content: "Original content")
        mockRepository.notes = [note]

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        mockRepository.shouldThrowError = true

        let updateData = NoteInsertData(
            coupleId: coupleId,
            title: "Updated Title",
            content: "Updated content",
            relatedType: nil,
            relatedId: nil
        )
        await store.updateNote(note, data: updateData)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.notes.first?.title, "Original Title")
        XCTAssertEqual(store.notes.first?.content, "Original content")
    }

    // MARK: - Delete Tests

    func testDeleteNote_Success() async throws {
        // Given
        let note1 = Note.makeTest(id: UUID(), coupleId: coupleId, title: "Note 1")
        let note2 = Note.makeTest(id: UUID(), coupleId: coupleId, title: "Note 2")
        mockRepository.notes = [note1, note2]

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()
        await store.deleteNote(note1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes.first?.title, "Note 2")
    }

    func testDeleteNote_Failure_RollsBack() async throws {
        // Given
        let note = Note.makeTest(id: UUID(), coupleId: coupleId, title: "Note 1")
        mockRepository.notes = [note]

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        mockRepository.shouldThrowError = true
        await store.deleteNote(note)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes.first?.id, note.id)
    }

    // MARK: - Filter Tests

    func testFilterByRelatedType() async throws {
        // Given
        let notes = [
            Note.makeTest(coupleId: coupleId, title: "Vendor Note", relatedType: NoteRelatedType.vendor),
            Note.makeTest(coupleId: coupleId, title: "Task Note", relatedType: NoteRelatedType.task),
            Note.makeTest(coupleId: coupleId, title: "Another Vendor Note", relatedType: NoteRelatedType.vendor)
        ]
        mockRepository.notes = notes

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()
        store.selectedType = NoteRelatedType.vendor
        let filtered = store.filteredNotes

        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.relatedType == .vendor })
    }

    func testFilterByRelatedId() async throws {
        // Given
        let relatedId = "test-vendor-123"
        let notes = [
            Note.makeTest(coupleId: coupleId, relatedType: NoteRelatedType.vendor, relatedId: relatedId),
            Note.makeTest(coupleId: coupleId, relatedType: NoteRelatedType.vendor, relatedId: "other-vendor"),
            Note.makeTest(coupleId: coupleId, relatedType: NoteRelatedType.vendor, relatedId: relatedId)
        ]
        mockRepository.notes = notes

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()
        let filtered = store.notes.filter { $0.relatedId == relatedId }

        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.relatedId == relatedId })
    }

    // MARK: - Search Tests

    func testSearchNotes() async throws {
        // Given
        let notes = [
            Note.makeTest(coupleId: coupleId, title: "Wedding Plan", content: "Initial planning notes"),
            Note.makeTest(coupleId: coupleId, title: "Vendor List", content: "List of vendors"),
            Note.makeTest(coupleId: coupleId, title: "Budget Notes", content: "Wedding budget tracking")
        ]
        mockRepository.notes = notes

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()
        store.searchText = "wedding"
        let filtered = store.filteredNotes

        // Then
        XCTAssertEqual(filtered.count, 2) // Wedding Plan and Budget Notes
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_TotalNotes() async throws {
        // Given
        let notes = [
            Note.makeTest(coupleId: coupleId),
            Note.makeTest(coupleId: coupleId),
            Note.makeTest(coupleId: coupleId)
        ]
        mockRepository.notes = notes

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()

        // Then
        XCTAssertEqual(store.notes.count, 3)
    }

    func testComputedProperty_NotesByType() async throws {
        // Given
        let notes = [
            Note.makeTest(coupleId: coupleId, relatedType: NoteRelatedType.vendor),
            Note.makeTest(coupleId: coupleId, relatedType: NoteRelatedType.task),
            Note.makeTest(coupleId: coupleId, relatedType: NoteRelatedType.vendor)
        ]
        mockRepository.notes = notes

        // When
        let store = await withDependencies {
            $0.notesRepository = mockRepository
        } operation: {
            NotesStoreV2()
        }

        await store.loadNotes()
        let grouped = store.groupedNotesByType()

        // Then
        XCTAssertEqual(grouped[.vendor]?.count, 2)
        XCTAssertEqual(grouped[.task]?.count, 1)
    }
}
