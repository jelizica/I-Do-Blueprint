//
//  MilestoneService.swift
//  I Do Blueprint
//
//  CRUD operations for milestones
//

import Foundation
import Supabase

/// Service for milestone CRUD operations
class MilestoneService {
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
    
    func fetchMilestones() async throws -> [Milestone] {
        let client = try getClient()
        let response: [Milestone] = try await client
            .from("milestones")
            .select()
            .order("milestone_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func fetchMilestoneById(_ id: UUID) async throws -> Milestone {
        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Create
    
    func createMilestone(_ data: MilestoneInsertData) async throws -> Milestone {
        struct MilestoneInsert: Encodable {
            let coupleId: String
            let milestoneName: String
            let milestoneDate: String
            let completed: Bool
            let description: String?
            let color: String?
            
            enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
                case milestoneName = "milestone_name"
                case milestoneDate = "milestone_date"
                case completed
                case description
                case color
            }
        }
        
        let insertData = MilestoneInsert(
            coupleId: data.coupleId.uuidString,
            milestoneName: data.milestoneName,
            milestoneDate: TimelineDateParser.stringFromDate(data.milestoneDate),
            completed: data.completed,
            description: data.description,
            color: data.color
        )
        
        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Update
    
    func updateMilestone(_ id: UUID, data: MilestoneInsertData) async throws -> Milestone {
        struct MilestoneUpdate: Encodable {
            let milestoneName: String
            let milestoneDate: String
            let completed: Bool
            let description: String?
            let color: String?
            
            enum CodingKeys: String, CodingKey {
                case milestoneName = "milestone_name"
                case milestoneDate = "milestone_date"
                case completed
                case description
                case color
            }
        }
        
        let updateData = MilestoneUpdate(
            milestoneName: data.milestoneName,
            milestoneDate: TimelineDateParser.stringFromDate(data.milestoneDate),
            completed: data.completed,
            description: data.description,
            color: data.color
        )
        
        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .update(updateData)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateMilestoneCompletion(_ id: UUID, completed: Bool) async throws -> Milestone {
        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .update(["completed": completed])
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Delete
    
    func deleteMilestone(_ id: UUID) async throws {
        let client = try getClient()
        try await client
            .from("milestones")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
