//
//  LiveNotesRepository.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/1/25.
//

import Foundation
import Supabase

// MARK: - Live Notes Repository

class LiveNotesRepository: NotesRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository

    init(supabase: SupabaseClient? = nil) {
        self.supabase = supabase
    }

    // Convenience initializer using SupabaseManager singleton
    init() {
        supabase = SupabaseManager.shared.client
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }
    
    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }

    // MARK: - Fetch Operations

    func fetchNotes() async throws -> [Note] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()

        do {
            let notes: [Note] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .select()
                    .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                    .order("updated_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(notes.count) notes in \(String(format: "%.2f", duration))s")

            return notes
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Notes fetch failed after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchNotes",
                "repository": "LiveNotesRepository"
            ])
            throw error
        }
    }

    func fetchNoteById(_ id: UUID) async throws -> Note {
        let client = try getClient()
        return try await client
            .from("notes")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note] {
        let client = try getClient()
        return try await client
            .from("notes")
            .select()
            .eq("related_type", value: type.rawValue)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async throws -> [Note] {
        let client = try getClient()
        return try await client
            .from("notes")
            .select()
            .eq("related_type", value: type.rawValue)
            .eq("related_id", value: relatedId)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Create, Update, Delete

    func createNote(_ data: NoteInsertData) async throws -> Note {
        do {
            let client = try getClient()
            let startTime = Date()

            struct NoteInsert: Encodable {
                let coupleId: String
                let title: String?
                let content: String
                let relatedType: String?
                let relatedId: String?

                enum CodingKeys: String, CodingKey {
                    case coupleId = "couple_id"
                    case title
                    case content
                    case relatedType = "related_type"
                    case relatedId = "related_id"
                }
            }

            let insertData = NoteInsert(
                coupleId: data.coupleId.uuidString,
                title: data.title,
                content: data.content,
                relatedType: data.relatedType?.rawValue,
                relatedId: data.relatedId)

            let note: Note = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created note: \(data.title ?? "Untitled")")

            return note
        } catch {
            logger.error("Failed to create note", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createNote",
                "repository": "LiveNotesRepository"
            ])
            throw NotesError.createFailed(underlying: error)
        }
    }

    func updateNote(id: UUID, data: NoteInsertData) async throws -> Note {
        do {
            let client = try getClient()
            let startTime = Date()
            
            struct NoteUpdate: Encodable {
                let title: String?
                let content: String
                let relatedType: String?
                let relatedId: String?

                enum CodingKeys: String, CodingKey {
                    case title
                    case content
                    case relatedType = "related_type"
                    case relatedId = "related_id"
                }
            }

            let updateData = NoteUpdate(
                title: data.title,
                content: data.content,
                relatedType: data.relatedType?.rawValue,
                relatedId: data.relatedId)

            let note: Note = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .update(updateData)
                    .eq("id", value: id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated note: \(data.title ?? "Untitled")")
            
            return note
        } catch {
            logger.error("Failed to update note", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateNote",
                "repository": "LiveNotesRepository",
                "noteId": id.uuidString
            ])
            throw NotesError.updateFailed(underlying: error)
        }
    }

    func deleteNote(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()
            
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted note: \(id)")
        } catch {
            logger.error("Failed to delete note", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteNote",
                "repository": "LiveNotesRepository",
                "noteId": id.uuidString
            ])
            throw NotesError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Search

    func searchNotes(query: String) async throws -> [Note] {
        let client = try getClient()
        return try await client
            .from("notes")
            .select()
            .or("title.ilike.%\(query)%,content.ilike.%\(query)%")
            .order("updated_at", ascending: false)
            .execute()
            .value
    }
}
