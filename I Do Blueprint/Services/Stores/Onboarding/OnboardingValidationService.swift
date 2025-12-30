//
//  OnboardingValidationService.swift
//  I Do Blueprint
//
//  Service for validating onboarding step requirements
//

import Foundation

/// Service managing onboarding step validation
struct OnboardingValidationService {
    
    // MARK: - Step Validation
    
    /// Validates the requirements for a specific step
    static func validateStep(
        _ step: OnboardingStep,
        weddingDetails: WeddingDetails,
        defaultSettings: OnboardingDefaultSettings
    ) -> Bool {
        switch step {
        case .welcome:
            return true // Always valid
            
        case .weddingDetails:
            return weddingDetails.isValid
            
        case .defaultSettings:
            return !defaultSettings.currency.isEmpty && !defaultSettings.timezone.isEmpty
            
        case .featurePreferences, .guestImport, .vendorImport:
            return true // Optional steps
            
        case .budgetSetup:
            return true // Will validate in budget wizard
            
        case .completion:
            return true
        }
    }
    
    /// Validates wedding details
    static func validateWeddingDetails(_ details: WeddingDetails) -> (isValid: Bool, error: String?) {
        guard details.isValid else {
            return (false, "Please enter both partner names and either select a date or check TBD")
        }
        return (true, nil)
    }
    
    /// Validates default settings
    static func validateDefaultSettings(_ settings: OnboardingDefaultSettings) -> (isValid: Bool, error: String?) {
        if settings.currency.isEmpty {
            return (false, "Please select a currency")
        }
        if settings.timezone.isEmpty {
            return (false, "Please select a timezone")
        }
        return (true, nil)
    }
}
