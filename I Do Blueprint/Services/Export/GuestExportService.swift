//
//  GuestExportService.swift
//  I Do Blueprint
//
//  Service for exporting guest list to multiple formats
//

import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers
import TPPDF

// MARK: - Export Format

enum GuestExportFormat: String, CaseIterable {
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

struct GuestExportData: Codable {
    let fullName: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let rsvpStatus: String
    let invitedBy: String
    let tableAssignment: String
    let mealOption: String
    let dietaryRestrictions: String
    let plusOneAllowed: String
    let plusOneName: String
    let plusOneAttending: String
    let addressLine1: String
    let city: String
    let state: String
    let zipCode: String
    let notes: String

    init(from guest: Guest, settings: CoupleSettings) {
        self.fullName = guest.fullName
        self.firstName = guest.firstName
        self.lastName = guest.lastName
        self.email = guest.email ?? ""
        self.phone = guest.phone ?? ""
        self.rsvpStatus = guest.rsvpStatus.displayName
        self.invitedBy = guest.invitedBy?.displayName(with: settings) ?? ""
        self.tableAssignment = guest.tableAssignment.map { String($0) } ?? ""
        self.mealOption = guest.mealOption ?? ""
        self.dietaryRestrictions = guest.dietaryRestrictions ?? ""
        self.plusOneAllowed = guest.plusOneAllowed ? "Yes" : "No"
        self.plusOneName = guest.plusOneName ?? ""
        self.plusOneAttending = guest.plusOneAttending ? "Yes" : "No"
        self.addressLine1 = guest.addressLine1 ?? ""
        self.city = guest.city ?? ""
        self.state = guest.state ?? ""
        self.zipCode = guest.zipCode ?? ""
        self.notes = guest.notes ?? ""
    }

    var csvRow: String {
        let fields = [
            fullName,
            firstName,
            lastName,
            email,
            phone,
            rsvpStatus,
            invitedBy,
            tableAssignment,
            mealOption,
            dietaryRestrictions,
            plusOneAllowed,
            plusOneName,
            plusOneAttending,
            addressLine1,
            city,
            state,
            zipCode,
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

    static var csvHeaderFields: [String] {
        [
            "Full Name",
            "First Name",
            "Last Name",
            "Email",
            "Phone",
            "RSVP Status",
            "Invited By",
            "Table Assignment",
            "Meal Option",
            "Dietary Restrictions",
            "Plus One Allowed",
            "Plus One Name",
            "Plus One Attending",
            "Address",
            "City",
            "State",
            "Zip Code",
            "Notes"
        ]
    }
    
    static var csvHeader: String {
        csvHeaderFields.joined(separator: ",")
    }
}

// MARK: - Guest Export Service

@MainActor
class GuestExportService {
    static let shared = GuestExportService()
    private let logger = AppLogger.export

    private init() {}

    // MARK: - Main Export Method

    func exportGuests(
        _ guests: [Guest],
        settings: CoupleSettings,
        format: GuestExportFormat,
        fileName: String? = nil
    ) async throws -> URL {
        guard !guests.isEmpty else {
            throw GuestExportError.noGuestsToExport
        }

        let exportData = guests.map { GuestExportData(from: $0, settings: settings) }

        switch format {
        case .csv, .googleSheets:
            return try await exportToCSV(exportData, fileName: fileName)
        case .pdf:
            return try await exportToPDF(exportData, fileName: fileName)
        }
    }

    // MARK: - CSV Export

    private func exportToCSV(
        _ guests: [GuestExportData],
        fileName: String?
    ) async throws -> URL {
        var csvContent = GuestExportData.csvHeader + "\n"

        for guest in guests {
            csvContent += guest.csvRow + "\n"
        }

        // Save to Downloads folder
        let fileManager = FileManager.default
        guard let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw GuestExportError.directoryNotFound
        }
        
        let actualFileName = fileName ?? "GuestList_\(dateStamp)"
        let fileURL = downloadsDir.appendingPathComponent("\(actualFileName).csv")

        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

        logger.info("Exported \(guests.count) guests to CSV: \(fileURL.path)")
        return fileURL
    }

    // MARK: - PDF Export

    private func exportToPDF(
        _ guests: [GuestExportData],
        fileName: String?
    ) async throws -> URL {
        let pdfData = try generatePDFData(for: guests)

        let fileManager = FileManager.default
        guard let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw GuestExportError.directoryNotFound
        }
        
        let actualFileName = fileName ?? "GuestList_\(dateStamp)"
        let fileURL = downloadsDir.appendingPathComponent("\(actualFileName).pdf")

        try pdfData.write(to: fileURL)

        logger.info("Exported \(guests.count) guests to PDF: \(fileURL.path)")
        return fileURL
    }

    // MARK: - PDF Generation (Using TPPDF)

    private func generatePDFData(for guests: [GuestExportData]) throws -> Data {
        let document = PDFDocument(format: .usLetter)

        // Set margins
        document.layout.margin = NSEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)

        // Add header
        document.add(.contentCenter, textObject: PDFSimpleText(
            text: "Guest List",
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

        // Create guest cards in 2-column sections
        var index = 0
        while index < guests.count {
            let section = PDFSection(columnWidths: [0.48, 0.48])

            // Add first guest to left column
            addGuestToSection(section, column: 0, guest: guests[index])

            // Add second guest to right column if available
            if index + 1 < guests.count {
                addGuestToSection(section, column: 1, guest: guests[index + 1])
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
            throw error
        }
    }

    private func addGuestToSection(_ section: PDFSection, column: Int, guest: GuestExportData) {
        // Card with group for background
        let group = PDFGroup(
            allowsBreaks: false,
            backgroundColor: NSColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0),
            padding: NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )

        // Guest name
        group.set(font: NSFont.boldSystemFont(ofSize: 16))
        group.set(textColor: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        group.add(text: guest.fullName)

        group.add(space: 5)

        // RSVP status and invited by
        let statusBadge = guest.rsvpStatus
        group.set(font: NSFont.systemFont(ofSize: 12))
        group.set(textColor: NSColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1.0))
        group.add(text: "\(statusBadge)  •  \(guest.invitedBy)")

        // Separator line
        group.addLineSeparator(style: PDFLineStyle(
            type: .full,
            color: NSColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.0),
            width: 2
        ))

        group.add(space: 8)

        // Contact details
        group.set(font: NSFont.systemFont(ofSize: 11))

        if !guest.email.isEmpty {
            let attr = createDetailAttributedString(label: "Email:", value: guest.email)
            group.add(attributedText: attr)
        }
        if !guest.phone.isEmpty {
            let attr = createDetailAttributedString(label: "Phone:", value: guest.phone)
            group.add(attributedText: attr)
        }
        if !guest.tableAssignment.isEmpty {
            let attr = createDetailAttributedString(label: "Table:", value: guest.tableAssignment)
            group.add(attributedText: attr)
        }
        if !guest.mealOption.isEmpty {
            let attr = createDetailAttributedString(label: "Meal:", value: guest.mealOption)
            group.add(attributedText: attr)
        }

        // Plus one info
        if guest.plusOneAllowed == "Yes" {
            group.add(space: 8)
            group.set(font: NSFont.boldSystemFont(ofSize: 11))
            group.set(textColor: NSColor(red: 0.08, green: 0.5, blue: 0.24, alpha: 1.0))
            if !guest.plusOneName.isEmpty {
                group.add(text: "Plus One: \(guest.plusOneName) (\(guest.plusOneAttending))")
            } else {
                group.add(text: "Plus One Allowed")
            }
        }

        // Dietary restrictions
        if !guest.dietaryRestrictions.isEmpty {
            group.add(space: 8)
            group.set(font: NSFont.systemFont(ofSize: 10))
            group.set(textColor: NSColor(red: 0.57, green: 0.4, blue: 0.05, alpha: 1.0))
            group.add(text: "Dietary: \(guest.dietaryRestrictions)")
        }

        // Notes
        if !guest.notes.isEmpty {
            group.add(space: 8)
            group.set(font: NSFont.systemFont(ofSize: 10))
            group.set(textColor: NSColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1.0))
            group.add(text: "Notes: \(guest.notes)")
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
        _ guests: [GuestExportData],
        googleIntegration: GoogleIntegrationManager
    ) async throws -> String {
        let sheetTitle = "Guest List - \(dateStamp)"

        // Convert guest data to rows
        var rows: [[Any]] = []

        // Header row
        rows.append(GuestExportData.csvHeaderFields)

        // Data rows
        for guest in guests {
            rows.append([
                guest.fullName,
                guest.firstName,
                guest.lastName,
                guest.email,
                guest.phone,
                guest.rsvpStatus,
                guest.invitedBy,
                guest.tableAssignment,
                guest.mealOption,
                guest.dietaryRestrictions,
                guest.plusOneAllowed,
                guest.plusOneName,
                guest.plusOneAttending,
                guest.addressLine1,
                guest.city,
                guest.state,
                guest.zipCode,
                guest.notes
            ])
        }

        // Create spreadsheet using Google Sheets API
        let spreadsheetId = try await googleIntegration.sheetsManager.createSpreadsheet(
            title: sheetTitle,
            rows: rows
        )

        logger.info("Exported \(guests.count) guests to Google Sheets: \(spreadsheetId)")
        return spreadsheetId
    }

    // MARK: - File Operations

    func openFile(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    // MARK: - Alert Helpers

    @MainActor
    func showExportSuccessAlert(format: GuestExportFormat, fileURL: URL? = nil, completion: @escaping (Bool) -> Void) {
        let message: String
        if let fileURL = fileURL {
            message = "Guest list exported successfully to:\n\n\(fileURL.path)\n\nThe file has been opened automatically."
        } else {
            message = "Guest list exported successfully. The file has been opened automatically."
        }
        
        AlertPresenter.shared.showAlert(
            title: "\(format.rawValue) Export Complete",
            message: message,
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
            message: "Guest list exported successfully.\n\n\(sheetURL)\n\nClick 'Open in Browser' to view the sheet.",
            style: .informational,
            buttons: ["Open in Browser", "Close"]
        ) { [self] response in
            if response == "Open in Browser" {
                guard let url = InputValidator.safeURLConversion(sheetURL) else {
                    logger.error("Invalid Google Sheets URL: \(sheetURL)")
                    completion(false)
                    return
                }
                NSWorkspace.shared.open(url)
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    @MainActor
    func showExportErrorAlert(error: Error) {
        if let guestError = error as? GuestExportError {
            AlertPresenter.shared.showAlert(
                title: "Export Error",
                message: guestError.errorDescription ?? "Unknown error occurred",
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
        // Use user's timezone for export timestamp
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        return DateFormatting.formatDate(Date(), format: "yyyy-MM-dd", timezone: userTimezone)
    }
}

// MARK: - Export Errors

enum GuestExportError: LocalizedError {
    case noGuestsToExport
    case userCancelled
    case directoryNotFound
    case googleSheetsRequiresManualImport

    var errorDescription: String? {
        switch self {
        case .noGuestsToExport:
            return "No guests to export. Please add guests to your guest list first."
        case .userCancelled:
            return "Export cancelled"
        case .directoryNotFound:
            return "Could not locate the Downloads directory. Please verify your file system permissions and try again."
        case .googleSheetsRequiresManualImport:
            return "CSV data has been copied to your clipboard. Please paste it into the new Google Sheet that just opened."
        }
    }
}
