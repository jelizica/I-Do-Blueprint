//
//  EditCategoryView.swift
//  I Do Blueprint
//
//  Form view for editing an existing budget category
//

import SwiftUI

struct EditCategoryView: View {
    let category: BudgetCategory
    @ObservedObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var categoryName: String
    @State private var description: String
    @State private var allocatedAmount: String
    @State private var selectedColor: Color
    @State private var typicalPercentage: String

    init(category: BudgetCategory, budgetStore: BudgetStoreV2) {
        self.category = category
        self.budgetStore = budgetStore
        _categoryName = State(initialValue: category.categoryName)
        _description = State(initialValue: category.description ?? "")
        _allocatedAmount = State(initialValue: String(category.allocatedAmount))
        _selectedColor = State(initialValue: AppColors.Budget.allocated)
        _typicalPercentage = State(initialValue: String(category.typicalPercentage ?? 0.0))
    }
    
    // MARK: - Proportional Modal Sizing
    
    private let minWidth: CGFloat = 400
    private let maxWidth: CGFloat = 600
    private let minHeight: CGFloat = 400
    private let maxHeight: CGFloat = 700
    private let windowChromeBuffer: CGFloat = 40
    
    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        // Use 60% of parent width and 75% of parent height (minus chrome buffer), clamped to min/max bounds
        let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
        let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
        return CGSize(width: targetWidth, height: targetHeight)
    }

    private let predefinedColors: [Color] = [
        AppColors.Budget.allocated,
        AppColors.Budget.income,
        AppColors.Budget.expense,
        AppColors.Budget.pending,
        .purple,
        .pink,
        .yellow,
        .cyan,
        .mint,
        .indigo,
        .brown,
        .gray
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $categoryName)
                    TextField("Description (optional)", text: $description)
                }

                Section("Budget Information") {
                    HStack {
                        Text("Allocated Amount")
                        Spacer()
                        TextField("$0.00", text: $allocatedAmount)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Typical Percentage")
                        Spacer()
                        TextField("0%", text: $typicalPercentage)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Appearance") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(predefinedColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        updateCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
    }

    private func updateCategory() {
        guard !categoryName.isEmpty else { return }

        var updatedCategory = category
        updatedCategory.categoryName = categoryName
        updatedCategory.description = description.isEmpty ? nil : description
        updatedCategory.allocatedAmount = Double(allocatedAmount) ?? 0
        updatedCategory.typicalPercentage = Double(typicalPercentage)

        Task {
            do {
                _ = try await budgetStore.categoryStore.updateCategory(updatedCategory)
                dismiss()
            } catch {
                AppLogger.ui.error("Failed to update category", error: error)
            }
        }
    }
}
