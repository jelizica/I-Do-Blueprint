//
//  BudgetCategoriesSettingsView.swift
//  I Do Blueprint
//
//  Settings view for managing budget categories and subcategories
//

import SwiftUI

struct BudgetCategoriesSettingsView: View {
    @Environment(\.appStores) private var appStores
    @State private var showingAddCategory = false
    @State private var editingCategory: BudgetCategory?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: BudgetCategory?
    
    // Batch delete state
    @State private var selectionMode = false
    @State private var selectedCategories: Set<UUID> = []
    @State private var showingBatchDeleteAlert = false
    @State private var showingBatchResultAlert = false
    @State private var batchDeleteResult: BatchDeleteResult?
    
    private var budgetStore: BudgetStoreV2 {
        appStores.budget
    }
    
    private var filteredCategories: [BudgetCategory] {
        let categories = budgetStore.categoryStore.categories
        
        let searchFiltered = searchText.isEmpty ? categories : categories.filter { category in
            category.categoryName.localizedCaseInsensitiveContains(searchText)
        }
        
        return searchFiltered.sorted { $0.categoryName < $1.categoryName }
    }
    
    private var parentCategories: [BudgetCategory] {
        filteredCategories.filter { $0.parentCategoryId == nil }
    }
    
    private func subcategories(for parent: BudgetCategory) -> [BudgetCategory] {
        filteredCategories.filter { $0.parentCategoryId == parent.id }
    }
    
    // Batch delete helpers
    private var selectedDeletableCount: Int {
        selectedCategories.filter { id in
            budgetStore.categoryStore.categories.first(where: { $0.id == id })
                .map { budgetStore.categoryStore.canDeleteCategory($0) } ?? false
        }.count
    }
    
    private var selectedBlockedCount: Int {
        selectedCategories.count - selectedDeletableCount
    }
    
    private var hasSelection: Bool {
        !selectedCategories.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Budget Categories")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Manage your budget categories and subcategories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 16) {
                // Header with search/selection controls
                HStack {
                    if selectionMode {
                        // Selection mode controls
                        Button("Cancel") {
                            selectionMode = false
                            selectedCategories.removeAll()
                        }
                        
                        Spacer()
                        
                        if hasSelection {
                            Text("\(selectedCategories.count) selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Delete Selected") {
                                showingBatchDeleteAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    } else {
                        // Normal mode controls
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search categories...", text: $searchText)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Select") {
                            selectionMode = true
                        }
                        
                        Button(action: { showingAddCategory = true }) {
                            Label("Add Category", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Categories List
                if filteredCategories.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Categories" : "No Results",
                        systemImage: searchText.isEmpty ? "folder" : "magnifyingglass",
                        description: Text(searchText.isEmpty ?
                            "Create your first budget category to start organizing expenses" :
                            "Try adjusting your search terms"))
                        .frame(maxHeight: 400)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(parentCategories, id: \.id) { parentCategory in
                                SettingsCategorySection(
                                    parentCategory: parentCategory,
                                    subcategories: subcategories(for: parentCategory),
                                    selectionMode: selectionMode,
                                    selectedCategories: $selectedCategories,
                                    onEdit: { category in
                                        editingCategory = category
                                    },
                                    onDelete: { category in
                                        categoryToDelete = category
                                        showingDeleteAlert = true
                                    })
                            }
                        }
                        .padding(.vertical, Spacing.sm)
                    }
                    .frame(maxHeight: 500)
                }
                
                // Info text
                Text("Categories created here will be available in the Budget section for expense tracking and allocation.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, Spacing.sm)
            }
        }
        .task {
            await budgetStore.loadBudgetData(force: false)
            // Load dependency information for delete validation
            await budgetStore.categoryStore.loadCategoryDependencies()
        }
        .sheet(isPresented: $showingAddCategory) {
            SettingsAddCategoryView(budgetStore: budgetStore)
        }
        .sheet(item: $editingCategory) { category in
            SettingsEditCategoryView(category: category, budgetStore: budgetStore)
        }
        .alert("Delete Category", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            if let category = categoryToDelete, budgetStore.categoryStore.canDeleteCategory(category) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? await budgetStore.categoryStore.deleteCategory(id: category.id)
                        // Reload dependencies after deletion
                        await budgetStore.categoryStore.loadCategoryDependencies()
                    }
                }
            }
        } message: {
            if let category = categoryToDelete {
                if let warning = budgetStore.categoryStore.getDependencyWarning(for: category) {
                    Text("Cannot delete '\(category.categoryName)':\n\n\(warning)\n\nPlease remove these dependencies first.")
                } else {
                    Text("Are you sure you want to delete '\(category.categoryName)'? This action cannot be undone.")
                }
            }
        }
        .alert("Delete \(selectedCategories.count) Categories", isPresented: $showingBatchDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let result = await budgetStore.batchDeleteCategories(ids: Array(selectedCategories))
                    batchDeleteResult = result
                    
                    // Reload dependencies after batch deletion
                    await budgetStore.categoryStore.loadCategoryDependencies()
                    
                    selectedCategories.removeAll()
                    selectionMode = false
                    
                    // Show result if there were any skipped
                    if result.failureCount > 0 {
                        showingBatchResultAlert = true
                    }
                }
            }
        } message: {
            if selectedDeletableCount == selectedCategories.count {
                Text("Are you sure you want to delete \(selectedCategories.count) categories? This action cannot be undone.")
            } else {
                Text("\(selectedDeletableCount) of \(selectedCategories.count) selected categories can be deleted.\n\n\(selectedBlockedCount) categories have dependencies and will be skipped.\n\nDo you want to continue?")
            }
        }
        .alert("Batch Delete Results", isPresented: $showingBatchResultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let result = batchDeleteResult {
                if result.successCount > 0 && result.failureCount > 0 {
                    Text("Successfully deleted \(result.successCount) of \(result.totalAttempted) categories.\n\n\(result.failureCount) categories were skipped due to dependencies (expenses, budget items, tasks, vendors, or subcategories).")
                } else if result.failureCount > 0 {
                    Text("Could not delete any categories. All \(result.failureCount) selected categories have dependencies that must be removed first.")
                }
            }
        }
    }
}

// MARK: - Settings Category Section

struct SettingsCategorySection: View {
    let parentCategory: BudgetCategory
    let subcategories: [BudgetCategory]
    let selectionMode: Bool
    @Binding var selectedCategories: Set<UUID>
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void
    
    @State private var isExpanded = true
    @Environment(\.appStores) private var appStores
    
    private var budgetStore: BudgetStoreV2 {
        appStores.budget
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Parent category (folder)
            SettingsFolderRow(
                category: parentCategory,
                subcategoryCount: subcategories.count,
                isExpanded: $isExpanded,
                selectionMode: selectionMode,
                selectedCategories: $selectedCategories,
                budgetStore: budgetStore,
                onEdit: onEdit,
                onDelete: onDelete)
            
            // Subcategories
            if isExpanded, !subcategories.isEmpty {
                ForEach(subcategories, id: \.id) { subcategory in
                    SettingsCategoryRow(
                        category: subcategory,
                        selectionMode: selectionMode,
                        selectedCategories: $selectedCategories,
                        budgetStore: budgetStore,
                        onEdit: onEdit,
                        onDelete: onDelete)
                        .padding(.leading, Spacing.xl)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Settings Folder Row

struct SettingsFolderRow: View {
    let category: BudgetCategory
    let subcategoryCount: Int
    @Binding var isExpanded: Bool
    let selectionMode: Bool
    @Binding var selectedCategories: Set<UUID>
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void
    
    private var isSelected: Bool {
        selectedCategories.contains(category.id)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox (in selection mode)
            if selectionMode {
                Button(action: {
                    if isSelected {
                        selectedCategories.remove(category.id)
                    } else {
                        selectedCategories.insert(category.id)
                    }
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .font(.body)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Expansion chevron
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 12)
            
            // Folder icon
            Image(systemName: "folder.fill")
                .font(.body)
                .foregroundColor(Color(hex: category.color) ?? AppColors.Budget.allocated)
            
            // Category details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(category.categoryName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("(\(subcategoryCount) subcategories)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = category.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Dependency badges
                if let deps = budgetStore.categoryStore.categoryDependencies[category.id] {
                    HStack(spacing: 8) {
                        if deps.expenseCount > 0 {
                            Label("\(deps.expenseCount) expense\(deps.expenseCount == 1 ? "" : "s")", 
                                  systemImage: "dollarsign.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if deps.budgetItemCount > 0 {
                            Label("\(deps.budgetItemCount) budget item\(deps.budgetItemCount == 1 ? "" : "s")", 
                                  systemImage: "list.bullet")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        if deps.subcategoryCount > 0 {
                            Label("\(deps.subcategoryCount) subcategor\(deps.subcategoryCount == 1 ? "y" : "ies")", 
                                  systemImage: "folder.fill")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                        if deps.taskCount > 0 {
                            Label("\(deps.taskCount) task\(deps.taskCount == 1 ? "" : "s")", 
                                  systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        if deps.vendorCount > 0 {
                            Label("\(deps.vendorCount) vendor\(deps.vendorCount == 1 ? "" : "s")", 
                                  systemImage: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.pink)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions menu (hidden in selection mode)
            if !selectionMode {
                Menu {
                    Button("Edit") {
                        onEdit(category)
                    }
                    
                    Button("Add Subcategory") {
                        // TODO: Add subcategory with this as parent
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        onDelete(category)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .highPriorityGesture(TapGesture())
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            if !selectionMode {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Settings Category Row

struct SettingsCategoryRow: View {
    let category: BudgetCategory
    let selectionMode: Bool
    @Binding var selectedCategories: Set<UUID>
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void
    
    private var isSelected: Bool {
        selectedCategories.contains(category.id)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox (in selection mode)
            if selectionMode {
                Button(action: {
                    if isSelected {
                        selectedCategories.remove(category.id)
                    } else {
                        selectedCategories.insert(category.id)
                    }
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Subcategory icon
            Image(systemName: "doc.text.fill")
                .font(.caption)
                .foregroundColor(Color(hex: category.color) ?? AppColors.Budget.allocated)
                .frame(width: 12)
            
            // Category details
            VStack(alignment: .leading, spacing: 2) {
                Text(category.categoryName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let description = category.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Dependency badges
                if let deps = budgetStore.categoryStore.categoryDependencies[category.id] {
                    HStack(spacing: 8) {
                        if deps.expenseCount > 0 {
                            Label("\(deps.expenseCount) expense\(deps.expenseCount == 1 ? "" : "s")", 
                                  systemImage: "dollarsign.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if deps.budgetItemCount > 0 {
                            Label("\(deps.budgetItemCount) budget item\(deps.budgetItemCount == 1 ? "" : "s")", 
                                  systemImage: "list.bullet")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        if deps.taskCount > 0 {
                            Label("\(deps.taskCount) task\(deps.taskCount == 1 ? "" : "s")", 
                                  systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        if deps.vendorCount > 0 {
                            Label("\(deps.vendorCount) vendor\(deps.vendorCount == 1 ? "" : "s")", 
                                  systemImage: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.pink)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions menu (hidden in selection mode)
            if !selectionMode {
                Menu {
                    Button("Edit") {
                        onEdit(category)
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        onDelete(category)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Settings Add Category View

struct SettingsAddCategoryView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName = ""
    @State private var description = ""
    @State private var selectedColor = AppColors.Budget.allocated
    @State private var parentCategory: BudgetCategory?
    
    private let predefinedColors: [Color] = [
        AppColors.Budget.allocated, AppColors.Budget.income, AppColors.Budget.expense, 
        AppColors.Budget.pending, .purple, .pink, .yellow, .cyan, .mint, .indigo, .brown, .gray
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $categoryName)
                    TextField("Description (optional)", text: $description)
                }
                
                Section("Organization") {
                    Picker("Parent Category", selection: $parentCategory) {
                        Text("None (Top Level)").tag(nil as BudgetCategory?)
                        ForEach(budgetStore.parentCategories, id: \.id) { category in
                            Text(category.categoryName).tag(category as BudgetCategory?)
                        }
                    }
                    
                    if parentCategory != nil {
                        Text("This will be created as a subcategory")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            allocatedAmount: 0, // Settings doesn't set allocation amounts
            spentAmount: 0.0,
            typicalPercentage: nil,
            priorityLevel: 1,
            isEssential: false,
            notes: description.isEmpty ? nil : description,
            forecastedAmount: 0,
            confidenceLevel: 0.8,
            lockedAllocation: false,
            description: description.isEmpty ? nil : description,
            createdAt: Date(),
            updatedAt: nil)
        
        Task {
            try? await budgetStore.categoryStore.addCategory(category)
            dismiss()
        }
    }
}

// MARK: - Settings Edit Category View

struct SettingsEditCategoryView: View {
    let category: BudgetCategory
    @ObservedObject var budgetStore: BudgetStoreV2
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName: String
    @State private var description: String
    @State private var selectedColor: Color
    
    init(category: BudgetCategory, budgetStore: BudgetStoreV2) {
        self.category = category
        self.budgetStore = budgetStore
        _categoryName = State(initialValue: category.categoryName)
        _description = State(initialValue: category.description ?? "")
        _selectedColor = State(initialValue: AppColors.Budget.allocated)
    }
    
    private let predefinedColors: [Color] = [
        AppColors.Budget.allocated, AppColors.Budget.income, AppColors.Budget.expense, 
        AppColors.Budget.pending, .purple, .pink, .yellow, .cyan, .mint, .indigo, .brown, .gray
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $categoryName)
                    TextField("Description (optional)", text: $description)
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
                
                if category.parentCategoryId == nil {
                    Section("Information") {
                        let subcategoryCount = budgetStore.categoryStore.categories.filter { $0.parentCategoryId == category.id }.count
                        HStack {
                            Text("Subcategories")
                            Spacer()
                            Text("\(subcategoryCount)")
                                .foregroundColor(.secondary)
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
    }
    
    private func updateCategory() {
        guard !categoryName.isEmpty else { return }
        
        var updatedCategory = category
        updatedCategory.categoryName = categoryName
        updatedCategory.description = description.isEmpty ? nil : description
        
        Task {
            try? await budgetStore.categoryStore.updateCategory(updatedCategory)
            dismiss()
        }
    }
}

#Preview {
    BudgetCategoriesSettingsView()
        .padding()
        .frame(width: 800, height: 700)
}
