//
//  FolderRowView.swift
//  I Do Blueprint
//
//  Displays a folder row with expand/collapse, rename, move, and delete actions
//

import SwiftUI

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
    @State private var newName = ""
    @State private var cachedTotal: Double = 0.0
    
    enum DeleteOption {
        case moveToParent
        case deleteContents
    }
    
    // Folder color coding
    private let folderColors: [Color] = [
        .blue, .purple, .green, .orange, .pink, .teal, .indigo, .mint
    ]
    
    // MARK: - Computed Properties
    
    private var availableFolders: [BudgetItem] {
        allItems.filter { $0.isFolder && $0.id != folder.id && !isDescendant(of: folder.id, item: $0) }
    }
    
    private var folderColor: Color {
        // Use hash of folder ID to consistently assign color
        let hash = abs(folder.id.hashValue)
        return folderColors[hash % folderColors.count]
    }
    
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
            cachedTotal = calculateFolderTotal(folderId: folder.id, allItems: newItems)
        }
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
