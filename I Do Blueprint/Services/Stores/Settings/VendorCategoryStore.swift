//
//  VendorCategoryStore.swift
//  I Do Blueprint
//
//  Manages custom vendor categories
//

import Foundation
import SwiftUI
import Combine

@MainActor
class VendorCategoryStore: ObservableObject {
    @Published var categories: [CustomVendorCategory] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repository: any SettingsRepositoryProtocol
    private let onSuccess: (String) -> Void
    private let onError: (Error, String) -> Void
    
    init(
        repository: any SettingsRepositoryProtocol,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (Error, String) -> Void
    ) {
        self.repository = repository
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func loadCategories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            categories = try await repository.fetchCustomVendorCategories()
            AppLogger.ui.info("VendorCategoryStore: Loaded \(categories.count) categories")
        } catch {
            self.error = error
            AppLogger.ui.error("VendorCategoryStore: Failed to load categories", error: error)
        }
    }
    
    func createCategory(_ category: CustomVendorCategory) async {
        do {
            let created = try await repository.createVendorCategory(category)
            categories.append(created)
            categories.sort { $0.name < $1.name }
            onSuccess("Category created successfully")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            self.error = error
            onError(error, "create vendor category")
        } catch {
            self.error = error
            onError(error, "create vendor category")
        }
    }
    
    func updateCategory(_ category: CustomVendorCategory) async {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        let original = categories[index]
        categories[index] = category
        
        do {
            let updated = try await repository.updateVendorCategory(category)
            categories[index] = updated
            categories.sort { $0.name < $1.name }
            onSuccess("Category updated successfully")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            categories[index] = original
            self.error = error
            onError(error, "update vendor category")
        } catch {
            categories[index] = original
            self.error = error
            onError(error, "update vendor category")
        }
    }
    
    func deleteCategory(_ category: CustomVendorCategory) async {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        let removed = categories.remove(at: index)
        
        do {
            try await repository.deleteVendorCategory(id: category.id)
            onSuccess("Category deleted successfully")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            categories.insert(removed, at: index)
            self.error = error
            onError(error, "delete vendor category")
        } catch {
            categories.insert(removed, at: index)
            self.error = error
            onError(error, "delete vendor category")
        }
    }
    
    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        try await repository.checkVendorsUsingCategory(categoryId: categoryId)
    }
}
