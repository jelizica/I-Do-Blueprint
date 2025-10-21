//
//  BudgetExportActions.swift
//  I Do Blueprint
//
//  Export actions for budget development
//

import Foundation

// MARK: - Budget Export Actions

extension BudgetDevelopmentView {
    
    // MARK: Tax Rate
    
    func handleAddCustomTaxRate() {
        showingTaxRateDialog = false
    }
    
    // MARK: Local Export
    
    func exportBudgetAsJSON() {
        exportHelper.exportAsJSON(
            budgetName: budgetName,
            budgetItems: budgetItems,
            totalWithoutTax: totalWithoutTax,
            totalTax: totalTax,
            totalWithTax: totalWithTax)
    }
    
    func exportBudgetAsCSV() {
        exportHelper.exportAsCSV(
            budgetName: budgetName,
            budgetItems: budgetItems,
            totalWithoutTax: totalWithoutTax,
            totalTax: totalTax,
            totalWithTax: totalWithTax,
            weddingEvents: budgetStore.weddingEvents)
    }
    
    // MARK: Google Export
    
    func signInToGoogle() async {
        do {
            try await googleIntegration.authManager.authenticate()
            logger.info("Successfully signed in to Google")
        } catch {
            logger.error("Failed to sign in to Google", error: error)
        }
    }
    
    func exportToGoogleDrive() async {
        do {
            try await exportHelper.exportToGoogleDrive(
                budgetName: budgetName,
                budgetItems: budgetItems,
                totalWithoutTax: totalWithoutTax,
                totalTax: totalTax,
                totalWithTax: totalWithTax,
                weddingEvents: budgetStore.weddingEvents,
                googleIntegration: googleIntegration)
        } catch {
            logger.error("Failed to upload to Google Drive", error: error)
        }
    }
    
    func exportToGoogleSheets() async {
        do {
            _ = try await exportHelper.exportToGoogleSheets(
                budgetName: budgetName,
                budgetItems: budgetItems,
                totalWithoutTax: totalWithoutTax,
                totalTax: totalTax,
                totalWithTax: totalWithTax,
                weddingEvents: budgetStore.weddingEvents,
                googleIntegration: googleIntegration)
        } catch {
            logger.error("Failed to create Google Sheet", error: error)
        }
    }
}
