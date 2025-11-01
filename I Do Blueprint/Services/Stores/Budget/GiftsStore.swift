//
//  GiftsStore.swift
//  I Do Blueprint
//
//  Extracted from BudgetStoreV2 as part of JES-42
//  Manages gifts and money owed operations with database persistence
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Store for managing gifts and money owed
/// Handles tracking of gifts received, money owed, and related operations
@MainActor
class GiftsStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var giftsAndOwed: [GiftOrOwed] = []
    @Published private(set) var giftsReceived: [GiftReceived] = []
    @Published private(set) var moneyOwed: [MoneyOwed] = []
    @Published var isLoading = false
    @Published var error: BudgetError?
    
    // MARK: - Dependencies
    
    @Dependency(\.budgetRepository) var repository
    private let logger = AppLogger.database
    
    // MARK: - Computed Properties
    
    /// Total amount of pending gifts and money owed
    var totalPending: Double {
        giftsAndOwed.reduce(0) { $0 + $1.amount }
    }
    
    /// Total amount of gifts received
    var totalReceived: Double {
        giftsReceived.reduce(0) { $0 + $1.amount }
    }
    
    /// Total amount of confirmed gifts
    var totalConfirmed: Double {
        giftsAndOwed.filter { $0.status == .confirmed }.reduce(0) { $0 + $1.amount }
    }
    
    /// Total budget addition from all gifts
    var totalBudgetAddition: Double {
        totalReceived + totalConfirmed
    }
    
    /// Gifts that are confirmed
    var confirmedGifts: [GiftOrOwed] {
        giftsAndOwed.filter { $0.status == .confirmed }
    }
    
    /// Gifts that are pending
    var pendingGifts: [GiftOrOwed] {
        giftsAndOwed.filter { $0.status == .pending }
    }
    
    // MARK: - Public Methods
    
    /// Load all gifts data including gifts received and money owed
    func loadGiftsData() async {
        do {
            async let giftsAndOwedTask = repository.fetchGiftsAndOwed()
            async let giftsReceivedTask = repository.fetchGiftsReceived()
            async let moneyOwedTask = repository.fetchMoneyOwed()
            
            giftsAndOwed = try await giftsAndOwedTask
            giftsReceived = try await giftsReceivedTask
            moneyOwed = try await moneyOwedTask
            
            logger.info("Loaded gifts data: \(giftsAndOwed.count) gifts/owed, \(giftsReceived.count) received, \(moneyOwed.count) owed")
        } catch {
            self.error = .fetchFailed(underlying: error)
            logger.error("Failed to load gifts data", error: error)
        }
    }
    
    // MARK: - Gifts and Owed Operations
    
    /// Add a new gift or owed item with database persistence
    func addGiftOrOwed(_ gift: GiftOrOwed) async {
        isLoading = true
        error = nil
        
        do {
            let created = try await repository.createGiftOrOwed(gift)
            giftsAndOwed.append(created)
            logger.info("Added gift or owed: \(created.id)")
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding gift or owed", error: error)
        }
        
        isLoading = false
    }
    
    /// Update an existing gift or owed item with database persistence
    func updateGiftOrOwed(_ gift: GiftOrOwed) async {
        isLoading = true
        error = nil
        
        do {
            let updated = try await repository.updateGiftOrOwed(gift)
            if let index = giftsAndOwed.firstIndex(where: { $0.id == updated.id }) {
                giftsAndOwed[index] = updated
            }
            logger.info("Updated gift or owed: \(updated.id)")
        } catch {
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating gift or owed", error: error)
        }
        
        isLoading = false
    }
    
    /// Delete a gift or owed item with database persistence
    func deleteGiftOrOwed(id: UUID) async {
        isLoading = true
        error = nil
        
        do {
            try await repository.deleteGiftOrOwed(id: id)
            giftsAndOwed.removeAll { $0.id == id }
            logger.info("Deleted gift or owed: \(id)")
        } catch {
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting gift or owed", error: error)
        }
        
        isLoading = false
    }
    
    // MARK: - Gifts Received Operations
    
    /// Add a new gift received with database persistence
    func addGiftReceived(_ gift: GiftReceived) async {
        isLoading = true
        error = nil
        
        do {
            let created = try await repository.createGiftReceived(gift)
            giftsReceived.append(created)
            logger.info("Added gift received: \(created.id)")
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding gift received", error: error)
        }
        
        isLoading = false
    }
    
    /// Update an existing gift received with database persistence
    func updateGiftReceived(_ gift: GiftReceived) async {
        isLoading = true
        error = nil
        
        do {
            let updated = try await repository.updateGiftReceived(gift)
            if let index = giftsReceived.firstIndex(where: { $0.id == updated.id }) {
                giftsReceived[index] = updated
            }
            logger.info("Updated gift received: \(updated.id)")
        } catch {
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating gift received", error: error)
        }
        
        isLoading = false
    }
    
    /// Delete a gift received with database persistence
    func deleteGiftReceived(id: UUID) async {
        isLoading = true
        error = nil
        
        do {
            try await repository.deleteGiftReceived(id: id)
            giftsReceived.removeAll { $0.id == id }
            logger.info("Deleted gift received: \(id)")
        } catch {
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting gift received", error: error)
        }
        
        isLoading = false
    }
    
    // MARK: - Money Owed Operations
    
    /// Add a new money owed item with database persistence
    func addMoneyOwed(_ money: MoneyOwed) async {
        isLoading = true
        error = nil
        
        do {
            let created = try await repository.createMoneyOwed(money)
            moneyOwed.append(created)
            logger.info("Added money owed: \(created.id)")
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding money owed", error: error)
        }
        
        isLoading = false
    }
    
    /// Update an existing money owed item with database persistence
    func updateMoneyOwed(_ money: MoneyOwed) async {
        isLoading = true
        error = nil
        
        do {
            let updated = try await repository.updateMoneyOwed(money)
            if let index = moneyOwed.firstIndex(where: { $0.id == updated.id }) {
                moneyOwed[index] = updated
            }
            logger.info("Updated money owed: \(updated.id)")
        } catch {
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating money owed", error: error)
        }
        
        isLoading = false
    }
    
    /// Delete a money owed item with database persistence
    func deleteMoneyOwed(id: UUID) async {
        isLoading = true
        error = nil
        
        do {
            try await repository.deleteMoneyOwed(id: id)
            moneyOwed.removeAll { $0.id == id }
            logger.info("Deleted money owed: \(id)")
        } catch {
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting money owed", error: error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    /// Get gifts linked to a specific scenario
    func giftsLinkedToScenario(_ scenarioId: UUID) -> [GiftOrOwed] {
        giftsAndOwed.filter { $0.scenarioId == scenarioId }
    }
    
    /// Get unlinked gifts (not associated with any scenario)
    var unlinkedGifts: [GiftOrOwed] {
        giftsAndOwed.filter { $0.scenarioId == nil }
    }
    
    /// Get total amount of gifts linked to a scenario
    func totalGiftsForScenario(_ scenarioId: UUID) -> Double {
        giftsLinkedToScenario(scenarioId).reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - State Management
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        giftsAndOwed = []
        giftsReceived = []
        moneyOwed = []
    }
}
