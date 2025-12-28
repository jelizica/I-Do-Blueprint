//
//  BudgetExportService.swift
//  My Wedding Planning App
//
//  Service for exporting budget and expense reports to multiple formats
//

import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers
import TPPDF

// MARK: - Export Format

enum BudgetExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF"

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        }
    }

    var iconName: String {
        switch self {
        case .csv: return "tablecells.fill"
        case .pdf: return "doc.fill"
        }
    }
}

// MARK: - Export Data Model

struct BudgetExpenseExportData: Codable {
    let categoryName: String
    let description: String
    let amount: String
    let date: String
    let paymentMethod: String
    let vendor: String
    let notes: String

    init(expense: Expense, categoryName: String, userTimezone: TimeZone) {
        self.categoryName = categoryName
        self.description = expense.expenseName
        self.amount = String(format: "$%.2f", expense.amount)

        // Use provided timezone for export date formatting
        self.date = DateFormatting.formatDateMedium(expense.expenseDate, timezone: userTimezone)

        self.paymentMethod = expense.paymentMethod ?? "N/A"
        self.vendor = expense.vendorName ?? "N/A"
        self.notes = expense.notes ?? ""
    }

    var csvRow: String {
        let fields = [
            categoryName,
            description,
            amount,
            date,
            paymentMethod,
            vendor,
            notes
        ]
        return fields.map { field in
            if field.contains(",") || field.contains("\"") || field.contains("\n") {
                return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return field
        }.joined(separator: ",")
    }

    static var csvHeader: String {
        [
            "Category",
            "Description",
            "Amount",
            "Date",
            "Payment Method",
            "Vendor",
            "Notes"
        ].joined(separator: ",")
    }
}

// MARK: - Export Error

enum BudgetExportError: LocalizedError {
    case noExpensesToExport
    case exportFailed(Error)
    case fileCreationFailed
    case pdfGenerationFailed

    var errorDescription: String? {
        switch self {
        case .noExpensesToExport:
            return "No expenses to export"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .fileCreationFailed:
            return "Failed to create export file"
        case .pdfGenerationFailed:
            return "PDF generation failed: The generated PDF data is empty"
        }
    }
}

// MARK: - Budget Export Service

@MainActor
class BudgetExportService {
    static let shared = BudgetExportService()

    private init() {}

    /// Generates a timestamp string for export operations.
    /// - Note: This should not be called directly. Use the timestamp parameter in export methods.
    private func generateDateStamp() -> String {
        // Use user's timezone for export timestamp
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        return DateFormatting.formatDate(Date(), format: "yyyy-MM-dd", timezone: userTimezone)
    }

    // MARK: - Main Export Method

    func exportExpenses(
        expenses: [Expense],
        categories: [BudgetCategory],
        format: BudgetExportFormat,
        fileName: String? = nil
    ) async throws -> URL {
        guard !expenses.isEmpty else {
            throw BudgetExportError.noExpensesToExport
        }

        // Generate timestamp once at export start to ensure consistency
        let timestamp = generateDateStamp()
        
        // Compute user timezone once for all expense data
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)

        // Create lookup dictionary for category names
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.categoryName) })

        let exportData = expenses.map { expense in
            let categoryName = categoryDict[expense.categoryId] ?? "Uncategorized"
            return BudgetExpenseExportData(expense: expense, categoryName: categoryName, userTimezone: userTimezone)
        }

        switch format {
        case .csv:
            return try await exportToCSV(exportData, fileName: fileName, timestamp: timestamp)
        case .pdf:
            return try await exportToPDF(exportData, expenses: expenses, categories: categories, fileName: fileName, timestamp: timestamp)
        }
    }

    // MARK: - CSV Export

    private func exportToCSV(
        _ exportData: [BudgetExpenseExportData],
        fileName: String?,
        timestamp: String
    ) async throws -> URL {
        var csvContent = BudgetExpenseExportData.csvHeader + "\n"

        for data in exportData {
            csvContent += data.csvRow + "\n"
        }

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let actualFileName = fileName ?? "ExpenseReport_\(timestamp)"
        let fileURL = tempDir.appendingPathComponent("\(actualFileName).csv")

        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    // MARK: - PDF Export

    private func exportToPDF(
        _ exportData: [BudgetExpenseExportData],
        expenses: [Expense],
        categories: [BudgetCategory],
        fileName: String?,
        timestamp: String
    ) async throws -> URL {
        let pdfData = generatePDFData(for: exportData, expenses: expenses, categories: categories, timestamp: timestamp)

        // Validate that PDF generation succeeded
        guard !pdfData.isEmpty else {
            AppLogger.ui.error("PDF generation failed: Generated PDF data is empty")
            throw BudgetExportError.pdfGenerationFailed
        }

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let actualFileName = fileName ?? "ExpenseReport_\(timestamp)"
        let fileURL = tempDir.appendingPathComponent("\(actualFileName).pdf")

        try pdfData.write(to: fileURL)

        AppLogger.ui.info("Successfully exported PDF to \(fileURL.path)")
        return fileURL
    }

    // MARK: - PDF Generation

    private func generatePDFData(
        for exportData: [BudgetExpenseExportData],
        expenses: [Expense],
        categories: [BudgetCategory],
        timestamp: String
    ) -> Data {
        let document = PDFDocument(format: .usLetter)
        document.layout.margin = NSEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)

        // Header
        document.add(.contentCenter, textObject: PDFSimpleText(
            text: "Expense Report",
            style: PDFTextStyle(
                name: "Header",
                font: NSFont.boldSystemFont(ofSize: 28),
                color: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
            )
        ))

        document.add(space: 10)

        // Date
        document.add(.contentCenter, textObject: PDFSimpleText(
            text: "Generated on \(timestamp)",
            style: PDFTextStyle(
                name: "Date",
                font: NSFont.systemFont(ofSize: 12),
                color: NSColor.gray
            )
        ))

        document.add(space: 20)

        // Summary Section
        let totalSpent = expenses.reduce(0.0) { $0 + $1.amount }
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        document.add(.contentLeft, textObject: PDFSimpleText(
            text: "Summary",
            style: PDFTextStyle(
                name: "SectionHeader",
                font: NSFont.boldSystemFont(ofSize: 18),
                color: NSColor.black
            )
        ))

        document.add(space: 8)

        document.add(.contentLeft, textObject: PDFSimpleText(
            text: "Total Expenses: \(String(format: "$%.2f", totalSpent))",
            style: PDFTextStyle(
                name: "Summary",
                font: NSFont.systemFont(ofSize: 14),
                color: NSColor.darkGray
            )
        ))

        document.add(.contentLeft, textObject: PDFSimpleText(
            text: "Number of Transactions: \(expenses.count)",
            style: PDFTextStyle(
                name: "Summary",
                font: NSFont.systemFont(ofSize: 14),
                color: NSColor.darkGray
            )
        ))

        document.add(space: 20)

        // Expenses by Category
        document.add(.contentLeft, textObject: PDFSimpleText(
            text: "Detailed Expenses",
            style: PDFTextStyle(
                name: "SectionHeader",
                font: NSFont.boldSystemFont(ofSize: 18),
                color: NSColor.black
            )
        ))

        document.add(space: 10)

        // Group expenses by category
        let groupedExpenses = Dictionary(grouping: exportData) { $0.categoryName }
        let sortedCategories = groupedExpenses.keys.sorted()

        for categoryName in sortedCategories {
            guard let categoryExpenses = groupedExpenses[categoryName] else { continue }

            let categoryTotal = categoryExpenses.reduce(0.0) { total, data in
                let amountString = data.amount.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                return total + (Double(amountString) ?? 0.0)
            }

            document.add(.contentLeft, textObject: PDFSimpleText(
                text: "\(categoryName) - \(String(format: "$%.2f", categoryTotal))",
                style: PDFTextStyle(
                    name: "CategoryHeader",
                    font: NSFont.boldSystemFont(ofSize: 14),
                    color: NSColor.black
                )
            ))

            document.add(space: 5)

            for data in categoryExpenses.sorted(by: { $0.date > $1.date }) {
                document.add(.contentLeft, textObject: PDFSimpleText(
                    text: "  • \(data.description) - \(data.amount) (\(data.date))",
                    style: PDFTextStyle(
                        name: "ExpenseItem",
                        font: NSFont.systemFont(ofSize: 11),
                        color: NSColor.darkGray
                    )
                ))

                if !data.vendor.isEmpty && data.vendor != "N/A" {
                    document.add(.contentLeft, textObject: PDFSimpleText(
                        text: "    Vendor: \(data.vendor)",
                        style: PDFTextStyle(
                            name: "ExpenseDetail",
                            font: NSFont.systemFont(ofSize: 10),
                            color: NSColor.gray
                        )
                    ))
                }
            }

            document.add(space: 10)
        }

        let generator = PDFGenerator(document: document)

        do {
            return try generator.generateData()
        } catch {
            // Return empty data on failure - caller will handle
            return Data()
        }
    }

    // MARK: - Share Sheet

    func showShareSheet(for fileURL: URL) {
        let picker = NSSavePanel()
        picker.allowedContentTypes = [UTType(filenameExtension: fileURL.pathExtension)].compactMap { $0 }
        picker.nameFieldStringValue = fileURL.lastPathComponent

        picker.begin { response in
            if response == .OK, let destinationURL = picker.url {
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: fileURL, to: destinationURL)

                    // Open the file location
                    NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
                } catch {
                    AppLogger.ui.error("Failed to save file", error: error)
                }
            }
        }
    }
}
