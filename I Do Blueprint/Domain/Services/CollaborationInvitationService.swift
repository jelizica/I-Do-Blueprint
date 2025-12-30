//
//  CollaborationInvitationService.swift
//  I Do Blueprint
//
//  Domain service for collaboration invitation business logic
//

import Foundation
import Supabase

/// Actor-based service handling invitation-specific business logic
actor CollaborationInvitationService {
    private let supabase: SupabaseClient
    private nonisolated let logger = AppLogger.repository
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Invitation Operations
    
    /// Fetch invitation details by token
    func fetchInvitationByToken(_ token: String) async throws -> InvitationDetails {
        let startTime = Date()
        
        logger.info("Fetching invitation by token")
        
        // Query invitation table (no tenant filtering - token is globally unique)
        let invitations: [Invitation] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("invitations")
                .select()
                .eq("token", value: token)
                .eq("status", value: "pending")
                .limit(1)
                .execute()
                .value
        }
        
        guard let invitation = invitations.first else {
            logger.warning("Invitation not found or already accepted for token")
            throw CollaborationError.invitationNotFound
        }
        
        // Check if expired
        if invitation.isExpired {
            logger.warning("Invitation has expired")
            throw CollaborationError.invitationExpired
        }
        
        // Fetch role
        let role = try await fetchRole(id: invitation.roleId)
        
        // Fetch couple name
        let coupleName = try await fetchCoupleName(coupleId: invitation.coupleId)
        
        let details = InvitationDetails(
            invitation: invitation,
            role: role,
            coupleId: invitation.coupleId,
            coupleName: coupleName,
            inviterEmail: nil // We can't easily query auth.users from client
        )
        
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("fetchInvitationByToken", duration: duration)
        
        logger.info("Fetched invitation details in \(String(format: "%.2f", duration))s")
        
        return details
    }
    
    /// Create invitation and send email
    func createInvitation(
        email: String,
        roleId: UUID,
        displayName: String?,
        coupleId: UUID,
        invitedBy: UUID
    ) async throws -> Invitation {
        let startTime = Date()
        
        struct InvitationInsert: Encodable {
            let couple_id: UUID
            let email: String
            let role_id: UUID
            let invited_by: UUID
            let invited_at: Date
            let display_name: String?
            let status: String
        }
        
        let newInvitation = InvitationInsert(
            couple_id: coupleId,
            email: email,
            role_id: roleId,
            invited_by: invitedBy,
            invited_at: Date(),
            display_name: displayName,
            status: "pending"
        )
        
        let created: Invitation = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("invitations")
                .insert(newInvitation)
                .select()
                .single()
                .execute()
                .value
        }
        
        // Send invitation email
        try await sendInvitationEmail(
            invitation: created,
            roleId: roleId,
            coupleId: coupleId
        )
        
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("createInvitation", duration: duration)
        
        logger.info("Created invitation for \(email) in \(String(format: "%.2f", duration))s")
        AnalyticsService.trackNetwork(operation: "createInvitation", outcome: .success, duration: duration)
        
        return created
    }
    
    /// Accept invitation via database function
    func acceptInvitation(id: UUID) async throws -> AcceptInvitationResult {
        let startTime = Date()
        
        logger.info("Accepting invitation via database function")
        
        struct AcceptInvitationParams: Encodable {
            let p_invitation_id: UUID
        }
        
        let params = AcceptInvitationParams(p_invitation_id: id)
        
        struct AcceptInvitationResultRow: Decodable {
            let collaborator_id: UUID
            let couple_id: UUID
            let user_id: UUID
            let role_id: UUID
            let email: String
            let display_name: String?
            let status: String
        }
        
        let results: [AcceptInvitationResultRow] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .rpc("accept_invitation", params: params)
                .execute()
                .value
        }
        
        guard let result = results.first else {
            logger.error("Database function returned no result")
            throw CollaborationError.updateFailed(underlying: NSError(
                domain: "CollaborationInvitationService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Function returned no collaborator"]
            ))
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("acceptInvitation", duration: duration)
        
        logger.info("Accepted invitation via database function in \(String(format: "%.2f", duration))s")
        
        return AcceptInvitationResult(
            collaboratorId: result.collaborator_id,
            coupleId: result.couple_id,
            userId: result.user_id,
            roleId: result.role_id,
            email: result.email,
            displayName: result.display_name,
            status: result.status
        )
    }
    
    /// Decline invitation
    func declineInvitation(id: UUID) async throws {
        let startTime = Date()
        
        logger.info("Declining invitation: \(id.uuidString)")
        
        struct UpdatePayload: Encodable {
            let status: String
            let updated_at: Date
        }
        
        let updates = UpdatePayload(
            status: "declined",
            updated_at: Date()
        )
        
        _ = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("collaborators")
                .update(updates)
                .eq("id", value: id)
                .eq("status", value: "pending")
                .execute()
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("declineInvitation", duration: duration)
        
        logger.info("Declined invitation in \(String(format: "%.2f", duration))s")
        
        await SentryService.shared.trackAction(
            "invitation_declined",
            category: "collaboration",
            metadata: ["invitation_id": id.uuidString]
        )
    }
    
    // MARK: - Private Helpers
    
    private func fetchRole(id: UUID) async throws -> CollaborationRole {
        let roles: [CollaborationRole] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("collaboration_roles")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
        }
        
        guard let role = roles.first else {
            throw CollaborationError.roleNotFound
        }
        
        return role
    }
    
    private func fetchCoupleName(coupleId: UUID) async throws -> String? {
        struct CoupleSettingsRow: Decodable {
            let settings: CoupleSettingsJSON
        }
        
        struct CoupleSettingsJSON: Decodable {
            let global: GlobalSettingsJSON?
        }
        
        struct GlobalSettingsJSON: Decodable {
            let partner1FullName: String?
            let partner2FullName: String?
            let partner1Nickname: String?
            let partner2Nickname: String?
            
            enum CodingKeys: String, CodingKey {
                case partner1FullName = "partner1_full_name"
                case partner2FullName = "partner2_full_name"
                case partner1Nickname = "partner1_nickname"
                case partner2Nickname = "partner2_nickname"
            }
        }
        
        let settingsRows: [CoupleSettingsRow] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("couple_settings")
                .select("settings")
                .eq("couple_id", value: coupleId)
                .limit(1)
                .execute()
                .value
        }
        
        guard let settingsRow = settingsRows.first,
              let global = settingsRow.settings.global else {
            return nil
        }
        
        let p1 = global.partner1Nickname?.isEmpty == false ? global.partner1Nickname : global.partner1FullName
        let p2 = global.partner2Nickname?.isEmpty == false ? global.partner2Nickname : global.partner2FullName
        let coupleName = [p1, p2].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " & ")
        
        return coupleName.isEmpty ? nil : coupleName
    }
    
    private func sendInvitationEmail(
        invitation: Invitation,
        roleId: UUID,
        coupleId: UUID
    ) async throws {
        do {
            // Get inviter's email
            let inviterEmail = try await UserContextProvider.shared.requireUserEmail()
            let inviterName = inviterEmail
            
            // Get couple name
            let coupleName = try await fetchCoupleName(coupleId: coupleId) ?? "Your Wedding"
            
            // Get role name
            let role = try await fetchRole(id: roleId)
            let roleName = role.roleName.displayName
            
            // Calculate expiry (7 days from now)
            let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            
            // Send email
            try await ResendEmailService.shared.sendInvitationEmail(
                to: invitation.email,
                inviterName: inviterName,
                coupleName: coupleName,
                role: roleName,
                token: invitation.token,
                expiresAt: expiresAt
            )
            
            logger.info("Sent invitation email to \(invitation.email) via Resend")
        } catch {
            // Log but don't fail - invitation was created successfully
            logger.warning("Failed to send invitation email to \(invitation.email): \(error.localizedDescription)")
            await SentryService.shared.captureError(error, context: [
                "operation": "sendInvitationEmail",
                "email": invitation.email
            ])
        }
    }
}

// MARK: - Supporting Types

struct AcceptInvitationResult {
    let collaboratorId: UUID
    let coupleId: UUID
    let userId: UUID
    let roleId: UUID
    let email: String
    let displayName: String?
    let status: String
}
