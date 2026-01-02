// BudgetItemsCardView.swift
// I Do Blueprint
//
// Card-based budget item editor for compact window mode
// Replaces the 10-column table with vertically stacked editable cards

import SwiftUI

/// View mode for organizing budget items
enum BudgetItemsViewMode: String, CaseIterable {
    case byCategory = "By Category"
    case byFolder = "By Folder"
    
    var icon: String {
        switch self {
        case .byCategory: return "square.grid.2x2"
        case .byFolder: return "folder"
        }
    }
}

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
    
    // View mode toggle
    @State private var viewMode: BudgetItemsViewMode = .byCategory
    
    // Folder support
    @State private var showingCreateFolder = false
    @State private var newFolderName = ""
    @State private var selectedParentFolder: String?
    
    // Expanded items for editing
    @State private var expandedItemIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // View mode toggle and action buttons
            headerRow
            
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
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        VStack(spacing: Spacing.sm) {
            // View mode toggle
            HStack(spacing: Spacing.xs) {
                ForEach(BudgetItemsViewMode.allCases, id: \.self) { mode in
                    Button(action: { viewMode = mode }) {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                            Text(mode.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(viewMode == mode ? AppColors.Budget.allocated.opacity(0.15) : Color.clear)
                        .foregroundColor(viewMode == mode ? AppColors.Budget.allocated : .secondary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            
            // Action buttons
            actionButtons
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
            switch viewMode {
            case .byCategory:
                ForEach(groupedByCategory.keys.sorted(), id: \.self) { category in
                    if let items = groupedByCategory[category] {
                        categorySection(category: category, items: items)
                    }
                }
            case .byFolder:
                folderBasedView
            }
        }
    }
    
    // MARK: - Grouped by Category
    
    private var groupedByCategory: [String: [BudgetItem]] {
        Dictionary(grouping: budgetItems.filter { !$0.isFolder }) { item in
            item.category.isEmpty ? "Uncategorized" : item.category
        }
    }
    
    // MARK: - Folder-Based View
    
    @ViewBuilder
    private var folderBasedView: some View {
        // Get folders
        let folders = budgetItems.filter { $0.isFolder }
        let rootFolders = folders.filter { $0.parentFolderId == nil }
        let itemsWithoutFolder = budgetItems.filter { !$0.isFolder && $0.parentFolderId == nil }
        
        // Root level folders
        ForEach(rootFolders) { folder in
            folderSection(folder: folder)
        }
        
        // Items without folder
        if !itemsWithoutFolder.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                    Text("Uncategorized Items")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let total = itemsWithoutFolder.reduce(0.0) { $0 + $1.vendorEstimateWithTax }
                    Text("$\(String(format: "%.0f", total))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                
                ForEach(itemsWithoutFolder) { item in
                    itemCard(item: item)
                }
            }
        }
    }
    
    private func folderSection(folder: BudgetItem) -> some View {
        let childItems = budgetItems.filter { !$0.isFolder && $0.parentFolderId == folder.id }
        let total = childItems.reduce(0.0) { $0 + $1.vendorEstimateWithTax }
        
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            // Folder header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(AppColors.Budget.allocated)
                Text(folder.itemName)
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
            
            // Child items
            ForEach(childItems) { item in
                itemCard(item: item)
            }
        }
    }
    
    // MARK: - Category Section
    
    @ViewBuilder
    private func categorySection(category: String, items: [BudgetItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            categoryHeader(category: category, items: items)
            
            ForEach(items) { item in
                itemCard(item: item)
            }
        }
    }
    
    private func itemCard(item: BudgetItem) -> some View {
        BudgetItemCard(
            item: item,
            isExpanded: expandedItemIds.contains(item.id),
            categories: parentCategoryNames,
            subcategories: subcategoryNames(for: item.category),
            taxRates: budgetStore.taxRates,
            weddingEvents: budgetStore.weddingEvents,
            responsibleOptions: responsibleOptions,
            onToggleExpand: { toggleExpand(item.id) },
            onUpdateItem: onUpdateItem,
            onRemoveItem: { onRemoveItem(item.id, nil) }
        )
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
    let weddingEvents: [WeddingEvent]
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
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Item Name - full width
                itemNameRow
                
                // Two-column grid for other fields
                twoColumnGrid
                
                // Notes - full width
                notesRow
                
                // Delete button
                deleteRow
            }
            .padding(Spacing.md)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
    }
    
    // MARK: - Two Column Grid
    
    private var twoColumnGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.md, verticalSpacing: Spacing.sm) {
            // Row 1: Category & Subcategory
            GridRow {
                labeledField(label: "Category") {
                    categoryPicker
                }
                labeledField(label: "Subcategory") {
                    subcategoryPicker
                }
            }
            
            // Row 2: Estimate & Tax Rate
            GridRow {
                labeledField(label: "Estimate (No Tax)") {
                    estimateField
                }
                labeledField(label: "Tax Rate") {
                    taxRateDisplay
                }
            }
            
            // Row 3: Responsible & Events
            GridRow {
                labeledField(label: "Responsible") {
                    responsiblePicker
                }
                labeledField(label: "Events") {
                    eventsDisplay
                }
            }
        }
    }
    
    /// Helper to create a labeled field with consistent styling
    @ViewBuilder
    private func labeledField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Item Name Row
    
    private var itemNameRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Item Name")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Item name", text: Binding(
                get: { item.itemName },
                set: { onUpdateItem(item.id, "itemName", $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.subheadline)
        }
    }
    
    // MARK: - Pickers
    
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var subcategoryPicker: some View {
        let currentSubcategory = item.subcategory ?? ""
        return Picker("", selection: Binding(
            get: { currentSubcategory },
            set: { onUpdateItem(item.id, "subcategory", $0) }
        )) {
            Text("None").tag("")
            ForEach(subcategories, id: \.self) { sub in
                Text(sub).tag(sub)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    /// Tax rate picker - uses ID for selection (same approach as full-size view)
    /// TaxInfo.taxRate is stored as decimal (0.1035), BudgetItem.taxRate is stored as percentage (10.35)
    private var taxRateDisplay: some View {
        Picker("", selection: Binding<Int64?>(
            get: {
                // Find the closest matching tax rate by comparing stored percentage to TaxInfo decimal * 100
                let closestRate = taxRates.min(by: {
                    abs(($0.taxRate * 100) - item.taxRate) < abs(($1.taxRate * 100) - item.taxRate)
                })
                return closestRate?.id
            },
            set: { newId in
                // Only update if we have a valid ID and can find the rate
                guard let newId = newId,
                      let selectedRate = taxRates.first(where: { $0.id == newId }) else {
                    return
                }
                // Convert decimal to percentage for storage (0.1035 -> 10.35)
                onUpdateItem(item.id, "taxRate", selectedRate.taxRate * 100)
            }
        )) {
            if taxRates.isEmpty {
                Text("No tax rates").tag(nil as Int64?)
            } else {
                // Show each tax rate with region name and percentage
                ForEach(taxRates, id: \.id) { rate in
                    Text("\(rate.region) (\(formatTaxRate(rate.taxRate)))")
                        .tag(rate.id as Int64?)
                }
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(maxWidth: .infinity, alignment: .leading)
        .disabled(taxRates.isEmpty)
    }
    
    /// Format tax rate as percentage (multiply by 100 since TaxInfo stores as decimal)
    private func formatTaxRate(_ rate: Double) -> String {
        let percentage = rate * 100
        if percentage == 0 {
            return "0%"
        } else if percentage.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(percentage))%"
        } else {
            return String(format: "%.2f%%", percentage)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Display event names instead of IDs
    private var eventsDisplay: some View {
        let eventNames = resolveEventNames()
        
        return Group {
            if eventNames.isEmpty {
                Text("None")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(eventNames.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Resolve event IDs to event names
    private func resolveEventNames() -> [String] {
        guard let eventIds = item.eventIds, !eventIds.isEmpty else {
            return []
        }
        
        return eventIds.compactMap { eventId in
            weddingEvents.first(where: { $0.id == eventId })?.eventName
        }
    }
    
    // MARK: - Notes Row
    
    private var notesRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Add notes...", text: Binding(
                get: { item.notes ?? "" },
                set: { onUpdateItem(item.id, "notes", $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.subheadline)
        }
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
