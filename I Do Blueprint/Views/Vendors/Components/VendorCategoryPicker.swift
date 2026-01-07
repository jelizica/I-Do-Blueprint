//
//  VendorCategoryPicker.swift
//  I Do Blueprint
//
//  Category picker for vendors with required category and optional subcategory
//  Uses BudgetCategory hierarchy from CategoryStoreV2
//  Only allows selecting parent categories OR leaf categories (no children)
//

import SwiftUI

struct VendorCategoryPicker: View {
    // MARK: - Properties
    
    let categories: [BudgetCategory]
    @Binding var selectedCategoryId: UUID?
    @Binding var selectedSubcategoryId: UUID?
    
    private let logger = AppLogger.ui
    
    // MARK: - Computed Properties
    
    /// Parent categories (no parent category ID)
    private var parentCategories: [BudgetCategory] {
        categories.filter { $0.parentCategoryId == nil }
            .sorted { $0.categoryName < $1.categoryName }
    }
    
    /// Leaf categories (categories with no children)
    private var leafCategories: [BudgetCategory] {
        categories.filter { category in
            // A leaf category has no children
            !categories.contains { $0.parentCategoryId == category.id }
        }
    }
    
    /// Categories that can be selected as primary category
    /// (parent categories OR leaf categories that have no children)
    private var selectableCategories: [BudgetCategory] {
        // Get parent categories that have children (for subcategory selection)
        let parentsWithChildren = parentCategories.filter { parent in
            categories.contains { $0.parentCategoryId == parent.id }
        }
        
        // Get leaf categories at the top level (no parent, no children)
        let topLevelLeaves = parentCategories.filter { parent in
            !categories.contains { $0.parentCategoryId == parent.id }
        }
        
        // Combine: parents with children + top-level leaves
        return (parentsWithChildren + topLevelLeaves).sorted { $0.categoryName < $1.categoryName }
    }
    
    /// Subcategories for the selected parent category
    private var subcategoriesForSelected: [BudgetCategory] {
        guard let parentId = selectedCategoryId else { return [] }
        return categories.filter { $0.parentCategoryId == parentId }
            .sorted { $0.categoryName < $1.categoryName }
    }
    
    /// Whether the selected category has subcategories
    private var hasSubcategories: Bool {
        !subcategoriesForSelected.isEmpty
    }
    
    /// Get category name for display
    private func categoryName(for id: UUID?) -> String {
        guard let id = id,
              let category = categories.first(where: { $0.id == id }) else {
            return "Select Category"
        }
        return category.categoryName
    }
    
    /// Get full category path for display (Parent > Child)
    private func fullCategoryPath() -> String {
        guard let categoryId = selectedCategoryId,
              let category = categories.first(where: { $0.id == categoryId }) else {
            return "Select Category"
        }
        
        if let subcategoryId = selectedSubcategoryId,
           let subcategory = categories.first(where: { $0.id == subcategoryId }) {
            return "\(category.categoryName) > \(subcategory.categoryName)"
        }
        
        return category.categoryName
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Required Category Picker
            categoryPickerSection
            
            // Optional Subcategory Picker (only shown if parent has children)
            if hasSubcategories {
                subcategoryPickerSection
            }
        }
    }
    
    // MARK: - Category Picker Section
    
    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Text("Category")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text("*")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.statusError)
            }
            
            Menu {
                // Clear selection option
                Button {
                    selectedCategoryId = nil
                    selectedSubcategoryId = nil
                    logger.info("Cleared category selection")
                } label: {
                    HStack {
                        Text("Select Category")
                        if selectedCategoryId == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                // Selectable categories
                ForEach(selectableCategories) { category in
                    Button {
                        // Clear subcategory when changing parent
                        if selectedCategoryId != category.id {
                            selectedSubcategoryId = nil
                        }
                        selectedCategoryId = category.id
                        logger.info("Selected category: \(category.categoryName)")
                    } label: {
                        HStack {
                            // Show folder icon for parents with children
                            if categories.contains(where: { $0.parentCategoryId == category.id }) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(categoryColor(for: category))
                            } else {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(categoryColor(for: category))
                            }
                            
                            Text(category.categoryName)
                            
                            Spacer()
                            
                            if selectedCategoryId == category.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let categoryId = selectedCategoryId,
                       let category = categories.first(where: { $0.id == categoryId }) {
                        // Show color indicator
                        Circle()
                            .fill(categoryColor(for: category))
                            .frame(width: 8, height: 8)
                        
                        Text(category.categoryName)
                            .foregroundColor(SemanticColors.textPrimary)
                    } else {
                        Text("Select Category")
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(Spacing.md)
                .background(glassFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay(fieldBorder)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Subcategory Picker Section
    
    private var subcategoryPickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Text("Subcategory")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text("(Optional)")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            Menu {
                // No subcategory option
                Button {
                    selectedSubcategoryId = nil
                    logger.info("Cleared subcategory selection")
                } label: {
                    HStack {
                        Text("No Subcategory")
                        if selectedSubcategoryId == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                // Subcategories
                ForEach(subcategoriesForSelected) { subcategory in
                    Button {
                        selectedSubcategoryId = subcategory.id
                        logger.info("Selected subcategory: \(subcategory.categoryName)")
                    } label: {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(categoryColor(for: subcategory))
                            
                            Text(subcategory.categoryName)
                            
                            Spacer()
                            
                            if selectedSubcategoryId == subcategory.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let subcategoryId = selectedSubcategoryId,
                       let subcategory = categories.first(where: { $0.id == subcategoryId }) {
                        // Show color indicator
                        Circle()
                            .fill(categoryColor(for: subcategory))
                            .frame(width: 8, height: 8)
                        
                        Text(subcategory.categoryName)
                            .foregroundColor(SemanticColors.textPrimary)
                    } else {
                        Text("Select Subcategory")
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(Spacing.md)
                .background(glassFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay(fieldBorder)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helper Views
    
    private var glassFieldBackground: some View {
        SemanticColors.backgroundPrimary.opacity(0.5)
    }
    
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg)
            .stroke(SemanticColors.borderLight, lineWidth: 1)
    }
    
    // MARK: - Helper Methods
    
    private func categoryColor(for category: BudgetCategory) -> Color {
        // Parse hex color from category
        if let color = Color(hex: category.color) {
            return color
        }
        return SemanticColors.primaryAction
    }
}

// MARK: - Preview

#Preview("Vendor Category Picker") {
    struct PreviewWrapper: View {
        @State private var selectedCategoryId: UUID?
        @State private var selectedSubcategoryId: UUID?
        
        let sampleCategories: [BudgetCategory] = {
            let venueId = UUID()
            let cateringId = UUID()
            let photographyId = UUID()
            let stationeryId = UUID() // Leaf category (no children)
            
            return [
                // Parent categories with children
                BudgetCategory(
                    id: venueId,
                    coupleId: UUID(),
                    categoryName: "Venue",
                    parentCategoryId: nil,
                    allocatedAmount: 10000,
                    spentAmount: 5000,
                    priorityLevel: 1,
                    isEssential: true,
                    forecastedAmount: 10000,
                    confidenceLevel: 0.9,
                    lockedAllocation: false,
                    color: "#3B82F6",
                    createdAt: Date()
                ),
                BudgetCategory(
                    id: cateringId,
                    coupleId: UUID(),
                    categoryName: "Catering",
                    parentCategoryId: nil,
                    allocatedAmount: 15000,
                    spentAmount: 3000,
                    priorityLevel: 1,
                    isEssential: true,
                    forecastedAmount: 15000,
                    confidenceLevel: 0.85,
                    lockedAllocation: false,
                    color: "#10B981",
                    createdAt: Date()
                ),
                BudgetCategory(
                    id: photographyId,
                    coupleId: UUID(),
                    categoryName: "Photography",
                    parentCategoryId: nil,
                    allocatedAmount: 5000,
                    spentAmount: 0,
                    priorityLevel: 2,
                    isEssential: true,
                    forecastedAmount: 5000,
                    confidenceLevel: 0.8,
                    lockedAllocation: false,
                    color: "#8B5CF6",
                    createdAt: Date()
                ),
                // Leaf category (no children)
                BudgetCategory(
                    id: stationeryId,
                    coupleId: UUID(),
                    categoryName: "Stationery",
                    parentCategoryId: nil,
                    allocatedAmount: 1000,
                    spentAmount: 200,
                    priorityLevel: 3,
                    isEssential: false,
                    forecastedAmount: 1000,
                    confidenceLevel: 0.7,
                    lockedAllocation: false,
                    color: "#F59E0B",
                    createdAt: Date()
                ),
                // Subcategories for Venue
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Ceremony Space",
                    parentCategoryId: venueId,
                    allocatedAmount: 3000,
                    spentAmount: 3000,
                    priorityLevel: 1,
                    isEssential: true,
                    forecastedAmount: 3000,
                    confidenceLevel: 1.0,
                    lockedAllocation: true,
                    color: "#3B82F6",
                    createdAt: Date()
                ),
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Reception Space",
                    parentCategoryId: venueId,
                    allocatedAmount: 7000,
                    spentAmount: 2000,
                    priorityLevel: 1,
                    isEssential: true,
                    forecastedAmount: 7000,
                    confidenceLevel: 0.9,
                    lockedAllocation: false,
                    color: "#3B82F6",
                    createdAt: Date()
                ),
                // Subcategories for Catering
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Main Course",
                    parentCategoryId: cateringId,
                    allocatedAmount: 8000,
                    spentAmount: 2000,
                    priorityLevel: 1,
                    isEssential: true,
                    forecastedAmount: 8000,
                    confidenceLevel: 0.85,
                    lockedAllocation: false,
                    color: "#10B981",
                    createdAt: Date()
                ),
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Appetizers",
                    parentCategoryId: cateringId,
                    allocatedAmount: 3000,
                    spentAmount: 500,
                    priorityLevel: 2,
                    isEssential: false,
                    forecastedAmount: 3000,
                    confidenceLevel: 0.8,
                    lockedAllocation: false,
                    color: "#10B981",
                    createdAt: Date()
                ),
                // Subcategories for Photography
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Engagement Photos",
                    parentCategoryId: photographyId,
                    allocatedAmount: 1000,
                    spentAmount: 0,
                    priorityLevel: 3,
                    isEssential: false,
                    forecastedAmount: 1000,
                    confidenceLevel: 0.7,
                    lockedAllocation: false,
                    color: "#8B5CF6",
                    createdAt: Date()
                ),
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Wedding Day",
                    parentCategoryId: photographyId,
                    allocatedAmount: 4000,
                    spentAmount: 0,
                    priorityLevel: 1,
                    isEssential: true,
                    forecastedAmount: 4000,
                    confidenceLevel: 0.85,
                    lockedAllocation: false,
                    color: "#8B5CF6",
                    createdAt: Date()
                )
            ]
        }()
        
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text("Vendor Category Picker")
                    .font(Typography.title2)
                
                VendorCategoryPicker(
                    categories: sampleCategories,
                    selectedCategoryId: $selectedCategoryId,
                    selectedSubcategoryId: $selectedSubcategoryId
                )
                
                Divider()
                
                // Selection display
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Selection:")
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                    
                    if let categoryId = selectedCategoryId,
                       let category = sampleCategories.first(where: { $0.id == categoryId }) {
                        HStack {
                            Text("Category:")
                            Text(category.categoryName)
                                .fontWeight(.medium)
                        }
                        .font(Typography.bodySmall)
                        
                        if let subcategoryId = selectedSubcategoryId,
                           let subcategory = sampleCategories.first(where: { $0.id == subcategoryId }) {
                            HStack {
                                Text("Subcategory:")
                                Text(subcategory.categoryName)
                                    .fontWeight(.medium)
                            }
                            .font(Typography.bodySmall)
                        }
                    } else {
                        Text("No category selected")
                            .font(Typography.bodySmall)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                .padding()
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(CornerRadius.md)
                
                Spacer()
            }
            .padding(Spacing.xl)
            .frame(width: 400, height: 500)
        }
    }
    
    return PreviewWrapper()
}
