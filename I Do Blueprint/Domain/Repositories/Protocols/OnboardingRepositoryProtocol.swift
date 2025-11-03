//
//  OnboardingRepositoryProtocol.swift
//  I Do Blueprint
//
//  Repository protocol for onboarding data access
//

import Foundation

/// Protocol defining onboarding data access operations
protocol OnboardingRepositoryProtocol: Sendable {
    /// Fetches the current onboarding progress for the authenticated couple
    /// - Returns: OnboardingProgress if found, nil otherwise
    /// - Throws: OnboardingError if fetch fails or tenant context is missing
    func fetchOnboardingProgress() async throws -> OnboardingProgress?

    /// Saves onboarding progress for the authenticated couple
    /// - Parameter progress: The onboarding progress to save
    /// - Returns: The saved onboarding progress
    /// - Throws: OnboardingError if save fails or tenant context is missing
    func saveOnboardingProgress(_ progress: OnboardingProgress) async throws -> OnboardingProgress

    /// Updates onboarding progress for the authenticated couple
    /// - Parameter progress: The onboarding progress to update
    /// - Returns: The updated onboarding progress
    /// - Throws: OnboardingError if update fails or tenant context is missing
    func updateOnboardingProgress(_ progress: OnboardingProgress) async throws -> OnboardingProgress

    /// Marks onboarding as completed for the authenticated couple
    /// - Returns: The completed onboarding progress
    /// - Throws: OnboardingError if completion fails or tenant context is missing
    func completeOnboarding() async throws -> OnboardingProgress

    /// Deletes onboarding progress for the authenticated couple
    /// - Throws: OnboardingError if deletion fails or tenant context is missing
    func deleteOnboardingProgress() async throws

    /// Checks if onboarding has been completed for the authenticated couple
    /// - Returns: True if onboarding is completed, false otherwise
    /// - Throws: OnboardingError if check fails or tenant context is missing
    func isOnboardingCompleted() async throws -> Bool
}
