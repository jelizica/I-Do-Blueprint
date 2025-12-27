import SwiftUI

struct ExpenseCategoriesView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var showingAddCategory = false
    @State private var editingCategory: BudgetCategory?
    @State private var searchText = ""
    @State private var selectedParentCategory: BudgetCategory?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: BudgetCategory?

    private var filteredCategories: [BudgetCategory] {
        let categories = budgetStore.categories

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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expense Categories")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(filteredCategories.count) categories")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button(action: { showingAddCategory = true }) {
                            Label("Add Category", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search categories...", text: $searchText)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            // Categories List
            if filteredCategories.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Categories" : "No Results",
                    systemImage: searchText.isEmpty ? "folder" : "magnifyingglass",
                    description: Text(searchText.isEmpty ?
                        "Create your first budget category to start organizing expenses" :
                        "Try adjusting your search terms"))
            } else {
                List {
                    ForEach(parentCategories, id: \.id) { parentCategory in
                        CategorySection(
                            parentCategory: parentCategory,
                            subcategories: subcategories(for: parentCategory),
                            budgetStore: budgetStore,
                            onEdit: { category in
                                editingCategory = category
                            },
                            onDelete: { category in
                                categoryToDelete = category
                                showingDeleteAlert = true
                            })
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .task {
            await budgetStore.loadBudgetData(force: true)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(budgetStore: budgetStore)
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category, budgetStore: budgetStore)
        }
        .alert("Delete Category", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    Task {
                        await budgetStore.deleteCategory(id: category.id)
                    }
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text("Are you sure you want to delete '\(category.categoryName)'? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let parentCategory: BudgetCategory
    let subcategories: [BudgetCategory]
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void

    @State private var isExpanded = true

    // Parent categories should only show sum of subcategories (not their own allocated amount)
    private var totalSpent: Double {
        subcategories.reduce(0) { total, subcategory in
            total + budgetStore.spentAmount(for: subcategory.id)
        }
    }

    private var totalBudgeted: Double {
        subcategories.reduce(0) { total, subcategory in
            total + subcategory.allocatedAmount
        }
    }

    var body: some View {
        Section {
            // Parent category (folder) - clickable to expand/collapse
            CategoryFolderRowView(
                category: parentCategory,
                subcategoryCount: subcategories.count,
                totalSpent: totalSpent,
                totalBudgeted: totalBudgeted,
                isExpanded: $isExpanded,
                budgetStore: budgetStore,
                onEdit: onEdit,
                onDelete: onDelete)

            // Subcategories
            if isExpanded, !subcategories.isEmpty {
                ForEach(subcategories, id: \.id) { subcategory in
                    CategoryRowView(
                        category: subcategory,
                        spentAmount: budgetStore.spentAmount(for: subcategory.id),
                        isParent: false,
                        budgetStore: budgetStore,
                        onEdit: onEdit,
                        onDelete: onDelete)
                        .padding(.leading, Spacing.xl)
                }
            }
        }
    }
}

// MARK: - Folder Row (Parent Category)

struct CategoryFolderRowView: View {
    let category: BudgetCategory
    let subcategoryCount: Int
    let totalSpent: Double
    let totalBudgeted: Double
    @Binding var isExpanded: Bool
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void

    private var utilizationPercentage: Double {
        totalBudgeted > 0 ? (totalSpent / totalBudgeted) * 100 : 0
    }

    private var statusColor: Color {
        if utilizationPercentage > 100 {
            AppColors.Budget.overBudget
        } else if utilizationPercentage > 80 {
            AppColors.Budget.pending
        } else {
            AppColors.Budget.underBudget
        }
    }

    var body: some View {
        HStack(spacing: 12) {
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
            VStack(alignment: .leading, spacing: 4) {
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
                
                // Linked budget items count
                let linkedCount = budgetStore.linkedBudgetItemsCount(for: category)
                if linkedCount > 0 {
                    Text("\(linkedCount) linked budget item\(linkedCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                // Budget progress
                if totalBudgeted > 0 {
                    HStack(spacing: 8) {
                        ProgressView(value: min(utilizationPercentage / 100, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: statusColor))
                            .frame(width: 100)

                        Text("\(Int(utilizationPercentage))%")
                            .font(.caption2)
                            .foregroundColor(statusColor)
                            .fontWeight(.medium)
                    }
                }
            }

            Spacer()

            // Budget information (sum of subcategories)
            VStack(alignment: .trailing, spacing: 2) {
                Text(NumberFormatter.currency.string(from: NSNumber(value: totalSpent)) ?? "$0")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)

                Text("of \(NumberFormatter.currency.string(from: NSNumber(value: totalBudgeted)) ?? "$0")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Actions menu (only this part is clickable for editing)
            Menu {
                Button("Edit") {
                    onEdit(category)
                }

                Button("Duplicate") {
                    duplicateCategory()
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
            .highPriorityGesture(TapGesture().onEnded { _ in
                // Intentionally no-op: consumes tap to prevent parent expansion
            })
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            // Toggle expansion when clicking anywhere except the menu
            isExpanded.toggle()
        }
    }
    
    private func duplicateCategory() {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            return
        }
        
        let duplicatedCategory = BudgetCategory(
            id: UUID(),
            coupleId: coupleId,
            categoryName: "Copy of \(category.categoryName)",
            parentCategoryId: category.parentCategoryId,
            allocatedAmount: category.allocatedAmount,
            spentAmount: 0.0, // Reset spent amount for new category
            typicalPercentage: category.typicalPercentage,
            priorityLevel: category.priorityLevel,
            isEssential: category.isEssential,
            notes: category.notes,
            forecastedAmount: category.forecastedAmount,
            confidenceLevel: category.confidenceLevel,
            lockedAllocation: category.lockedAllocation,
            description: category.description,
            createdAt: Date(),
            updatedAt: nil
        )
        
        Task {
            await budgetStore.addCategory(duplicatedCategory)
        }
    }
}

// MARK: - Category Row (Subcategory)

struct CategoryRowView: View {
    let category: BudgetCategory
    let spentAmount: Double
    let isParent: Bool
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void

    private var utilizationPercentage: Double {
        category.allocatedAmount > 0 ? (spentAmount / category.allocatedAmount) * 100 : 0
    }

    private var statusColor: Color {
        if utilizationPercentage > 100 {
            AppColors.Budget.overBudget
        } else if utilizationPercentage > 80 {
            AppColors.Budget.pending
        } else {
            AppColors.Budget.underBudget
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Subcategory icon
            Image(systemName: "doc.text.fill")
                .font(.caption)
                .foregroundColor(Color(hex: category.color) ?? AppColors.Budget.allocated)
                .frame(width: 12)

            // Category details
            VStack(alignment: .leading, spacing: 4) {
                Text(category.categoryName)
                    .font(.caption)
                    .fontWeight(.medium)

                if let description = category.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Linked budget items count
                let linkedCount = budgetStore.linkedBudgetItemsCount(for: category)
                if linkedCount > 0 {
                    Text("\(linkedCount) linked budget item\(linkedCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                // Budget progress
                HStack(spacing: 8) {
                    ProgressView(value: min(utilizationPercentage / 100, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: statusColor))
                        .frame(width: 100)

                    Text("\(Int(utilizationPercentage))%")
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .fontWeight(.medium)
                }
            }

            Spacer()

            // Budget information
            VStack(alignment: .trailing, spacing: 2) {
                Text(NumberFormatter.currency.string(from: NSNumber(value: spentAmount)) ?? "$0")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)

                Text("of \(NumberFormatter.currency.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Actions menu
            Menu {
                Button("Edit") {
                    onEdit(category)
                }

                Button("Duplicate") {
                    duplicateCategory()
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
        .padding(.vertical, Spacing.xs)
        .contextMenu {
            Button("Edit") {
                onEdit(category)
            }

            Button("Delete", role: .destructive) {
                onDelete(category)
            }
        }
    }
    
    private func duplicateCategory() {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            return
        }
        
        let duplicatedCategory = BudgetCategory(
            id: UUID(),
            coupleId: coupleId,
            categoryName: "Copy of \(category.categoryName)",
            parentCategoryId: category.parentCategoryId,
            allocatedAmount: category.allocatedAmount,
            spentAmount: 0.0, // Reset spent amount for new category
            typicalPercentage: category.typicalPercentage,
            priorityLevel: category.priorityLevel,
            isEssential: category.isEssential,
            notes: category.notes,
            forecastedAmount: category.forecastedAmount,
            confidenceLevel: category.confidenceLevel,
            lockedAllocation: category.lockedAllocation,
            description: category.description,
            createdAt: Date(),
            updatedAt: nil
        )
        
        Task {
            await budgetStore.addCategory(duplicatedCategory)
        }
    }
}


// MARK: - Add Category View

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
        AppColors.Budget.allocated, AppColors.Budget.income, AppColors.Budget.expense, AppColors.Budget.pending, .purple, .pink,
        .yellow, .cyan, .mint, .indigo, .brown, .gray
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

                Section("Organization") {
                    Picker("Parent Category", selection: $parentCategory) {
                        Text("None (Top Level)").tag(nil as BudgetCategory?)
                        ForEach(budgetStore.parentCategories, id: \.id) { category in
                            Text(category.categoryName).tag(category as BudgetCategory?)
                        }
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
            await budgetStore.addCategory(category)
            dismiss()
        }
    }
}

// MARK: - Edit Category View

struct EditCategoryView: View {
    let category: BudgetCategory
    @ObservedObject var budgetStore: BudgetStoreV2
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

    private let predefinedColors: [Color] = [
        AppColors.Budget.allocated, AppColors.Budget.income, AppColors.Budget.expense, AppColors.Budget.pending, .purple, .pink,
        .yellow, .cyan, .mint, .indigo, .brown, .gray
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
    }

    private func updateCategory() {
        guard !categoryName.isEmpty else { return }

        var updatedCategory = category
        updatedCategory.categoryName = categoryName
        updatedCategory.description = description.isEmpty ? nil : description
        updatedCategory.allocatedAmount = Double(allocatedAmount) ?? 0
        updatedCategory.typicalPercentage = Double(typicalPercentage)

        Task {
            await budgetStore.updateCategory(updatedCategory)
            dismiss()
        }
    }
}
