import SwiftUI

struct BudgetItemsTableView: View {
    @Binding var items: [BudgetItem]
    let budgetStore: BudgetStoreV2
    let selectedTaxRate: Double
    @Binding var newCategoryNames: [String: String]
    @Binding var newSubcategoryNames: [String: String]
    @Binding var newEventNames: [String: String]

    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String) -> Void
    let onAddCategory: (String, String) async -> Void
    let onAddSubcategory: (String, String) async -> Void
    let onAddEvent: (String, String) -> Void
    let responsibleOptions: [String]

    @State private var activeDropdownItemId: String?
    @State private var buttonRects: [String: CGRect] = [:]

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                // Data rows
                ForEach(items, id: \.id) { item in
                    BudgetItemRowView(
                        item: item,
                        budgetStore: budgetStore,
                        selectedTaxRate: selectedTaxRate,
                        newCategoryNames: $newCategoryNames,
                        newSubcategoryNames: $newSubcategoryNames,
                        newEventNames: $newEventNames,
                        onUpdateItem: onUpdateItem,
                        onRemoveItem: onRemoveItem,
                        onAddCategory: onAddCategory,
                        onAddSubcategory: onAddSubcategory,
                        onAddEvent: onAddEvent,
                        onButtonRectChanged: { itemId, rect in
                            buttonRects[itemId] = rect
                        },
                        responsibleOptions: responsibleOptions,
                        activeDropdownItemId: $activeDropdownItemId)
                        .padding(.vertical, Spacing.xs)
                }
            } header: {
                // Sticky header with title and column headers
                VStack(spacing: 0) {
                    // Budget Items title
                    HStack {
                        Text("Budget Items")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                    // Column headers
                    HStack(spacing: 12) {
                        Text("Event")
                            .frame(width: 120, alignment: .leading)
                        Text("Item")
                            .frame(width: 180, alignment: .leading)
                        Text("Category")
                            .frame(width: 120, alignment: .leading)
                        Text("Subcategory")
                            .frame(width: 120, alignment: .leading)
                        Text("Est. (No Tax)")
                            .frame(width: 100, alignment: .leading)
                        Text("Tax Rate")
                            .frame(width: 80, alignment: .leading)
                        Text("Est. (With Tax)")
                            .frame(width: 110, alignment: .leading)
                        Text("Person")
                            .frame(width: 80, alignment: .leading)
                        Text("Notes")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Actions")
                            .frame(width: 60, alignment: .leading)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, Spacing.sm)
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .overlay(
            // Event dropdown overlay
            Group {
                if let activeItemId = activeDropdownItemId,
                   let activeItem = items.first(where: { $0.id == activeItemId }) {
                    EventDropdownView(
                        isPresented: .constant(true),
                        selectedEventIds: activeItem.eventIds ?? [],
                        weddingEvents: budgetStore.weddingEvents,
                        onSelectionChanged: { eventIds in
                            onUpdateItem(activeItemId, "eventIds", eventIds)
                        },
                        onDismiss: {
                            activeDropdownItemId = nil
                        },
                        activeItemId: activeItemId,
                        allItems: items)
                }
            })
    }
}

struct BudgetItemRowView: View {
    let item: BudgetItem
    let budgetStore: BudgetStoreV2
    let selectedTaxRate: Double
    @Binding var newCategoryNames: [String: String]
    @Binding var newSubcategoryNames: [String: String]
    @Binding var newEventNames: [String: String]

    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String) -> Void
    let onAddCategory: (String, String) async -> Void
    let onAddSubcategory: (String, String) async -> Void
    let onAddEvent: (String, String) -> Void
    let onButtonRectChanged: (String, CGRect) -> Void
    let responsibleOptions: [String]

    @Binding var activeDropdownItemId: String?

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
                onRemoveItem(item.id)
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
                        onButtonRectChanged(item.id, rect)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newRect in
                        onButtonRectChanged(item.id, newRect)
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
        Picker("", selection: Binding(
            get: {
                // Find closest matching tax rate ID (item.taxRate is stored as percentage, rate.taxRate is decimal)
                budgetStore.taxRates.min(by: { abs(($0.taxRate * 100) - item.taxRate) < abs(($1.taxRate * 100) - item.taxRate) })?.id ?? budgetStore.taxRates.first?.id ?? 0
            },
            set: { newId in
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
        budgetStore.categories.filter { $0.parentCategoryId == nil }
    }

    private func subcategoriesForCategory(_ categoryName: String) -> [BudgetCategory] {
        guard let parentCategory = budgetStore.categories.first(where: {
            $0.categoryName == categoryName && $0.parentCategoryId == nil
        }) else {
            return []
        }

        return budgetStore.categories.filter { $0.parentCategoryId == parentCategory.id }
    }
}

struct EventDropdownView: View {
    @Binding var isPresented: Bool
    let selectedEventIds: [String]
    let weddingEvents: [WeddingEvent]
    let onSelectionChanged: ([String]) -> Void
    let onDismiss: () -> Void
    let activeItemId: String
    let allItems: [BudgetItem]

    @State private var tempSelectedIds: Set<String> = Set()

    private var rowIndex: Int {
        allItems.firstIndex(where: { $0.id == activeItemId }) ?? 0
    }

    var body: some View {
        if isPresented {
            // Full-screen overlay to catch outside taps
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
                .overlay(
                    // Dropdown content positioned based on row index
                    VStack(alignment: .leading, spacing: 4) {
                        if weddingEvents.isEmpty {
                            VStack(spacing: 8) {
                                Text("No events configured")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(Spacing.sm)
                            }
                        } else {
                            ForEach(weddingEvents, id: \.id) { event in
                                Button(action: {
                                    if tempSelectedIds.contains(event.id) {
                                        tempSelectedIds.remove(event.id)
                                    } else {
                                        tempSelectedIds.insert(event.id)
                                    }
                                    // Apply changes immediately
                                    onSelectionChanged(Array(tempSelectedIds))
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: tempSelectedIds
                                            .contains(event.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(tempSelectedIds.contains(event.id) ? .blue : .secondary)
                                            .font(.system(size: 14))

                                        Text(event.eventName)
                                            .font(.system(size: 13))
                                            .foregroundColor(.primary)

                                        Spacer()
                                    }
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(
                                    Color.clear
                                        .onHover { _ in
                                            // Add hover effect if needed
                                        })
                            }
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .shadow(color: AppColors.textPrimary.opacity(0.15), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: 200)
                    .fixedSize()
                    .offset(
                        x: 150, // Fixed horizontal position
                        y: -50 + CGFloat(rowIndex * 65) // Align with the button row
                    ), alignment: .topLeading)
                .zIndex(999) // High z-index to appear above everything
                .onAppear {
                    tempSelectedIds = Set(selectedEventIds)
                }
        }
    }
}

#Preview {
    BudgetItemsTableView(
        items: .constant([]),
        budgetStore: BudgetStoreV2(),
        selectedTaxRate: 10.35,
        newCategoryNames: .constant([:]),
        newSubcategoryNames: .constant([:]),
        newEventNames: .constant([:]),
        onUpdateItem: { _, _, _ in },
        onRemoveItem: { _ in },
        onAddCategory: { _, _ in },
        onAddSubcategory: { _, _ in },
        onAddEvent: { _, _ in },
        responsibleOptions: ["Partner 1", "Partner 2", "Both"]) 
}
