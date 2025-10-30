//
//  MockOnboardingRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of OnboardingRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockOnboardingRepository: OnboardingRepositoryProtocol {
    var progress: OnboardingProgress?
    var shouldThrowError = false
    var errorToThrow: OnboardingError = .fetchFailed(underlying: NSError(domain: "MockError", code: 1))
    
    // Track method calls for verification
    var fetchCalled = false
    var saveCalled = false
    var updateCalled = false
    var completeCalled = false
    var deleteCalled = false
    var isCompletedCalled = false
    
    func fetchOnboardingProgress() async throws -> OnboardingProgress? {
        fetchCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return progress
    }
    
    func saveOnboardingProgress(_ progress: OnboardingProgress) async throws -> OnboardingProgress {
        saveCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        self.progress = progress
        return progress
    }
    
    func updateOnboardingProgress(_ progress: OnboardingProgress) async throws -> OnboardingProgress {
        updateCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        self.progress = progress
        return progress
    }
    
    func completeOnboarding() async throws -> OnboardingProgress {
        completeCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        guard var currentProgress = progress else {
            throw OnboardingError.progressNotFound
        }
        currentProgress.isCompleted = true
        currentProgress.currentStep = .completion
        self.progress = currentProgress
        return currentProgress
    }
    
    func deleteOnboardingProgress() async throws {
        deleteCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        progress = nil
    }
    
    func isOnboardingCompleted() async throws -> Bool {
        isCompletedCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return progress?.isCompleted ?? false
    }
    
    // Helper methods for testing
    func reset() {
        progress = nil
        shouldThrowError = false
        fetchCalled = false
        saveCalled = false
        updateCalled = false
        completeCalled = false
        deleteCalled = false
        isCompletedCalled = false
    }
}
