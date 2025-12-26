import SwiftUI
import UniformTypeIdentifiers

struct BudgetItemsTableView: View {
    @Binding var items: [BudgetItem]
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

        
    // Drag and drop state
    @State private var draggedItem: BudgetItem?
    @State private var dropTargetId: String?
    @State private var isDragging = false
    
    // Folder expansion state (managed in view layer, not persisted)
    @State private var expandedFolderIds: Set<String> = []
    
    // Folder color coding
    private let folderColors: [Color] = [
        .blue, .purple, .green, .orange, .pink, .teal, .indigo, .mint
    ]
    
    // MARK: - Computed Properties
    
    private var rootItems: [BudgetItem] {
        items.filter { $0.parentFolderId == nil }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    private func getChildren(of folderId: String) -> [BudgetItem] {
        items.filter { $0.parentFolderId == folderId }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                // Data rows - hierarchical display
                ForEach(rootItems, id: \.id) { item in
                    renderItemHierarchy(item, level: 0)
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
    }
    
    // MARK: - Hierarchical Rendering
    
    private func renderItemHierarchy(_ item: BudgetItem, level: Int) -> AnyView {
        if item.isFolder {
            return AnyView(
                VStack(spacing: 0) {
                    // Render folder
                    FolderRowView(
                        folder: item,
                        level: level,
                        allItems: items,
                        isDragTarget: dropTargetId == item.id,
                        isExpanded: expandedFolderIds.contains(item.id),
                        onToggle: {
                            toggleFolder(item)
                        },
                        onRename: { newName in
                            onUpdateItem(item.id, "itemName", newName)
                        },
                        onRemove: { deleteOption in
                            onRemoveItem(item.id, deleteOption)
                        },
                        onUpdateItem: onUpdateItem
                    )
                    .padding(.vertical, Spacing.xs)
                    .opacity(draggedItem?.id == item.id ? 0.5 : 1.0)
                    .onDrag {
                        self.draggedItem = item
                        self.isDragging = true
                        return NSItemProvider(object: item.id as NSString)
                    }
                    .onDrop(of: [.text], delegate: FolderDropDelegate(
                        folder: item,
                        allItems: items,
                        draggedItem: $draggedItem,
                        dropTargetId: $dropTargetId,
                        onDrop: { sourceItem in
                            handleDrop(source: sourceItem, target: item)
                        }
                    ))
                    
                    // Render children if expanded
                    if expandedFolderIds.contains(item.id) {
                        ForEach(getChildren(of: item.id), id: \.id) { child in
                            renderItemHierarchy(child, level: level + 1)
                        }
                    }
                }
            )
        } else {
            return AnyView(
                // Render regular item with indentation
                HStack(spacing: 0) {
                    // Indentation
                    if level > 0 {
                        Color.clear
                            .frame(width: CGFloat(level * 20))
                    }
                    
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
                        responsibleOptions: responsibleOptions)
                }
                .padding(.vertical, Spacing.xs)
                .opacity(draggedItem?.id == item.id ? 0.5 : 1.0)
                .onDrag {
                    self.draggedItem = item
                    self.isDragging = true
                    return NSItemProvider(object: item.id as NSString)
                }
            )
        }
    }
    
    private func toggleFolder(_ folder: BudgetItem) {
        if expandedFolderIds.contains(folder.id) {
            expandedFolderIds.remove(folder.id)
        } else {
            expandedFolderIds.insert(folder.id)
        }
    }
    
    // MARK: - Drag and Drop Handlers
    
    private func handleDrop(source: BudgetItem, target: BudgetItem) {
        guard canMove(item: source, toFolder: target) else { return }
        onUpdateItem(source.id, "parentFolderId", target.id)
        draggedItem = nil
        dropTargetId = nil
        isDragging = false
    }
    
    private func canMove(item: BudgetItem, toFolder folder: BudgetItem) -> Bool {
        BudgetItemMoveValidator.canMove(item: item, toFolder: folder, allItems: items)
    }
}

// MARK: - Budget Item Move Validator

struct BudgetItemMoveValidator {
    /// Validates whether an item can be moved to a target folder
    /// - Parameters:
    ///   - item: The item to move
    ///   - toFolder: The target folder
    ///   - allItems: All budget items for hierarchy traversal
    /// - Returns: True if the move is valid, false otherwise
    static func canMove(item: BudgetItem, toFolder: BudgetItem, allItems: [BudgetItem]) -> Bool {
        // Cannot move item to itself
        if item.id == toFolder.id { return false }
        
        // If moving a folder, ensure we're not moving it into one of its descendants
        if item.isFolder {
            var currentId: String? = toFolder.id
            while let id = currentId {
                if id == item.id { return false }
                currentId = allItems.first(where: { $0.id == id })?.parentFolderId
            }
        }
        
        // Check folder depth limit (max 3 levels)
        var depth = 0
        var currentId: String? = toFolder.id
        while let id = currentId {
            depth += 1
            if depth >= 3 { return false }
            currentId = allItems.first(where: { $0.id == id })?.parentFolderId
        }
        
        return true
    }
}

// MARK: - Folder Drop Delegate

struct FolderDropDelegate: DropDelegate {
    let folder: BudgetItem
    let allItems: [BudgetItem]
    @Binding var draggedItem: BudgetItem?
    @Binding var dropTargetId: String?
    let onDrop: (BudgetItem) -> Void
    
    func validateDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        return canMove(item: draggedItem, toFolder: folder)
    }
    
    func dropEntered(info: DropInfo) {
        if validateDrop(info: info) { dropTargetId = folder.id }
    }
    
    func dropExited(info: DropInfo) {
        if dropTargetId == folder.id { dropTargetId = nil }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem, validateDrop(info: info) else { return false }
        onDrop(draggedItem)
        dropTargetId = nil
        return true
    }
    
    private func canMove(item: BudgetItem, toFolder folder: BudgetItem) -> Bool {
        BudgetItemMoveValidator.canMove(item: item, toFolder: folder, allItems: allItems)
    }
}

// MARK: - Folder Row View

struct FolderRowView: View {
    let folder: BudgetItem
    let level: Int
    let allItems: [BudgetItem]
    let isDragTarget: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRename: (String) -> Void
    let onRemove: (DeleteOption) -> Void
    let onUpdateItem: (String, String, Any) -> Void
    
    @State private var showingRenameDialog = false
    @State private var showingDeleteDialog = false
    @State private var showingColorPicker = false
    @State private var newName = ""
    @State private var deleteOption: DeleteOption = .moveToParent
    @State private var isDropTarget = false
    @State private var selectedColor: Color = .blue
    @State private var cachedTotal: Double = 0.0
    
    enum DeleteOption {
        case moveToParent
        case deleteContents
    }
    
    // Folder color coding
    private let folderColors: [Color] = [
        .blue, .purple, .green, .orange, .pink, .teal, .indigo, .mint
    ]
    
    // Available folders for "Move to Folder" menu
    private var availableFolders: [BudgetItem] {
        allItems.filter { $0.isFolder && $0.id != folder.id && !isDescendant(of: folder.id, item: $0) }
    }
    
    private func isDescendant(of folderId: String, item: BudgetItem) -> Bool {
        var currentId: String? = item.parentFolderId
        while let id = currentId {
            if id == folderId { return true }
            currentId = allItems.first(where: { $0.id == id })?.parentFolderId
        }
        return false
    }
    
    private func getFolderLevel(_ targetFolder: BudgetItem) -> Int {
        var level = 0
        var currentId: String? = targetFolder.parentFolderId
        while let id = currentId {
            level += 1
            currentId = allItems.first(where: { $0.id == id })?.parentFolderId
        }
        return level
    }
    
    private func onMoveToFolder(_ targetFolderId: String?) {
        if let targetId = targetFolderId {
            onUpdateItem(folder.id, "parentFolderId", targetId)
        } else {
            onUpdateItem(folder.id, "parentFolderId", NSNull())
        }
    }
    
    private var folderColor: Color {
        // Use hash of folder ID to consistently assign color
        let hash = abs(folder.id.hashValue)
        return folderColors[hash % folderColors.count]
    }
    
    // MARK: - Computed Properties
    
    private var folderTotal: Double {
        // Use database-cached total if available (Phase 2)
        if let dbCachedTotal = folder.cachedTotalWithTax,
           let updatedAt = folder.cachedTotalsUpdatedAt,
           Date().timeIntervalSince(updatedAt) < 300 {
            return dbCachedTotal
        }
        
        // Fallback to cached calculation (computed once on appear)
        return cachedTotal
    }
    
    private func calculateFolderTotal(folderId: String, allItems: [BudgetItem]) -> Double {
        var total = 0.0
        var queue = [folderId]
        
        while !queue.isEmpty {
            let currentId = queue.removeFirst()
            let children = allItems.filter { $0.parentFolderId == currentId }
            
            for child in children {
                if child.isFolder {
                    queue.append(child.id)
                } else {
                    total += child.vendorEstimateWithTax
                }
            }
        }
        
        return total
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Indentation
            if level > 0 {
                Color.clear
                    .frame(width: CGFloat(level * 20))
            }
            
            // Expand/collapse button
            Button(action: onToggle) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            
            // Folder icon with color coding
            Image(systemName: isExpanded ? "folder.fill" : "folder")
                .font(.system(size: 16))
                .foregroundColor(folderColor)
            
            // Color indicator dot
            Circle()
                .fill(folderColor)
                .frame(width: 8, height: 8)
            
            // Folder name
            Text(folder.itemName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Folder total with color-coded background
            Text("Total: $\(String(format: "%.2f", folderTotal))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(folderColor.opacity(0.15))
                .cornerRadius(4)
            
            // Actions menu
            Menu {
                Button {
                    newName = folder.itemName
                    showingRenameDialog = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                
                Menu {
                    Button {
                        onMoveToFolder(nil)
                    } label: {
                        Label("Root Level", systemImage: "house")
                    }
                    .disabled(folder.parentFolderId == nil)
                    
                    if !availableFolders.isEmpty {
                        Divider()
                        
                        ForEach(availableFolders, id: \.id) { targetFolder in
                            Button {
                                onMoveToFolder(targetFolder.id)
                            } label: {
                                HStack {
                                    let folderLevel = getFolderLevel(targetFolder)
                                    if folderLevel > 0 {
                                        Text(String(repeating: "  ", count: folderLevel))
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                    Image(systemName: "folder")
                                    Text(targetFolder.itemName)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Move to Folder", systemImage: "folder.badge.plus")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    showingDeleteDialog = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal)
        .background(
            isDragTarget ?
                Color.green.opacity(0.2) :
                Color(NSColor.controlBackgroundColor).opacity(0.5)
        )
        .cornerRadius(8)
        .overlay(
            isDragTarget ?
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green, lineWidth: 2) :
                nil
        )
        .sheet(isPresented: $showingRenameDialog) {
            renameDialog
        }
        .alert("Delete Folder", isPresented: $showingDeleteDialog) {
            deleteAlert
        } message: {
            Text("What would you like to do with the items in this folder?")
        }
        .onAppear {
            // Calculate total on appear
            cachedTotal = calculateFolderTotal(folderId: folder.id, allItems: allItems)
        }
        .onChange(of: allItems) { _, newItems in
            // Recalculate when items change (added, removed, or values updated)
            // This is efficient because SwiftUI only triggers when the actual array changes
            cachedTotal = calculateFolderTotal(folderId: folder.id, allItems: newItems)
        }
    }
    
    // MARK: - Rename Dialog
    
    private var renameDialog: some View {
        VStack(spacing: Spacing.lg) {
            Text("Rename Folder")
                .font(.headline)
            
            TextField("Folder Name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: Spacing.md) {
                Button("Cancel") {
                    showingRenameDialog = false
                    newName = ""
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Rename") {
                    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        onRename(trimmedName)
                    }
                    showingRenameDialog = false
                    newName = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 400)
    }
    
    // MARK: - Delete Alert
    
    private var deleteAlert: some View {
        Group {
            Button("Move Items to Parent") {
                onRemove(.moveToParent)
            }
            
            Button("Delete All Contents", role: .destructive) {
                onRemove(.deleteContents)
            }
            
            Button("Cancel", role: .cancel) {}
        }
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


// MARK: - Event Multi-Selector Popover

struct EventMultiSelectorPopover: View {
    let events: [WeddingEventDB]
    let selectedEventIds: [String]
    let onToggleEvent: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if events.isEmpty {
                Text("No events configured")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    Button(action: {
                        onToggleEvent(event.id)
                    }) {
                        HStack {
                            Image(systemName: selectedEventIds.contains(event.id) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedEventIds.contains(event.id) ? .accentColor : .secondary)
                            
                            Text(event.eventName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    if index < events.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(minWidth: 200, maxWidth: 300)
        .padding(.vertical, 8)
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
        onRemoveItem: { _, _ in },
        onAddCategory: { _, _ in },
        onAddSubcategory: { _, _ in },
        onAddEvent: { _, _ in },
        responsibleOptions: ["Partner 1", "Partner 2", "Both"])
}
