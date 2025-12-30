//
//  OnboardingProgressService.swift
//  I Do Blueprint
//
//  Service for managing onboarding progress persistence
//

import Foundation
import Dependencies

/// Actor managing onboarding progress persistence operations
actor OnboardingProgressService {
    
    // MARK: - Dependencies
    
    private let repository: OnboardingRepositoryProtocol
    private let logger = AppLogger.ui
    
    // MARK: - Initialization
    
    init(repository: OnboardingRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Load Progress
    
    /// Loads existing onboarding progress or returns nil if none exists
    func loadProgress() async throws -> OnboardingProgress? {
        logger.info("Loading onboarding progress")
        
        do {
            let progress = try await repository.fetchOnboardingProgress()
            
            if let progress = progress {
                logger.info("Found existing onboarding progress at step: \(progress.currentStep.rawValue)")
                
                await MainActor.run {
                    SentryService.shared.addBreadcrumb(
                        message: "Onboarding progress loaded",
                        category: "onboarding",
                        data: [
                            "currentStep": progress.currentStep.rawValue,
                            "completedSteps": progress.completedSteps.count,
                            "isCompleted": progress.isCompleted
                        ]
                    )
                }
            } else {
                logger.info("No existing onboarding progress found")
            }
            
            return progress
        } catch {
            logger.error("Failed to load onboarding progress", error: error)
            
            await MainActor.run {
                SentryService.shared.captureError(error, context: [
                    "operation": "loadOnboardingProgress"
                ])
            }
            
            throw error
        }
    }
    
    // MARK: - Create Progress
    
    /// Creates initial onboarding progress
    func createProgress(coupleId: UUID, mode: OnboardingMode) async throws -> OnboardingProgress {
        logger.info("Creating onboarding progress with mode: \(mode.rawValue)")
        
        let progress = OnboardingProgress(
            coupleId: coupleId,
            currentStep: .welcome,
            completedSteps: [],
            isCompleted: false
        )
        
        do {
            let saved = try await repository.saveOnboardingProgress(progress)
            
            await MainActor.run {
                SentryService.shared.trackAction(
                    "start_onboarding",
                    category: "onboarding",
                    metadata: ["mode": mode.rawValue]
                )
            }
            
            logger.info("Onboarding progress created successfully")
            return saved
        } catch {
            logger.error("Failed to create onboarding progress", error: error)
            
            await MainActor.run {
                SentryService.shared.captureError(error, context: [
                    "operation": "createOnboardingProgress",
                    "mode": mode.rawValue
                ])
            }
            
            throw error
        }
    }
    
    // MARK: - Update Progress
    
    /// Updates existing onboarding progress
    func updateProgress(_ progress: OnboardingProgress) async throws -> OnboardingProgress {
        logger.info("Updating onboarding progress")
        
        do {
            let saved = try await repository.updateOnboardingProgress(progress)
            logger.info("Progress updated successfully")
            return saved
        } catch {
            logger.error("Failed to update progress", error: error)
            
            await MainActor.run {
                SentryService.shared.captureError(error, context: [
                    "operation": "updateProgress",
                    "currentStep": progress.currentStep.rawValue
                ])
            }
            
            throw error
        }
    }
    
    // MARK: - Complete Onboarding
    
    /// Marks onboarding as completed
    func completeOnboarding() async throws -> OnboardingProgress {
        logger.info("Completing onboarding")
        
        do {
            let completed = try await repository.completeOnboarding()
            
            await MainActor.run {
                SentryService.shared.trackAction(
                    "complete_onboarding",
                    category: "onboarding",
                    metadata: [
                        "totalSteps": OnboardingStep.allCases.count
                    ]
                )
            }
            
            logger.info("Onboarding completed successfully")
            return completed
        } catch {
            logger.error("Failed to complete onboarding", error: error)
            
            await MainActor.run {
                SentryService.shared.captureError(error, context: [
                    "operation": "completeOnboarding"
                ])
            }
            
            throw error
        }
    }
    
    // MARK: - Delete Progress
    
    /// Deletes onboarding progress (for reset)
    func deleteProgress() async throws {
        logger.info("Deleting onboarding progress")
        
        do {
            try await repository.deleteOnboardingProgress()
            logger.info("Onboarding progress deleted successfully")
        } catch {
            logger.error("Failed to delete onboarding progress", error: error)
            throw error
        }
    }
    
    // MARK: - Check Completion
    
    /// Checks if onboarding has been completed
    func isCompleted() async throws -> Bool {
        do {
            let completed = try await repository.isOnboardingCompleted()
            return completed
        } catch {
            logger.error("Failed to check onboarding completion", error: error)
            throw error
        }
    }
}
