//
//  VendorCSVImportView.swift
//  I Do Blueprint
//
//  CSV import view for vendor list page with duplicate handling
//  Refactored: Decomposed into focused components to reduce complexity
//

import SwiftUI
import UniformTypeIdentifiers
import Dependencies

struct VendorCSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vendorStore: VendorStoreV2

    @State private var importService = FileImportService()
    @State private var selectedFileURL: URL?
    @State private var importPreview: ImportPreview?
    @State private var columnMappings: [ColumnMapping] = []
    @State private var validationResult: ImportValidationResult?
    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var importSuccess = false
    @State private var importStats: ImportStats?
    @State private var importMode: ImportMode = .addOnly

    @Dependency(\.vendorRepository) var vendorRepository
    private let sessionManager = SessionManager.shared
    private let logger = AppLogger.general

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VendorImportHeaderView()

            if let preview = importPreview {
                if importSuccess, let stats = importStats {
                    VendorImportSuccessView(stats: stats) {
                        Task {
                            await vendorStore.loadVendors()
                            dismiss()
                        }
                    }
                } else {
                    VendorImportPreviewView(
                        preview: preview,
                        importMode: importMode,
                        isImporting: isImporting,
                        validationResult: validationResult,
                        onClear: clearImport
                    )
                }
            } else {
                VendorImportFilePickerView(
                    importMode: $importMode,
                    onSelectFile: { showFilePicker = true }
                )
            }

            Spacer()

            // Bottom buttons
            HStack(spacing: Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.backgroundPrimary)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, .xlsx],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFileURL = url
            loadFile(url)

        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }

    private func loadFile(_ url: URL) {
        Task {
            do {
                // Detect file type by extension
                let preview: ImportPreview
                if url.pathExtension.lowercased() == "xlsx" {
                    preview = try await importService.parseXLSX(from: url)
                } else {
                    preview = try await importService.parseCSV(from: url)
                }

                await MainActor.run {
                    importPreview = preview

                    // Auto-import after preview loads
                    performImport()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func clearImport() {
        importPreview = nil
        selectedFileURL = nil
        columnMappings = []
        validationResult = nil
        importSuccess = false
        importStats = nil
    }

    private func performImport() {
        guard let preview = importPreview else { return }

        // Define vendor target fields
        let vendorFields = [
            "vendorName", "vendorType", "contactName", "phoneNumber", "email",
            "website", "quotedAmount", "isBooked", "dateBooked",
            "streetAddress", "streetAddress2", "city", "state", "postalCode", "country",
            "latitude", "longitude", "budgetCategoryId", "vendorCategoryId",
            "includeInExport", "imageUrl", "notes"
        ]

        // Infer column mappings
        columnMappings = importService.inferMappings(headers: preview.headers, targetFields: vendorFields)

        // Validate the import
        let validation = importService.validateImport(preview: preview, mappings: columnMappings)
        validationResult = validation

        // If validation fails, don't proceed
        guard validation.isValid else {
            logger.warning("Import validation failed with \(validation.errors.count) errors")
            return
        }

        // Get couple ID from session
        guard let coupleId = sessionManager.currentTenantId else {
            errorMessage = "No couple selected. Please sign in first."
            return
        }

        isImporting = true

        Task {
            do {
                // Convert CSV rows to VendorImportData objects
                let newVendors = await importService.convertToVendors(
                    preview: preview,
                    mappings: columnMappings,
                    coupleId: coupleId
                )

                logger.info("Converted \(newVendors.count) vendors, starting import with mode: \(importMode)")

                // Get existing vendors
                let existingVendors = vendorStore.vendors

                var stats = ImportStats(added: 0, updated: 0, deleted: 0, skipped: 0)

                if importMode == .addOnly {
                    // Add Only mode: Only add vendors that don't exist
                    stats = try await performAddOnlyImport(newVendors: newVendors, existingVendors: existingVendors)
                } else {
                    // Sync mode: Add new, update existing
                    stats = try await performSyncImport(newVendors: newVendors, existingVendors: existingVendors)
                }

                // Reload vendor data
                await vendorStore.loadVendors()

                await MainActor.run {
                    importStats = stats
                    importSuccess = true
                    isImporting = false
                    logger.info("Import complete: \(stats)")
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = "Import failed: \(error.localizedDescription)"
                    logger.error("Import failed", error: error)
                }
            }
        }
    }

    private func performAddOnlyImport(newVendors: [VendorImportData], existingVendors: [Vendor]) async throws -> ImportStats {
        var stats = ImportStats(added: 0, updated: 0, deleted: 0, skipped: 0)

        // Create a set of existing vendor names and emails for quick lookup
        let existingNames = Set(existingVendors.map { $0.vendorName.lowercased() })
        let existingEmails = Set(existingVendors.compactMap { $0.email?.lowercased() })

        // Filter out vendors that already exist
        let vendorsToAdd = newVendors.filter { vendor in
            // Check by name
            if existingNames.contains(vendor.vendorName.lowercased()) {
                stats.skipped += 1
                return false
            }

            // Check by email if available
            if let email = vendor.email?.lowercased(), !email.isEmpty {
                if existingEmails.contains(email) {
                    stats.skipped += 1
                    return false
                }
            }

            return true
        }

        // Import new vendors
        if !vendorsToAdd.isEmpty {
            let imported = try await vendorRepository.importVendors(vendorsToAdd)
            stats.added = imported.count
        }

        return stats
    }

    private func performSyncImport(newVendors: [VendorImportData], existingVendors: [Vendor]) async throws -> ImportStats {
        var stats = ImportStats(added: 0, updated: 0, deleted: 0, skipped: 0)

        // Create lookup dictionaries
        var existingByName: [String: Vendor] = [:]
        var existingByEmail: [String: Vendor] = [:]

        for vendor in existingVendors {
            existingByName[vendor.vendorName.lowercased()] = vendor
            if let email = vendor.email?.lowercased(), !email.isEmpty {
                existingByEmail[email] = vendor
            }
        }

        // Track which existing vendors are in the new file
        var matchedVendorIds = Set<Int64>()

        // Process new vendors
        var vendorsToAdd: [VendorImportData] = []

        for newVendor in newVendors {
            var existingVendor: Vendor?

            // Try to match by name first
            existingVendor = existingByName[newVendor.vendorName.lowercased()]

            // If no name match, try email
            if existingVendor == nil, let email = newVendor.email?.lowercased(), !email.isEmpty {
                existingVendor = existingByEmail[email]
            }

            if let existing = existingVendor {
                // Vendor exists - mark as matched (don't update to preserve data)
                matchedVendorIds.insert(existing.id)
                stats.updated += 1
            } else {
                // New vendor - add it
                vendorsToAdd.append(newVendor)
            }
        }

        // Import new vendors
        if !vendorsToAdd.isEmpty {
            let imported = try await vendorRepository.importVendors(vendorsToAdd)
            stats.added = imported.count
        }

        // Delete vendors not in the new file
        for existingVendor in existingVendors {
            if !matchedVendorIds.contains(existingVendor.id) {
                await vendorStore.deleteVendor(existingVendor)
                stats.deleted += 1
            }
        }

        return stats
    }
}

// MARK: - Preview

#Preview {
    VendorCSVImportView()
        .environmentObject(VendorStoreV2())
}
