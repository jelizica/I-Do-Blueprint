//
//  VendorExportService.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/2/25.
//  Service for exporting vendor contact information to multiple formats
//

import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers
import TPPDF

// MARK: - Export Format

enum VendorExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF"
    case googleSheets = "Google Sheets"

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .googleSheets: return "csv" // Google Sheets imports CSV
        }
    }

    var iconName: String {
        switch self {
        case .csv: return "doc.text"
        case .pdf: return "doc.richtext"
        case .googleSheets: return "square.grid.3x3.fill"
        }
    }
}

// MARK: - Export Data Model

struct VendorContactExportData: Codable {
    let vendorName: String
    let contactName: String
    let phoneNumber: String
    let email: String
    let vendorType: String
    let quotedAmount: String
    let website: String
    let notes: String
    let bookingStatus: String

    init(from vendor: Vendor) {
        self.vendorName = vendor.vendorName
        self.contactName = vendor.contactName ?? ""
        self.phoneNumber = vendor.phoneNumber ?? ""
        self.email = vendor.email ?? ""
        self.vendorType = vendor.vendorType ?? ""
        self.quotedAmount = vendor.quotedAmount.map { String(format: "$%.2f", $0) } ?? ""
        self.website = vendor.website ?? ""
        self.notes = vendor.notes ?? ""
        self.bookingStatus = vendor.isBooked == true ? "Booked" : "Available"
    }

    var csvRow: String {
        let fields = [
            vendorName,
            contactName,
            phoneNumber,
            email,
            vendorType,
            quotedAmount,
            website,
            bookingStatus,
            notes
        ]
        // Properly escape CSV fields (handle commas and quotes)
        return fields.map { field in
            if field.contains(",") || field.contains("\"") || field.contains("\n") {
                return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return field
        }.joined(separator: ",")
    }

    static var csvHeader: String {
        [
            "Vendor Name",
            "Contact Name",
            "Phone Number",
            "Email",
            "Vendor Type",
            "Quoted Amount",
            "Website",
            "Booking Status",
            "Notes"
        ].joined(separator: ",")
    }
}

// MARK: - Vendor Export Service

@MainActor
class VendorExportService {
    static let shared = VendorExportService()
    private let logger = AppLogger.export

    private init() {}

    // MARK: - Main Export Method

    func exportVendors(
        _ vendors: [Vendor],
        format: VendorExportFormat,
        fileName: String? = nil
    ) async throws -> URL {
        // Filter vendors marked for export
        let exportableVendors = vendors.filter { $0.includeInExport && !$0.isArchived }

        guard !exportableVendors.isEmpty else {
            throw VendorExportError.noVendorsToExport
        }

        let exportData = exportableVendors.map { VendorContactExportData(from: $0) }

        switch format {
        case .csv, .googleSheets:
            return try await exportToCSV(exportData, fileName: fileName)
        case .pdf:
            return try await exportToPDF(exportData, fileName: fileName)
        }
    }

    // MARK: - CSV Export

    private func exportToCSV(
        _ vendors: [VendorContactExportData],
        fileName: String?
    ) async throws -> URL {
        var csvContent = VendorContactExportData.csvHeader + "\n"

        for vendor in vendors {
            csvContent += vendor.csvRow + "\n"
        }

        // Save to temporary file
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let actualFileName = fileName ?? "VendorContacts_\(dateStamp)"
        let fileURL = tempDir.appendingPathComponent("\(actualFileName).csv")

        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    // MARK: - PDF Export

    private func exportToPDF(
        _ vendors: [VendorContactExportData],
        fileName: String?
    ) async throws -> URL {
        let pdfData = generatePDFData(for: vendors)

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let actualFileName = fileName ?? "VendorContacts_\(dateStamp)"
        let fileURL = tempDir.appendingPathComponent("\(actualFileName).pdf")

        try pdfData.write(to: fileURL)

        return fileURL
    }

    // MARK: - PDF Generation (Using TPPDF)

    private func generatePDFData(for vendors: [VendorContactExportData]) -> Data {
        let document = PDFDocument(format: .usLetter)

        // Set margins
        document.layout.margin = NSEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)

        // Add header
        document.add(.contentCenter, textObject: PDFSimpleText(
            text: "Vendor Contact List",
            style: PDFTextStyle(
                name: "Header",
                font: NSFont.boldSystemFont(ofSize: 28),
                color: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
            )
        ))

        document.add(space: 10)

        // Add date
        document.add(.contentCenter, textObject: PDFSimpleText(
            text: "Generated on \(dateStamp)",
            style: PDFTextStyle(
                name: "Date",
                font: NSFont.systemFont(ofSize: 12),
                color: NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            )
        ))

        document.add(space: 30)

        // Create vendor cards in 2-column sections
        var index = 0
        while index < vendors.count {
            let section = PDFSection(columnWidths: [0.48, 0.48])

            // Add first vendor to left column
            addVendorToSection(section, column: 0, vendor: vendors[index])

            // Add second vendor to right column if available
            if index + 1 < vendors.count {
                addVendorToSection(section, column: 1, vendor: vendors[index + 1])
            }

            document.add(section: section)
            document.add(space: 20)

            index += 2
        }

        // Generate PDF
        let generator = PDFGenerator(document: document)
        do {
            let data = try generator.generateData()
            return data
        } catch {
            logger.error("Error generating PDF", error: error)
            return Data()
        }
    }

    private func addVendorToSection(_ section: PDFSection, column: Int, vendor: VendorContactExportData) {
        // Card with group for background
        let group = PDFGroup(
            allowsBreaks: false,
            backgroundColor: NSColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0),
            padding: NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )

        // Vendor name
        group.set(font: NSFont.boldSystemFont(ofSize: 16))
        group.set(textColor: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        group.add(text: vendor.vendorName)

        group.add(space: 5)

        // Vendor type and status
        let statusBadge = vendor.bookingStatus == "Booked" ? "● Booked" : "○ Available"
        group.set(font: NSFont.systemFont(ofSize: 12))
        group.set(textColor: NSColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1.0))
        group.add(text: "\(vendor.vendorType)  \(statusBadge)")

        // Separator line
        group.addLineSeparator(style: PDFLineStyle(
            type: .full,
            color: NSColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.0),
            width: 2
        ))

        group.add(space: 8)

        // Contact details
        group.set(font: NSFont.systemFont(ofSize: 11))

        if !vendor.contactName.isEmpty {
            let attr = createDetailAttributedString(label: "Contact:", value: vendor.contactName)
            group.add(attributedText: attr)
        }
        if !vendor.phoneNumber.isEmpty {
            let attr = createDetailAttributedString(label: "Phone:", value: vendor.phoneNumber)
            group.add(attributedText: attr)
        }
        if !vendor.email.isEmpty {
            let attr = createDetailAttributedString(label: "Email:", value: vendor.email)
            group.add(attributedText: attr)
        }
        if !vendor.website.isEmpty {
            let attr = createDetailAttributedString(label: "Website:", value: vendor.website)
            group.add(attributedText: attr)
        }

        // Quoted amount
        if !vendor.quotedAmount.isEmpty {
            group.add(space: 10)
            group.set(font: NSFont.boldSystemFont(ofSize: 14))
            group.set(textColor: NSColor(red: 0.08, green: 0.5, blue: 0.24, alpha: 1.0))
            group.add(text: vendor.quotedAmount)
        }

        // Notes
        if !vendor.notes.isEmpty {
            group.add(space: 10)
            group.set(font: NSFont.systemFont(ofSize: 10))
            group.set(textColor: NSColor(red: 0.57, green: 0.4, blue: 0.05, alpha: 1.0))
            group.add(text: "Notes: \(vendor.notes)")
        }

        section.columns[column].add(group: group)
    }

    private func createDetailAttributedString(label: String, value: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()

        // Label (bold)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor(red: 0.22, green: 0.25, blue: 0.32, alpha: 1.0)
        ]
        attributedString.append(NSAttributedString(string: label + " ", attributes: labelAttributes))

        // Value
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1.0)
        ]
        attributedString.append(NSAttributedString(string: value, attributes: valueAttributes))

        return attributedString
    }


    // MARK: - Google Sheets Integration

    func exportToGoogleSheets(
        _ vendors: [VendorContactExportData],
        googleIntegration: GoogleIntegrationManager
    ) async throws -> String {
        let sheetTitle = "Vendor Contacts - \(dateStamp)"

        // Convert vendor data to rows
        var rows: [[Any]] = []

        // Header row
        rows.append([
            "Vendor Name",
            "Contact Name",
            "Phone Number",
            "Email",
            "Vendor Type",
            "Quoted Amount",
            "Website",
            "Booking Status",
            "Notes"
        ])

        // Data rows
        for vendor in vendors {
            rows.append([
                vendor.vendorName,
                vendor.contactName,
                vendor.phoneNumber,
                vendor.email,
                vendor.vendorType,
                vendor.quotedAmount,
                vendor.website,
                vendor.bookingStatus,
                vendor.notes
            ])
        }

        // Create spreadsheet using Google Sheets API
        let spreadsheetId = try await googleIntegration.sheetsManager.createSpreadsheet(
            title: sheetTitle,
            rows: rows
        )

        return spreadsheetId
    }

    // MARK: - File Operations

    func saveFileWithDialog(sourceURL: URL, suggestedName: String) async throws -> URL {
        // The file is already in a temp directory, just return it
        // We'll open it directly from there
        return sourceURL
    }

    func openFile(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    // MARK: - Alert Helpers

    @MainActor
    func showExportSuccessAlert(format: VendorExportFormat, fileURL: URL? = nil, completion: @escaping (Bool) -> Void) {
        AlertPresenter.shared.showAlert(
            title: "\(format.rawValue) Export Complete",
            message: "The file has been opened. You can save it from the opened application.",
            style: .informational,
            buttons: ["OK"]
        ) { _ in
            completion(false)
        }
    }

    @MainActor
    func showGoogleSheetsSuccessAlert(spreadsheetId: String, completion: @escaping (Bool) -> Void) {
        let sheetURL = "https://docs.google.com/spreadsheets/d/\(spreadsheetId)"
        AlertPresenter.shared.showAlert(
            title: "Google Sheet Created",
            message: "Vendor contact list exported successfully.\n\n\(sheetURL)\n\nClick 'Open in Browser' to view the sheet.",
            style: .informational,
            buttons: ["Open in Browser", "Close"]
        ) { response in
            if response == "Open in Browser" {
                NSWorkspace.shared.open(URL(string: sheetURL)!)
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    @MainActor
    func showExportErrorAlert(error: Error) {
        if let vendorError = error as? VendorExportError {
            AlertPresenter.shared.showAlert(
                title: "Export Error",
                message: vendorError.errorDescription ?? "Unknown error occurred",
                style: .warning,
                buttons: ["OK"]
            )
        } else {
            AlertPresenter.shared.showAlert(
                title: "Export Failed",
                message: error.localizedDescription,
                style: .warning,
                buttons: ["OK"]
            )
        }
    }

    // MARK: - Utilities

    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Errors

enum VendorExportError: LocalizedError {
    case noVendorsToExport
    case userCancelled
    case googleSheetsRequiresManualImport

    var errorDescription: String? {
        switch self {
        case .noVendorsToExport:
            return "No vendors are marked for export. Please select vendors to export in the vendor list."
        case .userCancelled:
            return "Export cancelled"
        case .googleSheetsRequiresManualImport:
            return "CSV data has been copied to your clipboard. Please paste it into the new Google Sheet that just opened."
        }
    }
}
