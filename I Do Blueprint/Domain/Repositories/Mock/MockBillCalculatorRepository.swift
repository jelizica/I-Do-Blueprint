//
//  MockBillCalculatorRepository.swift
//  I Do Blueprint
//
//  Mock implementation for testing and previews
//

import Foundation

// MARK: - Mock Bill Calculator Repository

class MockBillCalculatorRepository: BillCalculatorRepositoryProtocol {
    var calculators: [BillCalculator] = []
    var taxInfoOptions: [TaxInfo] = []
    var shouldThrowError = false
    var errorToThrow: Error = MockBillCalculatorRepositoryError.operationFailed

    // MARK: - Calculator Operations

    func fetchCalculators() async throws -> [BillCalculator] {
        if shouldThrowError {
            throw errorToThrow
        }
        return calculators.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func fetchCalculator(id: UUID) async throws -> BillCalculator {
        if shouldThrowError {
            throw errorToThrow
        }
        guard let calculator = calculators.first(where: { $0.id == id }) else {
            throw MockBillCalculatorRepositoryError.calculatorNotFound
        }
        return calculator
    }

    func fetchCalculatorsByVendor(vendorId: Int64) async throws -> [BillCalculator] {
        if shouldThrowError {
            throw errorToThrow
        }
        return calculators
            .filter { $0.vendorId == vendorId }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func createCalculator(_ calculator: BillCalculator) async throws -> BillCalculator {
        if shouldThrowError {
            throw errorToThrow
        }

        let now = Date()
        var newCalculator = calculator
        newCalculator = BillCalculator(
            id: calculator.id,
            coupleId: calculator.coupleId,
            name: calculator.name,
            vendorId: calculator.vendorId,
            eventId: calculator.eventId,
            taxInfoId: calculator.taxInfoId,
            guestCount: calculator.guestCount,
            notes: calculator.notes,
            createdAt: now,
            updatedAt: now,
            vendorName: calculator.vendorName,
            eventName: calculator.eventName,
            taxRate: calculator.taxRate,
            taxRegion: calculator.taxRegion,
            items: calculator.items
        )
        calculators.append(newCalculator)
        return newCalculator
    }

    func updateCalculator(_ calculator: BillCalculator) async throws -> BillCalculator {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = calculators.firstIndex(where: { $0.id == calculator.id }) else {
            throw MockBillCalculatorRepositoryError.calculatorNotFound
        }

        var updatedCalculator = calculator
        updatedCalculator = BillCalculator(
            id: calculator.id,
            coupleId: calculator.coupleId,
            name: calculator.name,
            vendorId: calculator.vendorId,
            eventId: calculator.eventId,
            taxInfoId: calculator.taxInfoId,
            guestCount: calculator.guestCount,
            notes: calculator.notes,
            createdAt: calculators[index].createdAt,
            updatedAt: Date(),
            vendorName: calculator.vendorName,
            eventName: calculator.eventName,
            taxRate: calculator.taxRate,
            taxRegion: calculator.taxRegion,
            items: calculator.items
        )
        calculators[index] = updatedCalculator
        return updatedCalculator
    }

    func deleteCalculator(id: UUID) async throws {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = calculators.firstIndex(where: { $0.id == id }) else {
            throw MockBillCalculatorRepositoryError.calculatorNotFound
        }

        calculators.remove(at: index)
    }

    // MARK: - Item Operations

    func createItem(_ item: BillCalculatorItem) async throws -> BillCalculatorItem {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let calculatorIndex = calculators.firstIndex(where: { $0.id == item.calculatorId }) else {
            throw MockBillCalculatorRepositoryError.calculatorNotFound
        }

        let now = Date()
        let newItem = BillCalculatorItem(
            id: item.id,
            calculatorId: item.calculatorId,
            coupleId: item.coupleId,
            type: item.type,
            name: item.name,
            amount: item.amount,
            sortOrder: item.sortOrder,
            createdAt: now,
            updatedAt: now
        )

        var calculator = calculators[calculatorIndex]
        var items = calculator.items
        items.append(newItem)

        calculators[calculatorIndex] = BillCalculator(
            id: calculator.id,
            coupleId: calculator.coupleId,
            name: calculator.name,
            vendorId: calculator.vendorId,
            eventId: calculator.eventId,
            taxInfoId: calculator.taxInfoId,
            guestCount: calculator.guestCount,
            notes: calculator.notes,
            createdAt: calculator.createdAt,
            updatedAt: Date(),
            vendorName: calculator.vendorName,
            eventName: calculator.eventName,
            taxRate: calculator.taxRate,
            taxRegion: calculator.taxRegion,
            items: items
        )

        return newItem
    }

    func updateItem(_ item: BillCalculatorItem) async throws -> BillCalculatorItem {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let calculatorIndex = calculators.firstIndex(where: { $0.id == item.calculatorId }) else {
            throw MockBillCalculatorRepositoryError.calculatorNotFound
        }

        var calculator = calculators[calculatorIndex]
        var items = calculator.items

        guard let itemIndex = items.firstIndex(where: { $0.id == item.id }) else {
            throw MockBillCalculatorRepositoryError.itemNotFound
        }

        let updatedItem = BillCalculatorItem(
            id: item.id,
            calculatorId: item.calculatorId,
            coupleId: item.coupleId,
            type: item.type,
            name: item.name,
            amount: item.amount,
            sortOrder: item.sortOrder,
            createdAt: items[itemIndex].createdAt,
            updatedAt: Date()
        )
        items[itemIndex] = updatedItem

        calculators[calculatorIndex] = BillCalculator(
            id: calculator.id,
            coupleId: calculator.coupleId,
            name: calculator.name,
            vendorId: calculator.vendorId,
            eventId: calculator.eventId,
            taxInfoId: calculator.taxInfoId,
            guestCount: calculator.guestCount,
            notes: calculator.notes,
            createdAt: calculator.createdAt,
            updatedAt: Date(),
            vendorName: calculator.vendorName,
            eventName: calculator.eventName,
            taxRate: calculator.taxRate,
            taxRegion: calculator.taxRegion,
            items: items
        )

        return updatedItem
    }

    func deleteItem(id: UUID) async throws {
        if shouldThrowError {
            throw errorToThrow
        }

        // Find the calculator containing this item
        for (calculatorIndex, calculator) in calculators.enumerated() {
            if let itemIndex = calculator.items.firstIndex(where: { $0.id == id }) {
                var items = calculator.items
                items.remove(at: itemIndex)

                calculators[calculatorIndex] = BillCalculator(
                    id: calculator.id,
                    coupleId: calculator.coupleId,
                    name: calculator.name,
                    vendorId: calculator.vendorId,
                    eventId: calculator.eventId,
                    taxInfoId: calculator.taxInfoId,
                    guestCount: calculator.guestCount,
                    notes: calculator.notes,
                    createdAt: calculator.createdAt,
                    updatedAt: Date(),
                    vendorName: calculator.vendorName,
                    eventName: calculator.eventName,
                    taxRate: calculator.taxRate,
                    taxRegion: calculator.taxRegion,
                    items: items
                )
                return
            }
        }

        throw MockBillCalculatorRepositoryError.itemNotFound
    }

    func createItems(_ items: [BillCalculatorItem]) async throws -> [BillCalculatorItem] {
        if shouldThrowError {
            throw errorToThrow
        }

        var createdItems: [BillCalculatorItem] = []
        for item in items {
            let created = try await createItem(item)
            createdItems.append(created)
        }
        return createdItems
    }

    // MARK: - Reference Data

    func fetchTaxInfoOptions() async throws -> [TaxInfo] {
        if shouldThrowError {
            throw errorToThrow
        }
        return taxInfoOptions.sorted { $0.region < $1.region }
    }
}

// MARK: - Mock Errors

enum MockBillCalculatorRepositoryError: Error, LocalizedError {
    case operationFailed
    case calculatorNotFound
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .operationFailed:
            "Mock operation failed"
        case .calculatorNotFound:
            "Calculator not found"
        case .itemNotFound:
            "Item not found"
        }
    }
}
