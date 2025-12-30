//
//  BudgetItemsTableView.swift
//  I Do Blueprint
//
//  Main coordination view for budget items table with hierarchical display
//

import SwiftUI

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
                    BudgetItemHierarchyRenderer(
                        item: item,
                        level: 0,
                        allItems: items,
                        budgetStore: budgetStore,
                        selectedTaxRate: selectedTaxRate,
                        newCategoryNames: $newCategoryNames,
                        newSubcategoryNames: $newSubcategoryNames,
                        newEventNames: $newEventNames,
                        draggedItem: $draggedItem,
                        dropTargetId: $dropTargetId,
                        isDragging: $isDragging,
                        expandedFolderIds: $expandedFolderIds,
                        onUpdateItem: onUpdateItem,
                        onRemoveItem: onRemoveItem,
                        onAddCategory: onAddCategory,
                        onAddSubcategory: onAddSubcategory,
                        onAddEvent: onAddEvent,
                        responsibleOptions: responsibleOptions,
                        getChildren: getChildren,
                        handleDrop: handleDrop
                    )
                }
            } header: {
                BudgetItemsTableHeader()
            }
        }
    }
    
    // MARK: - Drag and Drop Handlers
    
    private func handleDrop(source: BudgetItem, target: BudgetItem) {
        guard BudgetItemMoveValidator.canMove(item: source, toFolder: target, allItems: items) else { return }
        onUpdateItem(source.id, "parentFolderId", target.id)
        draggedItem = nil
        dropTargetId = nil
        isDragging = false
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
