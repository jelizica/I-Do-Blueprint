//
//  NotesAPI.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation
import Supabase

class NotesAPI {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.api

    init(supabase: SupabaseClient? = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    // MARK: - Fetch Notes

    func fetchNotes() async throws -> [Note] {
        let client = try getClient()
        let startTime = Date()

        do {
            let response: [Note] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .select()
                    .order("updated_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) notes in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchNotes", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Notes fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchNotes", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchNoteById(_ id: UUID) async throws -> Note {
        let client = try getClient()
        let startTime = Date()

        do {
            let response: Note = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .select()
                    .eq("id", value: id.uuidString)
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.debug("Fetched note by ID in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchNoteById", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Note fetch by ID failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchNoteById", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note] {
        let client = try getClient()
        let startTime = Date()

        do {
            let response: [Note] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .select()
                    .eq("related_type", value: type.rawValue)
                    .order("updated_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) notes by type in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchNotesByType", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Notes fetch by type failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchNotesByType", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async throws -> [Note] {
        let client = try getClient()
        let startTime = Date()

        do {
            let response: [Note] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .select()
                    .eq("related_type", value: type.rawValue)
                    .eq("related_id", value: relatedId)
                    .order("updated_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) notes by entity in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchNotesByRelatedEntity", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Notes fetch by entity failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchNotesByRelatedEntity", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Create Note

    func createNote(_ data: NoteInsertData) async throws -> Note {
        let client = try getClient()

        struct NoteInsert: Encodable {
            let coupleId: String
            let title: String?
            let content: String
            let relatedType: String?
            let relatedId: String?

            enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
                case title = "title"
                case content = "content"
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

        let startTime = Date()

        do {
            let response: Note = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created note in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "createNote", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Note creation failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "createNote", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Update Note

    func updateNote(_ id: UUID, data: NoteInsertData) async throws -> Note {
        let client = try getClient()

        struct NoteUpdate: Encodable {
            let title: String?
            let content: String
            let relatedType: String?
            let relatedId: String?

            enum CodingKeys: String, CodingKey {
                case title = "title"
                case content = "content"
                case relatedType = "related_type"
                case relatedId = "related_id"
            }
        }

        let updateData = NoteUpdate(
            title: data.title,
            content: data.content,
            relatedType: data.relatedType?.rawValue,
            relatedId: data.relatedId)

        let startTime = Date()

        do {
            let response: Note = try await RepositoryNetwork.withRetry {
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
            logger.info("Updated note in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "updateNote", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Note update failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "updateNote", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Delete Note

    func deleteNote(_ id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted note in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteNote", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Note deletion failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteNote", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Search Notes

    func searchNotes(query: String) async throws -> [Note] {
        let client = try getClient()
        let startTime = Date()

        do {
            let response: [Note] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("notes")
                    .select()
                    .or("title.ilike.%\(query)%,content.ilike.%\(query)%")
                    .order("updated_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Searched notes, found \(response.count) results in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "searchNotes", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Note search failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "searchNotes", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
}
