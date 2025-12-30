//
//  SettingsSectionStore.swift
//  I Do Blueprint
//
//  Generic store for managing individual settings sections
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsSectionStore<T: Equatable>: ObservableObject {
    @Published var localValue: T
    @Published var isSaving = false
    
    private let sectionName: String
    private let getValue: () -> T
    private let setValue: (T) -> Void
    private let saveOperation: (T) async throws -> Void
    private let onSuccess: (String) -> Void
    private let onError: (Error, String) -> Void
    
    init(
        sectionName: String,
        getValue: @escaping () -> T,
        setValue: @escaping (T) -> Void,
        saveOperation: @escaping (T) async throws -> Void,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (Error, String) -> Void
    ) {
        self.sectionName = sectionName
        self.getValue = getValue
        self.setValue = setValue
        self.saveOperation = saveOperation
        self.onSuccess = onSuccess
        self.onError = onError
        self.localValue = getValue()
    }
    
    var hasUnsavedChanges: Bool {
        localValue != getValue()
    }
    
    func save() async {
        isSaving = true
        defer { isSaving = false }
        
        let original = getValue()
        setValue(localValue)
        
        do {
            try await saveOperation(localValue)
            onSuccess("\(sectionName) settings updated")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            setValue(original)
            onError(error, sectionName)
        } catch {
            setValue(original)
            onError(error, sectionName)
        }
    }
    
    func discard() {
        localValue = getValue()
    }
    
    func refresh() {
        localValue = getValue()
    }
}
