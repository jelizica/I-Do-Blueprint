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

    init(expense: Expense, categoryName: String) {
        self.categoryName = categoryName
        self.description = expense.expenseName
        self.amount = String(format: "$%.2f", expense.amount)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        self.date = dateFormatter.string(from: expense.expenseDate)

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

    var errorDescription: String? {
        switch self {
        case .noExpensesToExport:
            return "No expenses to export"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .fileCreationFailed:
            return "Failed to create export file"
        }
    }
}

// MARK: - Budget Export Service

@MainActor
class BudgetExportService {
    static let shared = BudgetExportService()

    private init() {}

    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
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

        // Create lookup dictionary for category names
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.categoryName) })

        let exportData = expenses.map { expense in
            let categoryName = categoryDict[expense.categoryId] ?? "Uncategorized"
            return BudgetExpenseExportData(expense: expense, categoryName: categoryName)
        }

        switch format {
        case .csv:
            return try await exportToCSV(exportData, fileName: fileName)
        case .pdf:
            return try await exportToPDF(exportData, expenses: expenses, categories: categories, fileName: fileName)
        }
    }

    // MARK: - CSV Export

    private func exportToCSV(
        _ exportData: [BudgetExpenseExportData],
        fileName: String?
    ) async throws -> URL {
        var csvContent = BudgetExpenseExportData.csvHeader + "\n"

        for data in exportData {
            csvContent += data.csvRow + "\n"
        }

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let actualFileName = fileName ?? "ExpenseReport_\(dateStamp)"
        let fileURL = tempDir.appendingPathComponent("\(actualFileName).csv")

        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    // MARK: - PDF Export

    private func exportToPDF(
        _ exportData: [BudgetExpenseExportData],
        expenses: [Expense],
        categories: [BudgetCategory],
        fileName: String?
    ) async throws -> URL {
        let pdfData = generatePDFData(for: exportData, expenses: expenses, categories: categories)

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let actualFileName = fileName ?? "ExpenseReport_\(dateStamp)"
        let fileURL = tempDir.appendingPathComponent("\(actualFileName).pdf")

        try pdfData.write(to: fileURL)

        return fileURL
    }

    // MARK: - PDF Generation

    private func generatePDFData(
        for exportData: [BudgetExpenseExportData],
        expenses: [Expense],
        categories: [BudgetCategory]
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
            text: "Generated on \(dateStamp)",
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
