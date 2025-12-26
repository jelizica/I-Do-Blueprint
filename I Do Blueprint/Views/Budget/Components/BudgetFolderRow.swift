//
//  BudgetFolderRow.swift
//  I Do Blueprint
//
//  PHASE 3: Extracted folder row component for better view identity and performance
//

import SwiftUI

/// A dedicated view component for rendering budget folder rows
///
/// Extracted from BudgetItemsTableView to improve:
/// - View identity stability (reduces unnecessary re-renders)
/// - Code organization and maintainability
/// - Performance through better SwiftUI diffing
struct BudgetFolderRow: View, Identifiable {
    let id: String
    let folder: BudgetItem
    let level: Int
    let allItems: [BudgetItem]
    let folderTotal: Double
    let isDragTarget: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRename: (String) -> Void
    let onRemove: (FolderRowView.DeleteOption) -> Void
    let onUpdateItem: (String, String, Any) -> Void
    
    @State private var showingRenameDialog = false
    @State private var showingDeleteDialog = false
    @State private var newName = ""
    @State private var deleteOption: FolderRowView.DeleteOption = .moveToParent
    
    // Folder color coding
    private let folderColors: [Color] = [
        .blue, .purple, .green, .orange, .pink, .teal, .indigo, .mint
    ]
    
    init(
        folder: BudgetItem,
        level: Int,
        allItems: [BudgetItem],
        folderTotal: Double,
        isDragTarget: Bool,
        isExpanded: Bool,
        onToggle: @escaping () -> Void,
        onRename: @escaping (String) -> Void,
        onRemove: @escaping (FolderRowView.DeleteOption) -> Void,
        onUpdateItem: @escaping (String, String, Any) -> Void
    ) {
        self.id = folder.id
        self.folder = folder
        self.level = level
        self.allItems = allItems
        self.folderTotal = folderTotal
        self.isDragTarget = isDragTarget
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.onRename = onRename
        self.onRemove = onRemove
        self.onUpdateItem = onUpdateItem
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
    }
    
    // MARK: - Computed Properties
    
    private var folderColor: Color {
        let hash = abs(folder.id.hashValue)
        return folderColors[hash % folderColors.count]
    }
    
    private var availableFolders: [BudgetItem] {
        allItems.filter { $0.isFolder && $0.id != folder.id && !isDescendant(of: folder.id, item: $0) }
    }
    
    // MARK: - Helper Methods
    
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
