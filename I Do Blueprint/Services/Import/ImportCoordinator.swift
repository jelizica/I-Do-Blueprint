//
//  ImportCoordinator.swift
//  I Do Blueprint
//
//  High-level coordinator for file import workflows
//  Part of I Do Blueprint-11e: Consolidate Import Services
//

import Foundation

// MARK: - Import Result Types

/// Unified result type for import operations
struct ImportResult<T> {
    let success: [T]
    let failed: [FailedImport]
    let warnings: [ImportWarning]
    
    var successCount: Int { success.count }
    var failureCount: Int { failed.count }
    var warningCount: Int { warnings.count }
    var totalProcessed: Int { successCount + failureCount }
    
    var hasFailures: Bool { !failed.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }
    
    struct FailedImport {
        let rowNumber: Int
        let data: [String: String]
        let error: String
    }
    
    struct ImportWarning {
        let rowNumber: Int
        let column: String
        let message: String
    }
}

/// Import progress tracking
struct ImportProgress {
    let phase: Phase
    let currentStep: Int
    let totalSteps: Int
    let message: String
    
    var percentage: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep) / Double(totalSteps)
    }
    
    enum Phase {
        case parsing
        case validating
        case mapping
        case converting
        case completed
    }
}

/// Import configuration
struct ImportConfiguration {
    let fileType: ImportPreview.FileType
    let targetEntity: TargetEntity
    let autoMapColumns: Bool
    let validateBeforeImport: Bool
    let maxPreviewRows: Int
    
    enum TargetEntity {
        case guests
        case vendors
    }
    
    static let `default` = ImportConfiguration(
        fileType: .csv,
        targetEntity: .guests,
        autoMapColumns: true,
        validateBeforeImport: true,
        maxPreviewRows: 100
    )
}

// MARK: - Import Coordinator

/// High-level coordinator that orchestrates the complete import workflow
/// Provides a simplified API for common import scenarios
@MainActor
final class ImportCoordinator {
    
    // MARK: - Properties
    
    private let fileImportService: FileImportService
    private let logger = AppLogger.general
    
    // Progress callback
    var onProgress: ((ImportProgress) -> Void)?
    
    // MARK: - Initialization
    
    init(fileImportService: FileImportService? = nil) {
        self.fileImportService = fileImportService ?? FileImportService()
    }
    
    // MARK: - High-Level Import Workflows
    
    /// Complete guest import workflow from file URL
    /// - Parameters:
    ///   - url: File URL (CSV or XLSX)
    ///   - coupleId: Couple ID for multi-tenancy
    ///   - customMappings: Optional custom column mappings (auto-inferred if nil)
    /// - Returns: Import result with successful guests and failures
    func importGuests(
        from url: URL,
        coupleId: UUID,
        customMappings: [ColumnMapping]? = nil
    ) async throws -> ImportResult<Guest> {
        logger.info("Starting guest import from: \(url.lastPathComponent)")
        
        // Phase 1: Parse file
        reportProgress(.parsing, step: 1, total: 4, message: "Parsing file...")
        let preview = try await parseFile(url)
        
        // Phase 2: Map columns
        reportProgress(.mapping, step: 2, total: 4, message: "Mapping columns...")
        let mappings = customMappings ?? fileImportService.inferMappings(
            headers: preview.headers,
            targetFields: Guest.importableFields
        )
        
        // Phase 3: Validate
        reportProgress(.validating, step: 3, total: 4, message: "Validating data...")
        let validation = fileImportService.validateImport(preview: preview, mappings: mappings)
        
        // Phase 4: Convert
        reportProgress(.converting, step: 4, total: 4, message: "Converting to guests...")
        let guests = fileImportService.convertToGuests(
            preview: preview,
            mappings: mappings,
            coupleId: coupleId
        )
        
        // Build result
        let result = buildGuestImportResult(
            guests: guests,
            validation: validation,
            preview: preview
        )
        
        reportProgress(.completed, step: 4, total: 4, message: "Import completed")
        logger.info("Guest import completed: \(result.successCount) success, \(result.failureCount) failed")
        
        return result
    }
    
    /// Complete vendor import workflow from file URL
    /// - Parameters:
    ///   - url: File URL (CSV or XLSX)
    ///   - coupleId: Couple ID for multi-tenancy
    ///   - customMappings: Optional custom column mappings (auto-inferred if nil)
    /// - Returns: Import result with successful vendors and failures
    func importVendors(
        from url: URL,
        coupleId: UUID,
        customMappings: [ColumnMapping]? = nil
    ) async throws -> ImportResult<VendorImportData> {
        logger.info("Starting vendor import from: \(url.lastPathComponent)")
        
        // Phase 1: Parse file
        reportProgress(.parsing, step: 1, total: 4, message: "Parsing file...")
        let preview = try await parseFile(url)
        
        // Phase 2: Map columns
        reportProgress(.mapping, step: 2, total: 4, message: "Mapping columns...")
        let mappings = customMappings ?? fileImportService.inferMappings(
            headers: preview.headers,
            targetFields: VendorImportData.importableFields
        )
        
        // Phase 3: Validate
        reportProgress(.validating, step: 3, total: 4, message: "Validating data...")
        let validation = fileImportService.validateImport(preview: preview, mappings: mappings)
        
        // Phase 4: Convert
        reportProgress(.converting, step: 4, total: 4, message: "Converting to vendors...")
        let vendors = fileImportService.convertToVendors(
            preview: preview,
            mappings: mappings,
            coupleId: coupleId
        )
        
        // Build result
        let result = buildVendorImportResult(
            vendors: vendors,
            validation: validation,
            preview: preview
        )
        
        reportProgress(.completed, step: 4, total: 4, message: "Import completed")
        logger.info("Vendor import completed: \(result.successCount) success, \(result.failureCount) failed")
        
        return result
    }
    
    /// Preview import without converting to domain objects
    /// Useful for showing user what will be imported before committing
    func previewImport(from url: URL) async throws -> (preview: ImportPreview, suggestedMappings: [ColumnMapping]) {
        let preview = try await parseFile(url)
        
        // Infer mappings based on file content
        let targetFields = detectTargetEntity(from: preview.headers)
        let mappings = fileImportService.inferMappings(
            headers: preview.headers,
            targetFields: targetFields
        )
        
        return (preview, mappings)
    }
    
    // MARK: - Private Helpers
    
    /// Parse file based on extension
    private func parseFile(_ url: URL) async throws -> ImportPreview {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "csv":
            return try await fileImportService.parseCSV(from: url)
        case "xlsx":
            return try await fileImportService.parseXLSX(from: url)
        default:
            throw FileImportError.invalidFileType
        }
    }
    
    /// Detect target entity type from headers
    private func detectTargetEntity(from headers: [String]) -> [String] {
        let headerSet = Set(headers.map { $0.lowercased() })
        
        // Check for vendor-specific fields
        let vendorIndicators = ["vendor", "quoted", "booked", "contract"]
        let hasVendorFields = vendorIndicators.contains { indicator in
            headerSet.contains { $0.contains(indicator) }
        }
        
        if hasVendorFields {
            return VendorImportData.importableFields
        } else {
            return Guest.importableFields // Default to guests
        }
    }
    
    /// Build guest import result from conversion output
    private func buildGuestImportResult(
        guests: [Guest],
        validation: ImportValidationResult,
        preview: ImportPreview
    ) -> ImportResult<Guest> {
        // Convert validation errors to failed imports
        let failed = validation.errors.map { error in
            ImportResult<Guest>.FailedImport(
                rowNumber: error.row,
                data: [:], // Could be enhanced to include row data
                error: error.message
            )
        }
        
        // Convert validation warnings
        let warnings = validation.warnings.map { warning in
            ImportResult<Guest>.ImportWarning(
                rowNumber: warning.row,
                column: warning.column,
                message: warning.message
            )
        }
        
        return ImportResult(
            success: guests,
            failed: failed,
            warnings: warnings
        )
    }
    
    /// Build vendor import result from conversion output
    private func buildVendorImportResult(
        vendors: [VendorImportData],
        validation: ImportValidationResult,
        preview: ImportPreview
    ) -> ImportResult<VendorImportData> {
        // Convert validation errors to failed imports
        let failed = validation.errors.map { error in
            ImportResult<VendorImportData>.FailedImport(
                rowNumber: error.row,
                data: [:],
                error: error.message
            )
        }
        
        // Convert validation warnings
        let warnings = validation.warnings.map { warning in
            ImportResult<VendorImportData>.ImportWarning(
                rowNumber: warning.row,
                column: warning.column,
                message: warning.message
            )
        }
        
        return ImportResult(
            success: vendors,
            failed: failed,
            warnings: warnings
        )
    }
    
    /// Report progress to callback
    private func reportProgress(
        _ phase: ImportProgress.Phase,
        step: Int,
        total: Int,
        message: String
    ) {
        let progress = ImportProgress(
            phase: phase,
            currentStep: step,
            totalSteps: total,
            message: message
        )
        onProgress?(progress)
    }
}

// MARK: - Domain Model Extensions

// Note: Guest.importableFields is defined in GuestCSVImportView.swift

extension VendorImportData {
    /// Fields that can be imported from CSV/XLSX
    static var importableFields: [String] {
        [
            "vendorName",
            "vendorType",
            "contactName",
            "phoneNumber",
            "email",
            "website",
            "notes",
            "quotedAmount",
            "isBooked",
            "dateBooked",
            "streetAddress",
            "city",
            "state",
            "postalCode",
            "country"
        ]
    }
}
