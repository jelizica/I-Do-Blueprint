//
//  AddCategoryView.swift
//  I Do Blueprint
//
//  Form view for adding a new budget category
//

import SwiftUI

struct AddCategoryView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @Environment(\.dismiss) private var dismiss

    @State private var categoryName = ""
    @State private var description = ""
    @State private var allocatedAmount = ""
    @State private var selectedColor = AppColors.Budget.allocated
    @State private var typicalPercentage = ""
    @State private var parentCategory: BudgetCategory?

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
                CategoryDetailsSection(
                    categoryName: $categoryName,
                    description: $description
                )

                BudgetInformationSection(
                    allocatedAmount: $allocatedAmount,
                    typicalPercentage: $typicalPercentage
                )

                CategoryOrganizationSection(
                    parentCategory: $parentCategory,
                    availableParents: budgetStore.parentCategories
                )

                CategoryAppearanceSection(
                    selectedColor: $selectedColor,
                    predefinedColors: predefinedColors
                )
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }

    private func saveCategory() {
        guard !categoryName.isEmpty else { return }

        guard let coupleId = SessionManager.shared.getTenantId() else {
            return
        }

        let category = BudgetCategory(
            id: UUID(),
            coupleId: coupleId,
            categoryName: categoryName,
            parentCategoryId: parentCategory?.id,
            allocatedAmount: Double(allocatedAmount) ?? 0,
            spentAmount: 0.0,
            typicalPercentage: Double(typicalPercentage),
            priorityLevel: 1,
            isEssential: false,
            notes: description.isEmpty ? nil : description,
            forecastedAmount: Double(allocatedAmount) ?? 0,
            confidenceLevel: 0.8,
            lockedAllocation: false,
            description: description.isEmpty ? nil : description,
            createdAt: Date(),
            updatedAt: nil)

        Task {
            do {
                _ = try await budgetStore.categoryStore.addCategory(category)
                dismiss()
            } catch {
                AppLogger.ui.error("Failed to add category", error: error)
            }
        }
    }
}

// MARK: - Form Sections

private struct CategoryDetailsSection: View {
    @Binding var categoryName: String
    @Binding var description: String

    var body: some View {
        Section("Category Details") {
            TextField("Category Name", text: $categoryName)
            TextField("Description (optional)", text: $description)
        }
    }
}

private struct BudgetInformationSection: View {
    @Binding var allocatedAmount: String
    @Binding var typicalPercentage: String

    var body: some View {
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
    }
}

private struct CategoryOrganizationSection: View {
    @Binding var parentCategory: BudgetCategory?
    let availableParents: [BudgetCategory]

    var body: some View {
        Section("Organization") {
            Picker("Parent Category", selection: $parentCategory) {
                Text("None (Top Level)").tag(nil as BudgetCategory?)
                ForEach(availableParents, id: \.id) { category in
                    Text(category.categoryName).tag(category as BudgetCategory?)
                }
            }
        }
    }
}

private struct CategoryAppearanceSection: View {
    @Binding var selectedColor: Color
    let predefinedColors: [Color]

    var body: some View {
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
}
