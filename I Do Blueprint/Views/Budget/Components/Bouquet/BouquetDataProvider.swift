//
//  BouquetDataProvider.swift
//  I Do Blueprint
//
//  Data provider for the Budget Bouquet visualization
//  Fetches budget items and groups them by category for petal rendering
//

import Combine
import Foundation
import SwiftUI

// MARK: - Bouquet Category Data Model

/// Represents a budget category for the bouquet visualization
/// Each category becomes a petal in the flower
struct BouquetCategoryData: Identifiable, Equatable {
    let id: String
    let categoryName: String
    let totalBudgeted: Double
    let totalSpent: Double
    let itemCount: Int
    let color: Color
    
    /// Progress ratio (0.0 to 1.0) representing spent/budgeted
    var progressRatio: Double {
        guard totalBudgeted > 0 else { return 0 }
        return min(1.0, totalSpent / totalBudgeted)
    }
    
    /// Whether this category is over budget
    var isOverBudget: Bool {
        totalSpent > totalBudgeted
    }
    
    /// Remaining amount in this category
    var remaining: Double {
        totalBudgeted - totalSpent
    }
}

// MARK: - Bouquet Data Provider

/// Provides data for the Budget Bouquet visualization
/// Groups budget items by category and calculates totals
@MainActor
class BouquetDataProvider: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var categories: [BouquetCategoryData] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    // MARK: - Computed Properties
    
    /// Total budgeted amount across all categories
    var totalBudgeted: Double {
        categories.reduce(0) { $0 + $1.totalBudgeted }
    }
    
    /// Total spent amount across all categories
    var totalSpent: Double {
        categories.reduce(0) { $0 + $1.totalSpent }
    }
    
    /// Overall progress ratio
    var overallProgress: Double {
        guard totalBudgeted > 0 else { return 0 }
        return min(1.0, totalSpent / totalBudgeted)
    }
    
    /// Whether any data exists
    var hasData: Bool {
        !categories.isEmpty
    }
    
    // MARK: - Category Colors
    
    /// Predefined colors for budget categories
    /// These match the HTML design's color scheme
    private static let categoryColors: [String: Color] = [
        "Venue": Color.fromHex("#f43f5e"),           // Rose
        "Venue & Catering": Color.fromHex("#f43f5e"),
        "Photography": Color.fromHex("#a855f7"),     // Purple
        "Photography & Video": Color.fromHex("#a855f7"),
        "Attire": Color.fromHex("#ec4899"),          // Pink
        "Attire & Beauty": Color.fromHex("#ec4899"),
        "Flowers": Color.fromHex("#f59e0b"),         // Amber
        "Flowers & Decor": Color.fromHex("#f59e0b"),
        "Entertainment": Color.fromHex("#3b82f6"),   // Blue
        "Stationery": Color.fromHex("#10b981"),      // Green
        "Transportation": Color.fromHex("#6366f1"),  // Indigo
        "Catering": Color.fromHex("#ef4444"),        // Red
        "Cake": Color.fromHex("#f43f5e"),            // Rose
        "Wedding Cake": Color.fromHex("#f43f5e"),
        "Favors": Color.fromHex("#14b8a6"),          // Teal
        "Favors & Gifts": Color.fromHex("#14b8a6"),
        "Honeymoon": Color.fromHex("#a855f7"),       // Purple
        "Rehearsal": Color.fromHex("#f59e0b"),       // Amber
        "Rehearsal Dinner": Color.fromHex("#f59e0b"),
        "Hair & Makeup": Color.fromHex("#ec4899"),   // Pink
        "Rings": Color.fromHex("#f59e0b"),           // Amber
        "Wedding Rings": Color.fromHex("#f59e0b"),
        "Officiant": Color.fromHex("#3b82f6"),       // Blue
        "License": Color.fromHex("#10b981"),         // Green
        "Marriage License": Color.fromHex("#10b981"),
        "Guest Book": Color.fromHex("#14b8a6"),      // Teal
        "Programs": Color.fromHex("#6366f1"),        // Indigo
        "Signage": Color.fromHex("#a855f7"),         // Purple
        "Accessories": Color.fromHex("#ec4899"),     // Pink
        "Miscellaneous": Color.fromHex("#64748b"),   // Slate
        "Other": Color.fromHex("#64748b")            // Slate
    ]
    
    /// Get color for a category name
    private func colorForCategory(_ categoryName: String) -> Color {
        // Try exact match first
        if let color = Self.categoryColors[categoryName] {
            return color
        }
        
        // Try case-insensitive match
        let lowercased = categoryName.lowercased()
        for (key, color) in Self.categoryColors {
            if key.lowercased() == lowercased {
                return color
            }
        }
        
        // Try partial match
        for (key, color) in Self.categoryColors {
            if lowercased.contains(key.lowercased()) || key.lowercased().contains(lowercased) {
                return color
            }
        }
        
        // Generate a consistent color based on the category name hash
        return generateColorFromString(categoryName)
    }
    
    /// Generate a consistent color from a string (for categories without predefined colors)
    private func generateColorFromString(_ string: String) -> Color {
        let hash = abs(string.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
    
    // MARK: - Data Loading
    
    /// Load budget data from the development store and group by category
    /// - Parameters:
    ///   - developmentStore: The budget development store
    ///   - scenarioId: The scenario ID to load data for
    func loadData(from developmentStore: BudgetDevelopmentStoreV2, scenarioId: String) async {
        guard !scenarioId.isEmpty else {
            categories = []
            return
        }
        
        isLoading = true
        error = nil
        
        // Fetch budget items with spent amounts
        let items = await developmentStore.loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId: scenarioId)
        
        // Filter out folders and group by category
        let nonFolderItems = items.filter { !$0.isFolder }
        
        // Group items by category
        let grouped = Dictionary(grouping: nonFolderItems) { $0.category }
        
        // Convert to BouquetCategoryData
        var categoryDataList: [BouquetCategoryData] = []
        
        for (categoryName, categoryItems) in grouped {
            // Skip empty category names
            guard !categoryName.isEmpty else { continue }
            
            let totalBudgeted = categoryItems.reduce(0) { $0 + $1.budgeted }
            let totalSpent = categoryItems.reduce(0) { $0 + $1.spent }
            
            // Only include categories with budget items that have allocations
            guard totalBudgeted > 0 || totalSpent > 0 else { continue }
            
            let categoryData = BouquetCategoryData(
                id: categoryName,
                categoryName: categoryName,
                totalBudgeted: totalBudgeted,
                totalSpent: totalSpent,
                itemCount: categoryItems.count,
                color: colorForCategory(categoryName)
            )
            
            categoryDataList.append(categoryData)
        }
        
        // Sort by total budgeted amount (largest first)
        categories = categoryDataList.sorted { $0.totalBudgeted > $1.totalBudgeted }
        isLoading = false
    }
    
    /// Load data using BudgetOverviewItem array directly (for testing or alternative data sources)
    func loadData(from items: [BudgetOverviewItem]) {
        // Filter out folders and group by category
        let nonFolderItems = items.filter { !$0.isFolder }
        
        // Group items by category
        let grouped = Dictionary(grouping: nonFolderItems) { $0.category }
        
        // Convert to BouquetCategoryData
        var categoryDataList: [BouquetCategoryData] = []
        
        for (categoryName, categoryItems) in grouped {
            guard !categoryName.isEmpty else { continue }
            
            let totalBudgeted = categoryItems.reduce(0) { $0 + $1.budgeted }
            let totalSpent = categoryItems.reduce(0) { $0 + $1.spent }
            
            guard totalBudgeted > 0 || totalSpent > 0 else { continue }
            
            let categoryData = BouquetCategoryData(
                id: categoryName,
                categoryName: categoryName,
                totalBudgeted: totalBudgeted,
                totalSpent: totalSpent,
                itemCount: categoryItems.count,
                color: colorForCategory(categoryName)
            )
            
            categoryDataList.append(categoryData)
        }
        
        categories = categoryDataList.sorted { $0.totalBudgeted > $1.totalBudgeted }
    }
    
    /// Clear all data
    func clear() {
        categories = []
        error = nil
    }
}

// MARK: - Preview Helpers

extension BouquetDataProvider {
    /// Create a provider with sample data for previews
    static func preview() -> BouquetDataProvider {
        let provider = BouquetDataProvider()
        provider.categories = [
            BouquetCategoryData(
                id: "venue",
                categoryName: "Venue & Catering",
                totalBudgeted: 15000,
                totalSpent: 15000,
                itemCount: 3,
                color: Color.fromHex("#f43f5e")
            ),
            BouquetCategoryData(
                id: "photography",
                categoryName: "Photography & Video",
                totalBudgeted: 6000,
                totalSpent: 6500,
                itemCount: 2,
                color: Color.fromHex("#a855f7")
            ),
            BouquetCategoryData(
                id: "attire",
                categoryName: "Attire & Beauty",
                totalBudgeted: 5500,
                totalSpent: 4200,
                itemCount: 4,
                color: Color.fromHex("#ec4899")
            ),
            BouquetCategoryData(
                id: "flowers",
                categoryName: "Flowers & Decor",
                totalBudgeted: 4500,
                totalSpent: 2250,
                itemCount: 2,
                color: Color.fromHex("#f59e0b")
            ),
            BouquetCategoryData(
                id: "entertainment",
                categoryName: "Entertainment",
                totalBudgeted: 3500,
                totalSpent: 3500,
                itemCount: 1,
                color: Color.fromHex("#3b82f6")
            ),
            BouquetCategoryData(
                id: "stationery",
                categoryName: "Stationery",
                totalBudgeted: 2500,
                totalSpent: 2300,
                itemCount: 3,
                color: Color.fromHex("#10b981")
            ),
            BouquetCategoryData(
                id: "transportation",
                categoryName: "Transportation",
                totalBudgeted: 2000,
                totalSpent: 1800,
                itemCount: 2,
                color: Color.fromHex("#6366f1")
            ),
            BouquetCategoryData(
                id: "cake",
                categoryName: "Wedding Cake",
                totalBudgeted: 1500,
                totalSpent: 1200,
                itemCount: 1,
                color: Color.fromHex("#f43f5e")
            )
        ]
        return provider
    }
}
