//
//  BudgetItemHierarchyRenderer.swift
//  I Do Blueprint
//
//  Renders budget items hierarchically with folders and drag-and-drop support
//

import SwiftUI
import UniformTypeIdentifiers

struct BudgetItemHierarchyRenderer: View {
    let item: BudgetItem
    let level: Int
    let allItems: [BudgetItem]
    let budgetStore: BudgetStoreV2
    let selectedTaxRate: Double
    @Binding var newCategoryNames: [String: String]
    @Binding var newSubcategoryNames: [String: String]
    @Binding var newEventNames: [String: String]
    @Binding var draggedItem: BudgetItem?
    @Binding var dropTargetId: String?
    @Binding var isDragging: Bool
    @Binding var expandedFolderIds: Set<String>
    
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String, FolderRowView.DeleteOption?) -> Void
    let onAddCategory: (String, String) async -> Void
    let onAddSubcategory: (String, String) async -> Void
    let onAddEvent: (String, String) -> Void
    let responsibleOptions: [String]
    let getChildren: (String) -> [BudgetItem]
    let handleDrop: (BudgetItem, BudgetItem) -> Void
    
    var body: some View {
        if item.isFolder {
            folderView
        } else {
            itemView
        }
    }
    
    // MARK: - Folder View
    
    private var folderView: some View {
        VStack(spacing: 0) {
            // Render folder
            FolderRowView(
                folder: item,
                level: level,
                allItems: allItems,
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
                allItems: allItems,
                draggedItem: $draggedItem,
                dropTargetId: $dropTargetId,
                onDrop: { sourceItem in
                    handleDrop(sourceItem, item)
                }
            ))
            
            // Render children if expanded
            if expandedFolderIds.contains(item.id) {
                ForEach(getChildren(item.id), id: \.id) { child in
                    BudgetItemHierarchyRenderer(
                        item: child,
                        level: level + 1,
                        allItems: allItems,
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
            }
        }
    }
    
    // MARK: - Item View
    
    private var itemView: some View {
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
                responsibleOptions: responsibleOptions
            )
        }
        .padding(.vertical, Spacing.xs)
        .opacity(draggedItem?.id == item.id ? 0.5 : 1.0)
        .onDrag {
            self.draggedItem = item
            self.isDragging = true
            return NSItemProvider(object: item.id as NSString)
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleFolder(_ folder: BudgetItem) {
        if expandedFolderIds.contains(folder.id) {
            expandedFolderIds.remove(folder.id)
        } else {
            expandedFolderIds.insert(folder.id)
        }
    }
}
