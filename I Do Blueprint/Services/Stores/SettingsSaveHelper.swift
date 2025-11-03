//
//  SettingsSaveHelper.swift
//  I Do Blueprint
//
//  Helper for saving settings sections with error handling and rollback
//

import Foundation

/// Helper struct for saving individual settings sections with consistent error handling
struct SettingsSaveHelper {
    /// Save a settings section with optimistic update and rollback on error
    /// - Parameters:
    ///   - section: Name of the section being saved (for tracking)
    ///   - getCurrentValue: Closure to get the current value from settings
    ///   - getLocalValue: Closure to get the local (edited) value
    ///   - updateSettings: Closure to update the settings property
    ///   - saveToRepository: Closure to save to the repository
    ///   - onSuccess: Closure called on successful save
    ///   - onError: Closure called on error with the error object
    static func save<T>(
        section: String,
        getCurrentValue: () -> T,
        getLocalValue: () -> T,
        updateSettings: (T) -> Void,
        saveToRepository: () async throws -> Void,
        onSuccess: () -> Void,
        onError: (Error) -> Void
    ) async {
        let original = getCurrentValue()
        let localValue = getLocalValue()
        
        // Optimistic update
        updateSettings(localValue)
        
        do {
            try await saveToRepository()
            onSuccess()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            // Rollback on network error
            updateSettings(original)
            onError(SettingsError.networkUnavailable)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "save\(section.capitalized)Settings",
                    feature: "settings",
                    metadata: ["section": section]
                )
            )
        } catch {
            // Rollback on any other error
            updateSettings(original)
            onError(SettingsError.updateFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "save\(section.capitalized)Settings",
                    feature: "settings",
                    metadata: ["section": section]
                )
            )
        }
    }
    
    /// Update a settings section with optimistic update and rollback on error
    /// - Parameters:
    ///   - newValue: The new value to set
    ///   - getCurrentValue: Closure to get the current value from settings
    ///   - updateSettings: Closure to update the settings property
    ///   - saveToRepository: Closure to save to the repository
    ///   - onSuccess: Closure called on successful save
    ///   - onError: Closure called on error with the error object
    static func update<T>(
        newValue: T,
        getCurrentValue: () -> T,
        updateSettings: (T) -> Void,
        saveToRepository: (T) async throws -> Void,
        onSuccess: () -> Void,
        onError: (Error) -> Void
    ) async {
        let original = getCurrentValue()
        
        // Optimistic update
        updateSettings(newValue)
        
        do {
            try await saveToRepository(newValue)
            onSuccess()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            // Rollback on network error
            updateSettings(original)
            onError(SettingsError.networkUnavailable)
        } catch {
            // Rollback on any other error
            updateSettings(original)
            onError(SettingsError.updateFailed(underlying: error))
        }
    }
}
