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
            coupleId: coupleId.uuidString,
            isTestData: false)

        budgetItems.insert(newItem, at: 0)
        newlyCreatedItemIds.insert(newItem.id)
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
        default:
            break
        }

        budgetItems[index] = item
    }

    // MARK: Remove Item

    func removeBudgetItem(_ id: String) {
        if !newlyCreatedItemIds.contains(id) {
            itemsToDelete.insert(id)
        } else {
            newlyCreatedItemIds.remove(id)
        }

        budgetItems.removeAll { $0.id == id }
    }

    // MARK: Category Management

    func handleNewCategoryName(_ itemId: String, _ categoryName: String) async {
        guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        let existingCategory = budgetStore.categories.first {
            $0.categoryName == trimmedName && $0.parentCategoryId == nil
        }

        if existingCategory == nil {
            let newCategory = BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
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
            await budgetStore.addCategory(newCategory)
        }

        updateBudgetItem(itemId, field: "category", value: trimmedName)
        newCategoryNames.removeValue(forKey: itemId)
    }

    func handleNewSubcategoryName(_ itemId: String, _ subcategoryName: String) async {
        guard !subcategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let item = budgetItems.first(where: { $0.id == itemId }),
              !item.category.isEmpty else { return }

        let trimmedName = subcategoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let parentCategory = budgetStore.categories.first(where: {
            $0.categoryName == item.category && $0.parentCategoryId == nil
        }) else { return }

        let existingSubcategory = budgetStore.categories.first {
            $0.categoryName == trimmedName && $0.parentCategoryId == parentCategory.id
        }

        if existingSubcategory == nil {
            let newSubcategory = BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
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
            await budgetStore.addCategory(newSubcategory)
        }

        updateBudgetItem(itemId, field: "subcategory", value: trimmedName)
        newSubcategoryNames.removeValue(forKey: itemId)
    }

    func handleNewEventName(_ itemId: String, _: String) {
        newEventNames.removeValue(forKey: itemId)
    }
}
