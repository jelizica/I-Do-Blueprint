//
//  OnboardingNavigationService.swift
//  I Do Blueprint
//
//  Service for mode-aware onboarding navigation logic
//

import Foundation

/// Service managing onboarding step navigation logic
struct OnboardingNavigationService {
    
    // MARK: - Express Mode Flow
    
    /// Express flow: welcome → weddingDetails → budgetSetup → completion
    private static let expressFlow: [OnboardingStep] = [
        .welcome,
        .weddingDetails,
        .budgetSetup,
        .completion
    ]
    
    // MARK: - Navigation
    
    /// Gets the next step based on the selected onboarding mode
    static func getNextStep(
        currentStep: OnboardingStep,
        mode: OnboardingMode
    ) -> OnboardingStep? {
        if mode == .express {
            // Express flow: welcome → weddingDetails → budgetSetup → completion
            guard let currentIndex = expressFlow.firstIndex(of: currentStep),
                  currentIndex < expressFlow.count - 1 else {
                return nil
            }
            
            return expressFlow[currentIndex + 1]
        } else {
            // Guided flow: all steps in order
            return currentStep.nextStep
        }
    }
    
    /// Gets the previous step (same for both modes)
    static func getPreviousStep(currentStep: OnboardingStep) -> OnboardingStep? {
        return currentStep.previousStep
    }
    
    /// Checks if a step can be skipped
    static func canSkipStep(_ step: OnboardingStep) -> Bool {
        return step.isOptional
    }
    
    /// Calculates progress percentage based on mode
    static func calculateProgress(
        completedSteps: Set<OnboardingStep>,
        mode: OnboardingMode
    ) -> Double {
        let totalSteps: Int = mode == .express ? expressFlow.count : OnboardingStep.allCases.count
        let completed = completedSteps.count
        return Double(completed) / Double(totalSteps)
    }
}
