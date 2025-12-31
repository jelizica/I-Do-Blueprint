//
//  TimelineItemService.swift
//  I Do Blueprint
//
//  CRUD operations for timeline items
//

import Foundation
import Supabase

/// Service for timeline item CRUD operations
class TimelineItemService {
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
    
    // MARK: - Fetch
    
    func fetchTimelineItemById(_ id: UUID) async throws -> TimelineItem {
        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Create
    
    func createTimelineItem(_ data: TimelineItemInsertData) async throws -> TimelineItem {
        struct TimelineItemInsert: Encodable {
            let coupleId: String
            let title: String
            let itemType: String
            let itemDate: String
            let completed: Bool
            let relatedId: String?
            let description: String?
            
            enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
                case title
                case itemType = "item_type"
                case itemDate = "item_date"
                case completed
                case relatedId = "related_id"
                case description
            }
        }
        
        let insertData = TimelineItemInsert(
            coupleId: data.coupleId.uuidString,
            title: data.title,
            itemType: data.itemType.rawValue,
            itemDate: TimelineDateParser.stringFromDate(data.itemDate),
            completed: data.completed,
            relatedId: data.relatedId,
            description: data.description
        )
        
        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Update
    
    func updateTimelineItem(_ id: UUID, data: TimelineItemInsertData) async throws -> TimelineItem {
        struct TimelineItemUpdate: Encodable {
            let title: String
            let itemType: String
            let itemDate: String
            let completed: Bool
            let relatedId: String?
            let description: String?
            
            enum CodingKeys: String, CodingKey {
                case title
                case itemType = "item_type"
                case itemDate = "item_date"
                case completed
                case relatedId = "related_id"
                case description
            }
        }
        
        let updateData = TimelineItemUpdate(
            title: data.title,
            itemType: data.itemType.rawValue,
            itemDate: TimelineDateParser.stringFromDate(data.itemDate),
            completed: data.completed,
            relatedId: data.relatedId,
            description: data.description
        )
        
        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .update(updateData)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateTimelineItemCompletion(_ id: UUID, completed: Bool) async throws -> TimelineItem {
        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .update(["completed": completed])
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Delete
    
    func deleteTimelineItem(_ id: UUID) async throws {
        let client = try getClient()
        try await client
            .from("timeline_items")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
