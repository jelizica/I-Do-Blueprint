import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Helper class for budget export operations
class BudgetExportHelper: ObservableObject {
    private let logger = AppLogger.ui

    // MARK: - JSON Export

    func exportAsJSON(
        budgetName: String,
        budgetItems: [BudgetItem],
        totalWithoutTax: Double,
        totalTax: Double,
        totalWithTax: Double
    ) {
        let budgetData = BudgetExportData(
            name: budgetName,
            items: budgetItems,
            totals: BudgetTotals(
                totalWithoutTax: totalWithoutTax,
                totalTax: totalTax,
                totalWithTax: totalWithTax),
            exportDate: Date())

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(budgetData)

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(budgetName.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).json"
            savePanel.message = "Export Budget as JSON"
            savePanel.prompt = "Export"

            savePanel.begin { [weak self] response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try jsonData.write(to: url)
                        self?.logger.info("Successfully exported budget to: \(url.path)")
                    } catch {
                        self?.logger.error("Failed to write budget file", error: error)
                    }
                }
            }
        } catch {
            logger.error("Failed to encode budget data", error: error)
        }
    }

    // MARK: - CSV Export

    func exportAsCSV(
        budgetName: String,
        budgetItems: [BudgetItem],
        totalWithoutTax: Double,
        totalTax: Double,
        totalWithTax: Double,
        weddingEvents: [WeddingEvent]
    ) {
        let csvString = generateCSVString(
            budgetItems: budgetItems,
            totalWithoutTax: totalWithoutTax,
            totalTax: totalTax,
            totalWithTax: totalWithTax,
            weddingEvents: weddingEvents)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "\(budgetName.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"
        savePanel.message = "Export Budget as CSV"
        savePanel.prompt = "Export"

        savePanel.begin { [weak self] response in
            if response == .OK, let url = savePanel.url {
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    self?.logger.info("Successfully exported budget to: \(url.path)")
                } catch {
                    self?.logger.error("Failed to write CSV file", error: error)
                }
            }
        }
    }

    // MARK: - Google Drive Export

    func exportToGoogleDrive(
        budgetName: String,
        budgetItems: [BudgetItem],
        totalWithoutTax: Double,
        totalTax: Double,
        totalWithTax: Double,
        weddingEvents: [WeddingEvent],
        googleIntegration: GoogleIntegrationManager
    ) async throws {
        let csvString = generateCSVString(
            budgetItems: budgetItems,
            totalWithoutTax: totalWithoutTax,
            totalTax: totalTax,
            totalWithTax: totalWithTax,
            weddingEvents: weddingEvents)

        guard let csvData = csvString.data(using: .utf8) else {
            throw NSError(
                domain: "BudgetExport",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode CSV data"])
        }

        let fileName = "\(budgetName.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"

        let fileId = try await googleIntegration.driveManager.uploadCSV(data: csvData, fileName: fileName)

        logger.info("Successfully uploaded to Google Drive: \(fileId)")
    }

    // MARK: - Google Sheets Export

    func exportToGoogleSheets(
        budgetName: String,
        budgetItems: [BudgetItem],
        totalWithoutTax: Double,
        totalTax: Double,
        totalWithTax: Double,
        weddingEvents: [WeddingEvent],
        googleIntegration: GoogleIntegrationManager
    ) async throws -> String {
        let sheetTitle = "\(budgetName) - \(Date().formatted(date: .abbreviated, time: .omitted))"

        let spreadsheetId = try await googleIntegration.sheetsManager.createSpreadsheetFromBudget(
            title: sheetTitle,
            items: budgetItems,
            totals: BudgetTotals(
                totalWithoutTax: totalWithoutTax,
                totalTax: totalTax,
                totalWithTax: totalWithTax),
            weddingEvents: weddingEvents)

        logger.info("Successfully created Google Sheet: \(spreadsheetId)")

        return spreadsheetId
    }

    // MARK: - Helper Methods

    func generateCSVString(
        budgetItems: [BudgetItem],
        totalWithoutTax: Double,
        totalTax: Double,
        totalWithTax: Double,
        weddingEvents: [WeddingEvent]
    ) -> String {
        var csvString = "Item Name,Category,Subcategory,Events,Estimate (No Tax),Tax Rate %,Estimate (With Tax),Person Responsible,Notes\n"

        for item in budgetItems {
            let eventNames = (item.eventIds ?? [])
                .compactMap { eventId in
                    weddingEvents.first(where: { $0.id == eventId })?.eventName
                }
                .joined(separator: "; ")

            let row = [
                escapeCSV(item.itemName),
                escapeCSV(item.category),
                escapeCSV(item.subcategory ?? ""),
                escapeCSV(eventNames),
                String(format: "%.2f", item.vendorEstimateWithoutTax),
                String(format: "%.2f", item.taxRate),
                String(format: "%.2f", item.vendorEstimateWithTax),
                escapeCSV(item.personResponsible ?? ""),
                escapeCSV(item.notes ?? "")
            ].joined(separator: ",")

            csvString += row + "\n"
        }

        csvString += "\n"
        csvString += "SUMMARY\n"
        csvString += "Total Without Tax,,,,,,$\(String(format: "%.2f", totalWithoutTax))\n"
        csvString += "Total Tax,,,,,,$\(String(format: "%.2f", totalTax))\n"
        csvString += "Total With Tax,,,,,,$\(String(format: "%.2f", totalWithTax))\n"
        csvString += "\n"
        csvString += "Exported on,\(Date().formatted(date: .long, time: .shortened))\n"

        return csvString
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
