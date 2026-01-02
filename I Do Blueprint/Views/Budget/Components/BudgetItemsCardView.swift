// BudgetItemsCardView.swift
// I Do Blueprint
//
// Card-based budget item editor for compact window mode
// Replaces the 10-column table with vertically stacked editable cards

import SwiftUI

struct BudgetItemsCardView: View {
    @Binding var budgetItems: [BudgetItem]
    @Binding var newCategoryNames: [String: String]
    @Binding var newSubcategoryNames: [String: String]
    @Binding var newEventNames: [String: String]

    let budgetStore: BudgetStoreV2
    let selectedTaxRate: Double
    let currentScenarioId: String?
    let coupleId: String

    let onAddItem: () -> Void
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String, FolderRowView.DeleteOption?) -> Void
    let onAddCategory: (String, String) async -> Void
    let onAddSubcategory: (String, String) async -> Void
    let onAddEvent: (String, String) -> Void
    let onAddFolder: (String, String?) -> Void
    let responsibleOptions: [String]
    
    // Folder support
    @State private var showingCreateFolder = false
    @State private var newFolderName = ""
    @State private var selectedParentFolder: String?
    
    // Expanded items for editing
    @State private var expandedItemIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Action buttons
            actionButtons
            
            if budgetItems.isEmpty {
                emptyStateView
            } else {
                itemsList
            }
        }
        .padding(Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(isPresented: $showingCreateFolder) {
            createFolderSheet
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack {
            Button(action: { showingCreateFolder = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus")
                    Text("Add Folder")
                }
                .font(.subheadline)
            }
            .buttonStyle(.bordered)
            
            Spacer()

            Button(action: onAddItem) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add Item")
                }
                .font(.subheadline)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Items List
    
    private var itemsList: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                if let items = groupedItems[category] {
                    categorySection(category: category, items: items)
                }
            }
        }
    }
    
    // MARK: - Grouped Items
    
    private var groupedItems: [String: [BudgetItem]] {
        Dictionary(grouping: budgetItems.filter { !$0.isFolder }) { item in
            item.category.isEmpty ? "Uncategorized" : item.category
        }
    }
    
    // MARK: - Category Section
    
    @ViewBuilder
    private func categorySection(category: String, items: [BudgetItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            categoryHeader(category: category, items: items)
            
            ForEach(items) { item in
                BudgetItemCard(
                    item: item,
                    isExpanded: expandedItemIds.contains(item.id),
                    categories: parentCategoryNames,
                    subcategories: subcategoryNames(for: item.category),
                    taxRates: budgetStore.taxRates,
                    responsibleOptions: responsibleOptions,
                    onToggleExpand: { toggleExpand(item.id) },
                    onUpdateItem: onUpdateItem,
                    onRemoveItem: { onRemoveItem(item.id, nil) }
                )
            }
        }
    }
    
    private func categoryHeader(category: String, items: [BudgetItem]) -> some View {
        let total = items.reduce(0.0) { $0 + $1.vendorEstimateWithTax }
        
        return HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(AppColors.Budget.allocated)
            Text(category)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("$\(String(format: "%.0f", total))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private func toggleExpand(_ itemId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedItemIds.contains(itemId) {
                expandedItemIds.remove(itemId)
            } else {
                expandedItemIds.insert(itemId)
            }
        }
    }
    
    // MARK: - Category Helpers
    
    private var parentCategoryNames: [String] {
        budgetStore.categoryStore.categories
            .filter { $0.parentCategoryId == nil }
            .map { $0.categoryName }
            .sorted()
    }
    
    private func subcategoryNames(for categoryName: String) -> [String] {
        guard let parentCategory = budgetStore.categoryStore.categories.first(where: {
            $0.categoryName == categoryName && $0.parentCategoryId == nil
        }) else {
            return []
        }
        
        return budgetStore.categoryStore.categories
            .filter { $0.parentCategoryId == parentCategory.id }
            .map { $0.categoryName }
            .sorted()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No budget items yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Tap 'Add Item' to start building your budget")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
    
    // MARK: - Folder Creation Sheet
    
    private var createFolderSheet: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $newFolderName)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Parent Folder", selection: $selectedParentFolder) {
                        Text("Root Level").tag(nil as String?)
                        ForEach(budgetItems.filter { $0.isFolder }) { folder in
                            Text(folder.itemName).tag(folder.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Create Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCreateFolder = false
                        newFolderName = ""
                        selectedParentFolder = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createFolder()
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 400, height: 250)
    }
    
    private func createFolder() {
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        onAddFolder(trimmedName, selectedParentFolder)
        showingCreateFolder = false
        newFolderName = ""
        selectedParentFolder = nil
    }
}

// MARK: - Budget Item Card

struct BudgetItemCard: View {
    let item: BudgetItem
    let isExpanded: Bool
    let categories: [String]
    let subcategories: [String]
    let taxRates: [TaxInfo]
    let responsibleOptions: [String]
    let onToggleExpand: () -> Void
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsedView
            
            if isExpanded {
                expandedView
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Collapsed View
    
    private var collapsedView: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.itemName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    if let subcategory = item.subcategory, !subcategory.isEmpty {
                        Text(subcategory)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.0f", item.vendorEstimateWithTax))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if item.taxRate > 0 {
                        Text("incl. tax")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Expanded View
    
    private var expandedView: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, Spacing.sm)
            
            VStack(spacing: Spacing.sm) {
                categoryRow
                estimateRow
                responsibleRow
                notesRow
                deleteRow
            }
            .padding(Spacing.sm)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
    }
    
    // MARK: - Category Row
    
    private var categoryRow: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                categoryPicker
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Subcategory")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                subcategoryPicker
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var categoryPicker: some View {
        let currentCategory = item.category
        return Picker("", selection: Binding(
            get: { currentCategory },
            set: { onUpdateItem(item.id, "category", $0) }
        )) {
            ForEach(categories, id: \.self) { cat in
                Text(cat).tag(cat)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
    
    private var subcategoryPicker: some View {
        let currentSubcategory = item.subcategory ?? ""
        return Picker("", selection: Binding(
            get: { currentSubcategory },
            set: { onUpdateItem(item.id, "subcategory", $0) }
        )) {
            ForEach(subcategories, id: \.self) { sub in
                Text(sub).tag(sub)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
    
    // MARK: - Estimate Row
    
    private var estimateRow: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimate (No Tax)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                estimateField
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tax Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                taxRatePicker
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var estimateField: some View {
        let currentEstimate = item.vendorEstimateWithoutTax
        return TextField("0", value: Binding(
            get: { currentEstimate },
            set: { onUpdateItem(item.id, "vendorEstimateWithoutTax", $0) }
        ), format: .number)
        .textFieldStyle(.roundedBorder)
        .font(.subheadline)
    }
    
    private var taxRatePicker: some View {
        let currentTaxRate = item.taxRate
        return Picker("", selection: Binding(
            get: { currentTaxRate },
            set: { onUpdateItem(item.id, "taxRate", $0) }
        )) {
            ForEach(taxRates, id: \.id) { rate in
                Text("\(rate.region)")
                    .tag(rate.taxRate)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
    
    // MARK: - Responsible Row
    
    private var responsibleRow: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Responsible")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                responsiblePicker
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.eventIds?.joined(separator: ", ") ?? "None")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var responsiblePicker: some View {
        let currentResponsible = item.personResponsible ?? responsibleOptions.first ?? ""
        return Picker("", selection: Binding(
            get: { currentResponsible },
            set: { onUpdateItem(item.id, "personResponsible", $0) }
        )) {
            ForEach(responsibleOptions, id: \.self) { person in
                Text(person).tag(person)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
    
    // MARK: - Notes Row
    
    private var notesRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
                .font(.caption)
                .foregroundColor(.secondary)
            
            notesField
        }
    }
    
    private var notesField: some View {
        let currentNotes = item.notes ?? ""
        return TextField("Add notes...", text: Binding(
            get: { currentNotes },
            set: { onUpdateItem(item.id, "notes", $0) }
        ))
        .textFieldStyle(.roundedBorder)
        .font(.subheadline)
    }
    
    // MARK: - Delete Row
    
    private var deleteRow: some View {
        HStack {
            Spacer()
            Button(role: .destructive, action: onRemoveItem) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }
}
