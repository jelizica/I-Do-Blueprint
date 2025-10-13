//
//  VendorExportHandler.swift
//  My Wedding Planning App
//
//  Extracted export logic from VendorListViewV2 for improved modularity
//

import Foundation
import SwiftUI
import Combine

/// Handles vendor export operations with Google Sheets integration
@MainActor
class VendorExportHandler: ObservableObject {
    @Published var isExporting = false
    @Published var exportError: VendorExportError?
    @Published var showingExportSuccess = false
    @Published var exportedFileURL: URL?
    @Published var exportedSpreadsheetId: String?

    private var googleIntegration: GoogleIntegrationManager!

    init(googleIntegration: GoogleIntegrationManager? = nil) {
        self.googleIntegration = googleIntegration ?? GoogleIntegrationManager()
    }

    /// Export vendors to the specified format
    func exportVendors(_ vendors: [Vendor], format: VendorExportFormat) async {
        isExporting = true
        exportError = nil

        do {
            if format == .googleSheets {
                try await exportToGoogleSheets(vendors)
            } else {
                try await exportToFile(vendors, format: format)
            }
        } catch {
            await VendorExportService.shared.showExportErrorAlert(error: error)
            exportError = error as? VendorExportError
        }

        isExporting = false
    }

    // MARK: - Private Export Methods

    private func exportToGoogleSheets(_ vendors: [Vendor]) async throws {
        // Check if user is authenticated
        if !googleIntegration.authManager.isAuthenticated {
            try await googleIntegration.authManager.authenticate()
        }

        // Filter and prepare vendor data
        let exportableVendors = vendors.filter { $0.includeInExport && !$0.isArchived }
        let vendorData = exportableVendors.map { VendorContactExportData(from: $0) }

        // Export to Google Sheets
        let spreadsheetId = try await VendorExportService.shared.exportToGoogleSheets(
            vendorData,
            googleIntegration: googleIntegration
        )

        exportedSpreadsheetId = spreadsheetId

        // Show success alert
        await VendorExportService.shared.showGoogleSheetsSuccessAlert(
            spreadsheetId: spreadsheetId
        ) { _ in }
    }

    private func exportToFile(_ vendors: [Vendor], format: VendorExportFormat) async throws {
        // CSV or PDF export
        let fileURL = try await VendorExportService.shared.exportVendors(
            vendors,
            format: format
        )

        // Open the file directly
        VendorExportService.shared.openFile(fileURL)
        exportedFileURL = fileURL

        // Show success message
        await VendorExportService.shared.showExportSuccessAlert(
            format: format,
            fileURL: fileURL
        ) { _ in }
    }

    /// Get the count of exportable vendors
    func exportableCount(from vendors: [Vendor]) -> Int {
        vendors.filter { $0.includeInExport && !$0.isArchived }.count
    }
}
