import Foundation
import GoogleAPIClientForREST_Sheets
import GTMAppAuth

@MainActor
class GoogleSheetsManager {
    private let authManager: GoogleAuthManager
    private var sheetsService: GTLRSheetsService?
    private let logger = AppLogger.general

    init(authManager: GoogleAuthManager) {
        self.authManager = authManager
        setupSheetsService()
    }

    private func setupSheetsService() {
        let service = GTLRSheetsService()
        service.shouldFetchNextPages = true
        service.isRetryEnabled = true
        sheetsService = service
    }

    // MARK: - Create Spreadsheet from Budget Data

    func createSpreadsheetFromBudget(
        title: String,
        items: [BudgetItem],
        totals: BudgetTotals,
        weddingEvents: [WeddingEvent]) async throws -> String {
        guard let sheetsService else {
            throw GoogleSheetsError.serviceNotInitialized
        }

        sheetsService.authorizer = try authManager.getAuthorizer()

        // Create spreadsheet
        let spreadsheet = GTLRSheets_Spreadsheet()
        spreadsheet.properties = GTLRSheets_SpreadsheetProperties()
        spreadsheet.properties?.title = title

        let query = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject: spreadsheet)

        let createdSpreadsheet: GTLRSheets_Spreadsheet = try await withCheckedThrowingContinuation { continuation in
            sheetsService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let sheet = result as? GTLRSheets_Spreadsheet {
                    continuation.resume(returning: sheet)
                } else {
                    continuation.resume(throwing: GoogleSheetsError.creationFailed)
                }
            }
        }

        guard let spreadsheetId = createdSpreadsheet.spreadsheetId else {
            throw GoogleSheetsError.creationFailed
        }

        // Populate with data
        try await populateSpreadsheet(
            spreadsheetId: spreadsheetId,
            items: items,
            totals: totals,
            weddingEvents: weddingEvents)

        logger.info("Spreadsheet created: \(title)")
        logger.info("URL: https://docs.google.com/spreadsheets/d/\(spreadsheetId)")

        return spreadsheetId
    }

    // MARK: - Populate Spreadsheet

    private func populateSpreadsheet(
        spreadsheetId: String,
        items: [BudgetItem],
        totals: BudgetTotals,
        weddingEvents: [WeddingEvent]) async throws {
        guard let sheetsService else {
            throw GoogleSheetsError.serviceNotInitialized
        }

        // Create header row
        var rows: [[Any]] = [[
            "Item Name",
            "Category",
            "Subcategory",
            "Events",
            "Estimate (No Tax)",
            "Tax Rate %",
            "Estimate (With Tax)",
            "Person Responsible",
            "Notes"
        ]]

        // Add data rows
        for item in items {
            let eventNames = (item.eventIds ?? [])
                .compactMap { eventId in
                    weddingEvents.first(where: { $0.id == eventId })?.eventName
                }
                .joined(separator: "; ")

            rows.append([
                item.itemName,
                item.category,
                item.subcategory ?? "",
                eventNames,
                item.vendorEstimateWithoutTax,
                item.taxRate,
                item.vendorEstimateWithTax,
                item.personResponsible ?? "",
                item.notes ?? ""
            ])
        }

        // Add summary rows
        rows.append([])
        rows.append(["SUMMARY"])
        rows.append(["Total Without Tax", "", "", "", "", "", totals.totalWithoutTax])
        rows.append(["Total Tax", "", "", "", "", "", totals.totalTax])
        rows.append(["Total With Tax", "", "", "", "", "", totals.totalWithTax])
        rows.append([])
        rows.append(["Exported on", Date().formatted(date: .long, time: .shortened)])

        // Create value range
        let valueRange = GTLRSheets_ValueRange()
        valueRange.range = "Sheet1!A1"
        valueRange.values = rows

        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(
            withObject: valueRange,
            spreadsheetId: spreadsheetId,
            range: "Sheet1!A1")
        query.valueInputOption = "USER_ENTERED"

        let _: GTLRSheets_UpdateValuesResponse = try await withCheckedThrowingContinuation { continuation in
            sheetsService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response = result as? GTLRSheets_UpdateValuesResponse {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: GoogleSheetsError.updateFailed)
                }
            }
        }

        // Format header row
        try await formatHeaderRow(spreadsheetId: spreadsheetId)
    }

    // MARK: - Format Header Row

    private func formatHeaderRow(spreadsheetId: String) async throws {
        guard let sheetsService else {
            throw GoogleSheetsError.serviceNotInitialized
        }

        let request = GTLRSheets_Request()
        let repeatCell = GTLRSheets_RepeatCellRequest()

        // Define range for header row
        let gridRange = GTLRSheets_GridRange()
        gridRange.sheetId = 0
        gridRange.startRowIndex = 0
        gridRange.endRowIndex = 1
        repeatCell.range = gridRange

        // Define cell format
        let cellData = GTLRSheets_CellData()
        let cellFormat = GTLRSheets_CellFormat()

        // Bold text
        let textFormat = GTLRSheets_TextFormat()
        textFormat.bold = true
        cellFormat.textFormat = textFormat

        // Background color (light blue)
        let backgroundColor = GTLRSheets_Color()
        backgroundColor.red = 0.8
        backgroundColor.green = 0.9
        backgroundColor.blue = 1.0
        cellFormat.backgroundColor = backgroundColor

        cellData.userEnteredFormat = cellFormat
        repeatCell.cell = cellData
        repeatCell.fields = "userEnteredFormat(backgroundColor,textFormat)"

        request.repeatCell = repeatCell

        // Execute batch update
        let batchRequest = GTLRSheets_BatchUpdateSpreadsheetRequest()
        batchRequest.requests = [request]

        let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(
            withObject: batchRequest,
            spreadsheetId: spreadsheetId)

        let _: GTLRSheets_BatchUpdateSpreadsheetResponse = try await withCheckedThrowingContinuation { continuation in
            sheetsService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response = result as? GTLRSheets_BatchUpdateSpreadsheetResponse {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: GoogleSheetsError.formatFailed)
                }
            }
        }
    }

    // MARK: - Generic Spreadsheet Creation

    func createSpreadsheet(
        title: String,
        rows: [[Any]]
    ) async throws -> String {
        guard let sheetsService else {
            throw GoogleSheetsError.serviceNotInitialized
        }

        sheetsService.authorizer = try authManager.getAuthorizer()

        // Create spreadsheet
        let spreadsheet = GTLRSheets_Spreadsheet()
        spreadsheet.properties = GTLRSheets_SpreadsheetProperties()
        spreadsheet.properties?.title = title

        let query = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject: spreadsheet)

        let createdSpreadsheet: GTLRSheets_Spreadsheet = try await withCheckedThrowingContinuation { continuation in
            sheetsService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let sheet = result as? GTLRSheets_Spreadsheet {
                    continuation.resume(returning: sheet)
                } else {
                    continuation.resume(throwing: GoogleSheetsError.creationFailed)
                }
            }
        }

        guard let spreadsheetId = createdSpreadsheet.spreadsheetId else {
            throw GoogleSheetsError.creationFailed
        }

        // Populate with data
        try await populateGenericSpreadsheet(spreadsheetId: spreadsheetId, rows: rows)

        return spreadsheetId
    }

    private func populateGenericSpreadsheet(
        spreadsheetId: String,
        rows: [[Any]]
    ) async throws {
        guard let sheetsService else {
            throw GoogleSheetsError.serviceNotInitialized
        }

        // Convert rows to GTLRSheets_ValueRange format
        let valueRange = GTLRSheets_ValueRange()
        let convertedRows: [[NSObject]] = rows.map { row in
            row.map { value in
                if let nsValue = value as? NSObject {
                    return nsValue
                } else {
                    return "\(value)" as NSString
                }
            }
        }
        valueRange.values = convertedRows

        let updateQuery = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(
            withObject: valueRange,
            spreadsheetId: spreadsheetId,
            range: "Sheet1!A1"
        )
        updateQuery.valueInputOption = "USER_ENTERED"

        let _: GTLRSheets_UpdateValuesResponse = try await withCheckedThrowingContinuation { continuation in
            sheetsService.executeQuery(updateQuery) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response = result as? GTLRSheets_UpdateValuesResponse {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: GoogleSheetsError.updateFailed)
                }
            }
        }

        // Format header row
        try await formatGenericHeaderRow(spreadsheetId: spreadsheetId)
    }

    private func formatGenericHeaderRow(spreadsheetId: String) async throws {
        guard let sheetsService else {
            throw GoogleSheetsError.serviceNotInitialized
        }

        let requests = [
            GTLRSheets_Request.init(json: [
                "repeatCell": [
                    "range": [
                        "sheetId": 0,
                        "startRowIndex": 0,
                        "endRowIndex": 1
                    ],
                    "cell": [
                        "userEnteredFormat": [
                            "backgroundColor": ["red": 0.2, "green": 0.6, "blue": 0.9],
                            "textFormat": ["bold": true, "foregroundColor": ["red": 1, "green": 1, "blue": 1]],
                            "horizontalAlignment": "CENTER"
                        ]
                    ],
                    "fields": "userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)"
                ]
            ])
        ]

        let batchUpdate = GTLRSheets_BatchUpdateSpreadsheetRequest()
        batchUpdate.requests = requests

        let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(
            withObject: batchUpdate,
            spreadsheetId: spreadsheetId
        )

        let _: GTLRSheets_BatchUpdateSpreadsheetResponse = try await withCheckedThrowingContinuation { continuation in
            sheetsService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response = result as? GTLRSheets_BatchUpdateSpreadsheetResponse {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: GoogleSheetsError.formatFailed)
                }
            }
        }
    }
}

// MARK: - Errors

enum GoogleSheetsError: LocalizedError {
    case serviceNotInitialized
    case creationFailed
    case updateFailed
    case formatFailed

    var errorDescription: String? {
        switch self {
        case .serviceNotInitialized:
            "Google Sheets service not initialized"
        case .creationFailed:
            "Failed to create Google Spreadsheet"
        case .updateFailed:
            "Failed to update Google Spreadsheet"
        case .formatFailed:
            "Failed to format Google Spreadsheet"
        }
    }
}
