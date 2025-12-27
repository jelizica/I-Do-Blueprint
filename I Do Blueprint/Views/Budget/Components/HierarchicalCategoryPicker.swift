//
//  HierarchicalCategoryPicker.swift
//  I Do Blueprint
//
//  Hierarchical category picker that shows top-level categories first,
//  then displays subcategories on hover
//

import SwiftUI

struct HierarchicalCategoryPicker: View {
    let categories: [BudgetCategory]
    @Binding var selectedCategoryId: UUID?
    
    private let logger = AppLogger.ui
    
    // Computed properties to organize categories
    private var topLevelCategories: [BudgetCategory] {
        categories.filter { $0.parentCategoryId == nil }
            .sorted { $0.categoryName < $1.categoryName }
    }
    
    private func subcategories(for parentId: UUID) -> [BudgetCategory] {
        categories.filter { $0.parentCategoryId == parentId }
            .sorted { $0.categoryName < $1.categoryName }
    }
    
    
    
    private func categoryName(for id: UUID?) -> String {
        guard let id = id,
              let category = categories.first(where: { $0.id == id }) else {
            return "Select Category"
        }
        
        // If it's a subcategory, show parent > child format
        if let parentId = category.parentCategoryId,
           let parent = categories.first(where: { $0.id == parentId }) {
            return "\(parent.categoryName) > \(category.categoryName)"
        }
        
        return category.categoryName
    }
    
    var body: some View {
        Menu {
            // "Select Category" option
            Button {
                selectedCategoryId = nil
            } label: {
                HStack {
                    Text("Select Category")
                    if selectedCategoryId == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            // Top-level categories
            ForEach(topLevelCategories) { category in
                categoryMenuItem(category)
            }
        } label: {
            HStack {
                Text(categoryName(for: selectedCategoryId))
                    .foregroundColor(selectedCategoryId == nil ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .help("Select a budget category")
    }
    
    @ViewBuilder
    private func categoryMenuItem(_ category: BudgetCategory) -> some View {
        let subs = subcategories(for: category.id)
        
        if subs.isEmpty {
            // Leaf category - directly selectable
            Button {
                selectedCategoryId = category.id
                logger.info("Selected category: \(category.categoryName)")
            } label: {
                HStack {
                    Text(category.categoryName)
                    Spacer()
                    if selectedCategoryId == category.id {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } else {
            // Parent category with subcategories
            Menu {
                // Option to select the parent category itself
                Button {
                    selectedCategoryId = category.id
                    logger.info("Selected parent category: \(category.categoryName)")
                } label: {
                    HStack {
                        Text(category.categoryName)
                        Text("(All)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if selectedCategoryId == category.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                // Subcategories
                ForEach(subs) { subcategory in
                    Button {
                        selectedCategoryId = subcategory.id
                        logger.info("Selected subcategory: \(subcategory.categoryName) under \(category.categoryName)")
                    } label: {
                        HStack {
                            Text(subcategory.categoryName)
                            Spacer()
                            if selectedCategoryId == subcategory.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(category.categoryName)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Hierarchical Category Picker") {
    struct PreviewWrapper: View {
        @State private var selectedCategoryId: UUID?
        
        let sampleCategories: [BudgetCategory] = {
            let venueId = UUID()
            let cateringId = UUID()
            let photographyId = UUID()
            
            return [
                // Top-level categories
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
                    createdAt: Date()
                ),
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Desserts",
                    parentCategoryId: cateringId,
                    allocatedAmount: 2000,
                    spentAmount: 500,
                    priorityLevel: 2,
                    isEssential: false,
                    forecastedAmount: 2000,
                    confidenceLevel: 0.75,
                    lockedAllocation: false,
                    createdAt: Date()
                ),
                BudgetCategory(
                    id: UUID(),
                    coupleId: UUID(),
                    categoryName: "Beverages",
                    parentCategoryId: cateringId,
                    allocatedAmount: 2000,
                    spentAmount: 0,
                    priorityLevel: 2,
                    isEssential: true,
                    forecastedAmount: 2000,
                    confidenceLevel: 0.8,
                    lockedAllocation: false,
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
                    createdAt: Date()
                )
            ]
        }()
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Hierarchical Category Picker")
                    .font(.title)
                
                HierarchicalCategoryPicker(
                    categories: sampleCategories,
                    selectedCategoryId: $selectedCategoryId
                )
                
                if let selectedId = selectedCategoryId,
                   let category = sampleCategories.first(where: { $0.id == selectedId }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Category:")
                            .font(.headline)
                        
                        if let parentId = category.parentCategoryId,
                           let parent = sampleCategories.first(where: { $0.id == parentId }) {
                            Text("\(parent.categoryName) > \(category.categoryName)")
                                .font(.body)
                        } else {
                            Text(category.categoryName)
                                .font(.body)
                        }
                        
                        Text("Allocated: $\(category.allocatedAmount, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Text("No category selected")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
            .frame(width: 500)
        }
    }
    
    return PreviewWrapper()
}
