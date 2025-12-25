// Extracted from BudgetDevelopmentView.swift

import SwiftUI

struct BudgetItemsTable: View {
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
    
    // Folder support
    @State private var showingCreateFolder = false
    @State private var newFolderName = ""
    @State private var selectedParentFolder: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Add Folder button
                Button(action: { showingCreateFolder = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.plus")
                        Text("Add Folder")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()

                Button(action: onAddItem) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Item")
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if budgetItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No budget items yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Click 'Add Item' to start building your budget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.huge)
            } else {
                    BudgetItemsTableView(
                    items: $budgetItems,
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
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(isPresented: $showingCreateFolder) {
            createFolderSheet
        }
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
    
    // MARK: - Folder Actions
    
    private func createFolder() {
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Call the parent's addFolder function which handles creation and persistence
        onAddFolder(trimmedName, selectedParentFolder)
        
        // Close sheet
        showingCreateFolder = false
        newFolderName = ""
        selectedParentFolder = nil
    }
}
