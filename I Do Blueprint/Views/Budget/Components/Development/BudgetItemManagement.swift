//
//  BudgetItemManagement.swift
//  I Do Blueprint
//
//  Budget item CRUD operations for budget development
//

import Foundation

// MARK: - Budget Item Management

extension BudgetDevelopmentView {

    // MARK: Add Item

    func addBudgetItem() {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            logger.error("Cannot add budget item: No couple selected")
            return
        }

        let newItem = BudgetItem(
            id: UUID().uuidString,
            scenarioId: currentScenarioId,
            itemName: "",
            category: "",
            subcategory: "",
            vendorEstimateWithoutTax: 0,
            taxRate: selectedTaxRate,
            vendorEstimateWithTax: 0,
            personResponsible: "Both",
            notes: "",
            createdAt: Date(),
            updatedAt: Date(),
            eventId: nil,
            eventIds: [],
            linkedExpenseId: nil,
            linkedGiftOwedId: nil,
            coupleId: coupleId,
            isTestData: false,
            parentFolderId: nil,
            isFolder: false,
            displayOrder: 0)

        budgetItems.insert(newItem, at: 0)
        newlyCreatedItemIds.insert(newItem.id)
    }
    
    // MARK: Add Folder
    
    func addFolder(name: String, parentFolderId: String?) {
        // Validate folder name is not empty or whitespace-only
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.error("Cannot add folder: name is empty")
            return
        }
        
        guard let coupleId = SessionManager.shared.getTenantId() else {
            logger.error("Cannot add folder: No couple selected")
            return
        }
        
        guard let scenarioId = currentScenarioId else {
            logger.error("Cannot add folder: No scenario selected")
            return
        }
        
        // Increment displayOrder of all items in the same parent folder
        for index in budgetItems.indices {
            if budgetItems[index].parentFolderId == parentFolderId {
                budgetItems[index].displayOrder += 1
            }
        }
        
        // Create folder at the top (displayOrder = 0)
        let newFolder = BudgetItem.createFolder(
            name: name,
            scenarioId: scenarioId,
            parentFolderId: parentFolderId,
            displayOrder: 0,
            coupleId: coupleId
        )
        
        // Add to local array at the top to match displayOrder = 0 and addBudgetItem() behavior
        budgetItems.insert(newFolder, at: 0)
        
        // Mark as newly created so it gets saved
        newlyCreatedItemIds.insert(newFolder.id)
        
        logger.info("Created folder: \(name) at top of list")
    }

    // MARK: Update Item

    func updateBudgetItem(_ id: String, field: String, value: Any) {
        guard let index = budgetItems.firstIndex(where: { $0.id == id }) else { return }

        var item = budgetItems[index]

        switch field {
        case "itemName":
            item.itemName = value as? String ?? ""
        case "eventIds":
            item.eventIds = value as? [String] ?? []
        case "category":
            item.category = value as? String ?? ""
            item.subcategory = ""
        case "subcategory":
            item.subcategory = value as? String ?? ""
        case "vendorEstimateWithoutTax":
            item.vendorEstimateWithoutTax = value as? Double ?? 0
            item.vendorEstimateWithTax = item.vendorEstimateWithoutTax * (1 + item.taxRate / 100)
        case "taxRate":
            item.taxRate = value as? Double ?? 0
            item.vendorEstimateWithTax = item.vendorEstimateWithoutTax * (1 + item.taxRate / 100)
        case "personResponsible":
            item.personResponsible = value as? String ?? "Both"
        case "notes":
            item.notes = value as? String ?? ""
        case "parentFolderId":
            // Handle both String and NSNull for parentFolderId
            if let folderId = value as? String {
                item.parentFolderId = folderId
            } else {
                item.parentFolderId = nil
            }
        default:
            break
        }

        budgetItems[index] = item
    }

    // MARK: Remove Item

    func removeBudgetItem(_ id: String, deleteOption: FolderRowView.DeleteOption? = nil) {
        // Check if this is a folder
        guard let item = budgetItems.first(where: { $0.id == id }) else { return }
        
        if item.isFolder {
            // Handle folder deletion based on the option
            if let option = deleteOption {
                switch option {
                case .moveToParent:
                    // Move all children to the folder's parent
                    let parentFolderId = item.parentFolderId
                    for index in budgetItems.indices {
                        if budgetItems[index].parentFolderId == id {
                            budgetItems[index].parentFolderId = parentFolderId
                        }
                    }
                    
                case .deleteContents:
                    // Recursively delete all descendants
                    var itemsToRemove = Set<String>()
                    var queue = [id]
                    
                    while !queue.isEmpty {
                        let currentId = queue.removeFirst()
                        let children = budgetItems.filter { $0.parentFolderId == currentId }
                        
                        for child in children {
                            itemsToRemove.insert(child.id)
                            if child.isFolder {
                                queue.append(child.id)
                            }
                        }
                    }
                    
                    // Mark items for deletion or remove from newly created
                    for itemId in itemsToRemove {
                        if !newlyCreatedItemIds.contains(itemId) {
                            itemsToDelete.insert(itemId)
                        } else {
                            newlyCreatedItemIds.remove(itemId)
                        }
                    }
                    
                    // Remove all descendants from local array
                    budgetItems.removeAll { itemsToRemove.contains($0.id) }
                }
            }
        }
        
        // Mark folder/item for deletion or remove from newly created
        if !newlyCreatedItemIds.contains(id) {
            itemsToDelete.insert(id)
        } else {
            newlyCreatedItemIds.remove(id)
        }

        // Remove the folder/item itself from local array
        budgetItems.removeAll { $0.id == id }
    }

    // MARK: Category Management

    func handleNewCategoryName(_ itemId: String, _ categoryName: String) async {
        guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        let existingCategory = budgetStore.categoryStore.categories.first {
            $0.categoryName == trimmedName && $0.parentCategoryId == nil
        }

        if existingCategory == nil {
            // Get the current tenant's couple ID for RLS compliance
            guard let coupleId = SessionManager.shared.getTenantId() else {
                logger.error("Cannot create category: No couple selected")
                return
            }
            
            let newCategory = BudgetCategory(
                id: UUID(),
                coupleId: coupleId,
                categoryName: trimmedName,
                parentCategoryId: nil,
                allocatedAmount: 0,
                spentAmount: 0,
                typicalPercentage: 0,
                priorityLevel: 5,
                isEssential: false,
                notes: "Category created from budget development",
                forecastedAmount: 0,
                confidenceLevel: 0.5,
                lockedAllocation: false,
                description: "Category created from budget development",
                createdAt: Date())
            try? await budgetStore.categoryStore.addCategory(newCategory)
        }

        updateBudgetItem(itemId, field: "category", value: trimmedName)
        newCategoryNames.removeValue(forKey: itemId)
    }

    func handleNewSubcategoryName(_ itemId: String, _ subcategoryName: String) async {
        guard !subcategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let item = budgetItems.first(where: { $0.id == itemId }),
              !item.category.isEmpty else { return }

        let trimmedName = subcategoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let parentCategory = budgetStore.categoryStore.categories.first(where: {
            $0.categoryName == item.category && $0.parentCategoryId == nil
        }) else { return }

        let existingSubcategory = budgetStore.categoryStore.categories.first {
            $0.categoryName == trimmedName && $0.parentCategoryId == parentCategory.id
        }

        if existingSubcategory == nil {
            // Get the current tenant's couple ID for RLS compliance
            guard let coupleId = SessionManager.shared.getTenantId() else {
                logger.error("Cannot create subcategory: No couple selected")
                return
            }
            
            let newSubcategory = BudgetCategory(
                id: UUID(),
                coupleId: coupleId,
                categoryName: trimmedName,
                parentCategoryId: parentCategory.id,
                allocatedAmount: 0,
                spentAmount: 0,
                typicalPercentage: 0,
                priorityLevel: 5,
                isEssential: false,
                notes: "Subcategory created from budget development",
                forecastedAmount: 0,
                confidenceLevel: 0.5,
                lockedAllocation: false,
                description: "Subcategory created from budget development",
                createdAt: Date())
            try? await budgetStore.categoryStore.addCategory(newSubcategory)
        }

        updateBudgetItem(itemId, field: "subcategory", value: trimmedName)
        newSubcategoryNames.removeValue(forKey: itemId)
    }

    func handleNewEventName(_ itemId: String, _: String) {
        newEventNames.removeValue(forKey: itemId)
    }
}
