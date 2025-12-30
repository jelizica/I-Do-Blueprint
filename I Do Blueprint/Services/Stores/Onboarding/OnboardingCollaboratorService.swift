//
//  OnboardingCollaboratorService.swift
//  I Do Blueprint
//
//  Service for creating owner collaborator during onboarding
//

import Foundation
import Dependencies

/// Actor managing owner collaborator creation during onboarding
actor OnboardingCollaboratorService {
    
    // MARK: - Dependencies
    
    private let collaborationRepository: CollaborationRepositoryProtocol
    private let logger = AppLogger.ui
    
    // MARK: - Initialization
    
    init(collaborationRepository: CollaborationRepositoryProtocol) {
        self.collaborationRepository = collaborationRepository
    }
    
    // MARK: - Create Owner Collaborator
    
    /// Creates owner collaborator record for the user who completed onboarding
    func createOwnerCollaborator(
        coupleId: UUID,
        userId: UUID,
        userEmail: String,
        weddingDetails: WeddingDetails
    ) async throws {
        logger.info("Creating owner collaborator record")
        
        // Determine display name from wedding details
        // Use partner1's name as default (user can update later if they're partner2)
        let displayName = weddingDetails.partner1Name.isEmpty ? nil : weddingDetails.partner1Name
        
        do {
            let collaborator = try await collaborationRepository.createOwnerCollaborator(
                coupleId: coupleId,
                userId: userId,
                email: userEmail,
                displayName: displayName
            )
            
            logger.info("Owner collaborator created successfully: \(collaborator.id.uuidString)")
            
            await MainActor.run {
                SentryService.shared.addBreadcrumb(
                    message: "Owner collaborator created during onboarding",
                    category: "onboarding",
                    data: [
                        "couple_id": coupleId.uuidString,
                        "user_id": userId.uuidString,
                        "has_display_name": displayName != nil
                    ]
                )
            }
        } catch {
            // Log error but don't fail onboarding
            // User can still use the app, just won't be able to invite others until this is fixed
            logger.error("Failed to create owner collaborator (non-blocking)", error: error)
            
            await MainActor.run {
                SentryService.shared.captureError(error, context: [
                    "operation": "createOwnerCollaboratorRecord",
                    "couple_id": coupleId.uuidString,
                    "user_id": userId.uuidString,
                    "blocking": "false"
                ])
            }
            
            throw error
        }
    }
}
