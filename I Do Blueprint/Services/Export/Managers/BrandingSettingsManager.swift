//
//  BrandingSettingsManager.swift
//  I Do Blueprint
//
//  Branding settings persistence service
//

import Foundation

/// Protocol for branding settings management
protocol BrandingSettingsManagerProtocol {
    func loadBranding() -> BrandingSettings
    func saveBranding(_ branding: BrandingSettings)
    func resetBranding()
}

/// Service responsible for branding settings persistence
class BrandingSettingsManager: BrandingSettingsManagerProtocol {
    
    private let userDefaultsKey = "CustomBranding"
    
    // MARK: - Loading
    
    func loadBranding() -> BrandingSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let branding = try? JSONDecoder().decode(BrandingSettings.self, from: data) else {
            return BrandingSettings() // Return default settings
        }
        return branding
    }
    
    // MARK: - Saving
    
    func saveBranding(_ branding: BrandingSettings) {
        if let data = try? JSONEncoder().encode(branding) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Reset
    
    func resetBranding() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
