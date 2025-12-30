//
//  FolderDropDelegate.swift
//  I Do Blueprint
//
//  Handles drag-and-drop operations for budget item folders
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderDropDelegate: DropDelegate {
    let folder: BudgetItem
    let allItems: [BudgetItem]
    @Binding var draggedItem: BudgetItem?
    @Binding var dropTargetId: String?
    let onDrop: (BudgetItem) -> Void
    
    func validateDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        return BudgetItemMoveValidator.canMove(item: draggedItem, toFolder: folder, allItems: allItems)
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
}
