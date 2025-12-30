//
//  BudgetItemRowView.swift
//  I Do Blueprint
//
//  Displays a single budget item row with editable fields
//

import SwiftUI

struct BudgetItemRowView: View {
    let item: BudgetItem
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
    let responsibleOptions: [String]
    
    // Cached picker values to avoid recomputation on every render
    @State private var cachedTaxRateId: Int64?
    @State private var cachedCategoryName: String = ""
    @State private var cachedSubcategoryName: String = ""
    
    // Event selector popover state
    @State private var showingEventPopover: Bool = false

    var body: some View {
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
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Component Views

    private var eventSelector: some View {
        Button(action: {
            showingEventPopover.toggle()
        }) {
            HStack {
                Text(eventDisplayText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .popover(isPresented: $showingEventPopover, arrowEdge: .bottom) {
            EventMultiSelectorPopover(
                events: budgetStore.weddingEvents,
                selectedEventIds: item.eventIds ?? [],
                onToggleEvent: { eventId in
                    var current = item.eventIds ?? []
                    if let index = current.firstIndex(of: eventId) {
                        current.remove(at: index)
                    } else {
                        current.append(eventId)
                    }
                    onUpdateItem(item.id, "eventIds", current)
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                                Task {
                                    await onAddCategory(item.id, currentName)
                                }
                            }
                        }

                    Button(action: {
                        if let currentName = newCategoryNames[item.id] {
                            Task {
                                await onAddCategory(item.id, currentName)
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
                    get: { cachedCategoryName.isEmpty ? item.category : cachedCategoryName },
                    set: { newValue in
                        if newValue == "__new__" {
                            newCategoryNames[item.id] = ""
                        } else {
                            cachedCategoryName = newValue
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
                    .onAppear {
                        if cachedCategoryName.isEmpty {
                            cachedCategoryName = item.category
                        }
                    }
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
                                Task {
                                    await onAddSubcategory(item.id, currentName)
                                }
                            }
                        }

                    Button(action: {
                        if let currentName = newSubcategoryNames[item.id] {
                            Task {
                                await onAddSubcategory(item.id, currentName)
                            }
                        }
                    }) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderless)
                    .disabled((newSubcategoryNames[item.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty)
                }
            } else {
                Picker("", selection: Binding(
                    get: { cachedSubcategoryName.isEmpty ? (item.subcategory ?? "") : cachedSubcategoryName },
                    set: { newValue in
                        if newValue == "__new__" {
                            newSubcategoryNames[item.id] = ""
                        } else {
                            cachedSubcategoryName = newValue
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
                    .onAppear {
                        if cachedSubcategoryName.isEmpty {
                            cachedSubcategoryName = item.subcategory ?? ""
                        }
                    }
            }
        }
    }

    private var taxRateSelector: some View {
        Picker("", selection: Binding(
            get: {
                // Use cached value if available
                if let cached = cachedTaxRateId {
                    return cached
                }
                // Fallback to first tax rate
                return budgetStore.taxRates.first?.id ?? 0
            },
            set: { (newId: Int64) in
                cachedTaxRateId = newId
                if let selectedRate = budgetStore.taxRates.first(where: { $0.id == newId }) {
                    // Convert decimal to percentage for storage (0.0935 -> 9.35)
                    onUpdateItem(item.id, "taxRate", selectedRate.taxRate * 100)
                }
            })) {
                ForEach(budgetStore.taxRates, id: \.id) { rate in
                    Text("\(rate.region) (\(String(format: "%.2f", rate.taxRate * 100))%)").tag(rate.id)
                }
            }
            .pickerStyle(.menu)
            .padding(.leading, -8)
            .onAppear {
                // Compute and cache tax rate ID once on appear
                if cachedTaxRateId == nil {
                    let closestRate = budgetStore.taxRates.min(by: {
                        abs(($0.taxRate * 100) - item.taxRate) < abs(($1.taxRate * 100) - item.taxRate)
                    })
                    cachedTaxRateId = closestRate?.id ?? budgetStore.taxRates.first?.id
                }
            }
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
