//
//  BudgetItemRow.swift
//  I Do Blueprint
//
//  PHASE 3: Extracted item row component for better view identity and performance
//

import SwiftUI

/// A dedicated view component for rendering budget item rows
///
/// Extracted from BudgetItemsTableView to improve:
/// - View identity stability (reduces unnecessary re-renders)
/// - Code organization and maintainability
/// - Performance through better SwiftUI diffing
struct BudgetItemRow: View, Identifiable {
    let id: String
    let item: BudgetItem
    let level: Int
    let budgetStore: BudgetStoreV2
    let selectedTaxRate: Double
    @Binding var newCategoryNames: [String: String]
    @Binding var newSubcategoryNames: [String: String]
    @Binding var newEventNames: [String: String]
    
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String, FolderRowView.DeleteOption?) -> Void
    let onAddCategory: (String, String) async -> Void
    let onAddSubcategory: (String, String) async -> Void
    let onAddEvent: (String, String) -> Void
    let onButtonRectChanged: (String, CGRect) -> Void
    let responsibleOptions: [String]
    
    @Binding var activeDropdownItemId: String?
    
    // Debounce state for coalescing rapid geometry updates
    @State private var rectUpdateWorkItem: DispatchWorkItem?
    private let rectDebounceInterval: TimeInterval = 0.1 // 100ms
    
    // Tracked async tasks to avoid unscoped work
    @State private var addCategoryTask: Task<Void, Never>?
    @State private var addSubcategoryTask: Task<Void, Never>?
    
    init(
        item: BudgetItem,
        level: Int,
        budgetStore: BudgetStoreV2,
        selectedTaxRate: Double,
        newCategoryNames: Binding<[String: String]>,
        newSubcategoryNames: Binding<[String: String]>,
        newEventNames: Binding<[String: String]>,
        onUpdateItem: @escaping (String, String, Any) -> Void,
        onRemoveItem: @escaping (String, FolderRowView.DeleteOption?) -> Void,
        onAddCategory: @escaping (String, String) async -> Void,
        onAddSubcategory: @escaping (String, String) async -> Void,
        onAddEvent: @escaping (String, String) -> Void,
        onButtonRectChanged: @escaping (String, CGRect) -> Void,
        responsibleOptions: [String],
        activeDropdownItemId: Binding<String?>
    ) {
        self.id = item.id
        self.item = item
        self.level = level
        self.budgetStore = budgetStore
        self.selectedTaxRate = selectedTaxRate
        self._newCategoryNames = newCategoryNames
        self._newSubcategoryNames = newSubcategoryNames
        self._newEventNames = newEventNames
        self.onUpdateItem = onUpdateItem
        self.onRemoveItem = onRemoveItem
        self.onAddCategory = onAddCategory
        self.onAddSubcategory = onAddSubcategory
        self.onAddEvent = onAddEvent
        self.onButtonRectChanged = onButtonRectChanged
        self.responsibleOptions = responsibleOptions
        self._activeDropdownItemId = activeDropdownItemId
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Indentation
            if level > 0 {
                Color.clear
                    .frame(width: CGFloat(level * 20))
            }
            
            // Item content
            HStack(spacing: 12) {
                // Event selector
                eventSelector
                    .frame(width: 120)
                
                // Item name
                TextField("Item name", text: Binding(
                    get: { item.itemName },
                    set: { newValue in
                        onUpdateItem(item.id, "itemName", newValue)
                    }))
                .frame(width: 180)
                
                // Category selector
                categorySelector
                    .frame(width: 120)
                
                // Subcategory selector
                subcategorySelector
                    .frame(width: 120)
                
                // Vendor estimate without tax
                TextField("0.00", value: Binding(
                    get: { item.vendorEstimateWithoutTax },
                    set: { newValue in
                        onUpdateItem(item.id, "vendorEstimateWithoutTax", newValue)
                    }), format: .number)
                .frame(width: 100)
                
                // Tax rate selector
                taxRateSelector
                    .frame(width: 80)
                
                // Vendor estimate with tax (calculated)
                Text("$\(String(format: "%.2f", item.vendorEstimateWithTax))")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .frame(width: 110, alignment: .leading)
                
                // Person responsible
                personSelector
                    .frame(width: 80)
                
                // Notes
                TextField("Notes", text: Binding(
                    get: { item.notes ?? "" },
                    set: { newValue in
                        onUpdateItem(item.id, "notes", newValue.isEmpty ? nil : newValue)
                    }))
                .frame(maxWidth: .infinity)
                
                // Actions
                Button(action: {
                    onRemoveItem(item.id, nil)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .frame(width: 60)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .onDisappear {
            // Cancel any in-flight add operations when view disappears
            addCategoryTask?.cancel()
            addCategoryTask = nil
            addSubcategoryTask?.cancel()
            addSubcategoryTask = nil
        }
    }
    
    // MARK: - Component Views
    
    private var eventSelector: some View {
        Button(action: {
            if activeDropdownItemId == item.id {
                activeDropdownItemId = nil
            } else {
                activeDropdownItemId = item.id
            }
        }) {
            HStack {
                Text(eventDisplayText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
        .buttonStyle(.bordered)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        let rect = geometry.frame(in: .global)
                        // Immediate call for initial rect
                        onButtonRectChanged(item.id, rect)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newRect in
                        // Debounce rapid updates to reduce frequent callbacks
                        rectUpdateWorkItem?.cancel()
                        let work = DispatchWorkItem { [itemId = item.id, newRect] in
                            onButtonRectChanged(itemId, newRect)
                        }
                        rectUpdateWorkItem = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + rectDebounceInterval, execute: work)
                    }
                    .onDisappear {
                        // Cancel any pending debounced update when view disappears
                        rectUpdateWorkItem?.cancel()
                        rectUpdateWorkItem = nil
                    }
            })
    }
    
    private var eventDisplayText: String {
        let selectedEventIds = item.eventIds ?? []
        if selectedEventIds.isEmpty {
            return "Select events"
        } else {
            let selectedEventNames = budgetStore.weddingEvents
                .filter { selectedEventIds.contains($0.id) }
                .map(\.eventName)
            
            if selectedEventNames.count == 1 {
                return selectedEventNames[0]
            } else {
                return "\(selectedEventNames.count) events"
            }
        }
    }
    
    private var categorySelector: some View {
        Group {
            if let newName = newCategoryNames[item.id] {
                HStack(spacing: 4) {
                    TextField("Category name", text: Binding(
                        get: { newCategoryNames[item.id] ?? "" },
                        set: { newValue in
                            newCategoryNames[item.id] = newValue
                        }))
                    .onSubmit {
                        if let currentName = newCategoryNames[item.id] {
                            addCategoryTask?.cancel()
                            addCategoryTask = Task { [itemId = item.id, name = currentName] in
                                await onAddCategory(itemId, name)
                            }
                        }
                    }
                    
                    Button(action: {
                        if let currentName = newCategoryNames[item.id] {
                            addCategoryTask?.cancel()
                            addCategoryTask = Task { [itemId = item.id, name = currentName] in
                                await onAddCategory(itemId, name)
                            }
                        }
                    }) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderless)
                    .disabled((newCategoryNames[item.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                Picker("", selection: Binding(
                    get: { item.category },
                    set: { newValue in
                        if newValue == "__new__" {
                            newCategoryNames[item.id] = ""
                        } else {
                            onUpdateItem(item.id, "category", newValue)
                        }
                    })) {
                        Text("Select category").tag("")
                        Text("+ New Category").tag("__new__")
                        
                        ForEach(parentCategories, id: \.id) { category in
                            Text(category.categoryName).tag(category.categoryName)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.leading, -8)
            }
        }
    }
    
    private var subcategorySelector: some View {
        Group {
            if let newName = newSubcategoryNames[item.id] {
                HStack(spacing: 4) {
                    TextField("Subcategory name", text: Binding(
                        get: { newSubcategoryNames[item.id] ?? "" },
                        set: { newValue in
                            newSubcategoryNames[item.id] = newValue
                        }))
                    .onSubmit {
                        if let currentName = newSubcategoryNames[item.id] {
                            addSubcategoryTask?.cancel()
                            addSubcategoryTask = Task { [itemId = item.id, name = currentName] in
                                await onAddSubcategory(itemId, name)
                            }
                        }
                    }
                    
                    Button(action: {
                        if let currentName = newSubcategoryNames[item.id] {
                            addSubcategoryTask?.cancel()
                            addSubcategoryTask = Task { [itemId = item.id, name = currentName] in
                                await onAddSubcategory(itemId, name)
                            }
                        }
                    }) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderless)
                    .disabled((newSubcategoryNames[item.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                Picker("", selection: Binding(
                    get: { item.subcategory ?? "" },
                    set: { newValue in
                        if newValue == "__new__" {
                            newSubcategoryNames[item.id] = ""
                        } else {
                            onUpdateItem(item.id, "subcategory", newValue)
                        }
                    })) {
                        Text(item.category.isEmpty ? "Select category first" : "Select subcategory").tag("")
                        
                        if !item.category.isEmpty {
                            Text("+ New Subcategory").tag("__new__")
                            
                            ForEach(subcategoriesForCategory(item.category), id: \.id) { subcategory in
                                Text(subcategory.categoryName).tag(subcategory.categoryName)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.leading, -8)
                    .disabled(item.category.isEmpty)
            }
        }
    }
    
    private var taxRateSelector: some View {
        Picker("", selection: Binding<Int64?>(
            get: {
                // Find the closest matching tax rate
                let closestRate = budgetStore.taxRates.min(by: {
                    abs(($0.taxRate * 100) - item.taxRate) < abs(($1.taxRate * 100) - item.taxRate)
                })
                // Return optional ID (nil if no tax rates available)
                return closestRate?.id ?? budgetStore.taxRates.first?.id
            },
            set: { newId in
                // Only update if we have a valid ID and can find the rate
                guard let newId = newId,
                      let selectedRate = budgetStore.taxRates.first(where: { $0.id == newId }) else {
                    return
                }
                onUpdateItem(item.id, "taxRate", selectedRate.taxRate * 100)
            })) {
                // Show placeholder if no tax rates available
                if budgetStore.taxRates.isEmpty {
                    Text("No tax rates available").tag(nil as Int64?)
                } else {
                    ForEach(budgetStore.taxRates, id: \.id) { rate in
                        Text("\(rate.region) (\(String(format: "%.2f", rate.taxRate * 100))%)").tag(rate.id as Int64?)
                    }
                }
            }
            .pickerStyle(.menu)
            .padding(.leading, -8)
            .disabled(budgetStore.taxRates.isEmpty)
    }
    
    private var personSelector: some View {
        Picker("", selection: Binding(
            get: { item.personResponsible ?? "Both" },
            set: { newValue in
                onUpdateItem(item.id, "personResponsible", newValue)
            })) {
                ForEach(responsibleOptions, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)
            .padding(.leading, -8)
    }
    
    // MARK: - Helper Properties
    
    private var parentCategories: [BudgetCategory] {
        budgetStore.categoryStore.categories.filter { $0.parentCategoryId == nil }
    }
    
    private func subcategoriesForCategory(_ categoryName: String) -> [BudgetCategory] {
        guard let parentCategory = budgetStore.categoryStore.categories.first(where: {
            $0.categoryName == categoryName && $0.parentCategoryId == nil
        }) else {
            return []
        }
        
        return budgetStore.categoryStore.categories.filter { $0.parentCategoryId == parentCategory.id }
    }
}
