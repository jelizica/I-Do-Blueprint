//
//  OnboardingGuestImportView.swift
//  I Do Blueprint
//
//  Guest list import view for onboarding
//

import SwiftUI
import UniformTypeIdentifiers
import Dependencies

struct OnboardingGuestImportView: View {
    @State private var importService = FileImportService()
    @State private var selectedFileURL: URL?
    @State private var importPreview: ImportPreview?
    @State private var columnMappings: [ColumnMapping] = []
    @State private var validationResult: ImportValidationResult?
    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var importSuccess = false
    @State private var importedCount = 0
    
    @Dependency(\.guestRepository) var guestRepository
    private let sessionManager = SessionManager.shared
    private let logger = AppLogger.general
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            headerSection
            
            if let preview = importPreview {
                previewSection(preview: preview)
            } else {
                filePickerSection
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
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
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            
            Text("Import Guest List")
                .font(Typography.title1)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Upload a CSV or Excel file with your guest list to get started quickly")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
        }
        .padding(.top, Spacing.xl)
    }
    
    private var filePickerSection: some View {
        VStack(spacing: Spacing.lg) {
            // File picker button
            Button(action: { showFilePicker = true }) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Choose File")
                        .font(Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                    
                    Text("Supported formats: CSV, Excel (.xlsx)")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: 400)
                .padding(.vertical, Spacing.xxl)
                .padding(.horizontal, Spacing.xl)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose CSV file to import")
            .accessibilityHint("Opens file picker to select a guest list CSV file")
            
            // Format help
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Expected CSV Format:")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("• First row should contain column headers")
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("• Required: Full Name or First Name + Last Name")
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("• Optional: Email, Phone, Address, RSVP Status")
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 400)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
        }
        .padding(.horizontal, Spacing.xl)
    }
    
    private func previewSection(preview: ImportPreview) -> some View {
        VStack(spacing: Spacing.lg) {
            // File info
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(AppColors.primary)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(preview.fileName)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(preview.totalRows) guests • \(preview.headers.count) columns")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: { clearImport() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear import")
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            
            // Preview table
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // Headers
                    HStack(spacing: 0) {
                        ForEach(preview.headers, id: \.self) { header in
                            Text(header)
                                .font(Typography.bodySmall)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(Spacing.sm)
                                .frame(minWidth: 120, alignment: .leading)
                                .background(AppColors.cardBackground)
                        }
                    }
                    
                    Divider()
                    
                    // Rows (show first 10)
                    ForEach(Array(preview.rows.prefix(10).enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(Typography.bodySmall)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(Spacing.sm)
                                    .frame(minWidth: 120, alignment: .leading)
                            }
                        }
                        .background(index % 2 == 0 ? Color.clear : AppColors.cardBackground.opacity(0.5))
                    }
                }
            }
            .frame(maxHeight: 300)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            
            if preview.totalRows > 10 {
                Text("Showing first 10 of \(preview.totalRows) guests")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Validation results
            if let validation = validationResult {
                validationSection(validation: validation)
            }
            
            // Import button
            if !importSuccess {
                Button(action: { performImport() }) {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(isImporting ? "Importing..." : "Import Guests")
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: 400)
                    .padding(.vertical, Spacing.md)
                    .background(isImporting ? AppColors.textSecondary : AppColors.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isImporting || (validationResult?.isValid == false))
                .accessibilityLabel("Import guests from CSV")
            } else {
                successSection
            }
        }
        .padding(.horizontal, Spacing.xl)
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
        isImporting = true
        
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
                    isImporting = false
                    
                    // Auto-import after preview loads
                    performImport()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isImporting = false
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
        importedCount = 0
    }
    
    private func validationSection(validation: ImportValidationResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if validation.isValid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Validation passed! Ready to import.")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Validation errors found:")
                            .font(Typography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    ForEach(Array(validation.errors.prefix(5).enumerated()), id: \.offset) { _, error in
                        Text("• Row \(error.row): \(error.message)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if validation.errors.count > 5 {
                        Text("... and \(validation.errors.count - 5) more errors")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            if !validation.warnings.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Warnings:")
                            .font(Typography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    ForEach(Array(validation.warnings.prefix(3).enumerated()), id: \.offset) { _, warning in
                        Text("• Row \(warning.row): \(warning.message)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if validation.warnings.count > 3 {
                        Text("... and \(validation.warnings.count - 3) more warnings")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: 400)
        .background(validation.isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var successSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Import Successful!")
                .font(Typography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Successfully imported \(importedCount) guests")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
            
            Button(action: { clearImport() }) {
                Text("Import Another File")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: 400)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xl)
    }
    
    private func performImport() {
        guard let preview = importPreview else { return }
        
        // Define target fields for mapping
        let targetFields = [
            "firstName", "lastName", "email", "phone", "rsvpStatus",
            "plusOneAllowed", "plusOneName", "plusOneAttending",
            "attendingCeremony", "attendingReception",
            "dietaryRestrictions", "accessibilityNeeds",
            "tableAssignment", "seatNumber", "preferredContactMethod",
            "addressLine1", "addressLine2", "city", "state", "zipCode", "country",
            "invitationNumber", "isWeddingParty", "weddingPartyRole",
            "relationshipToCouple", "invitedBy", "rsvpDate",
            "mealOption", "giftReceived", "notes",
            "hairDone", "makeupDone", "preparationNotes"
        ]
        
        // Infer column mappings
        columnMappings = importService.inferMappings(headers: preview.headers, targetFields: targetFields)
        
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
                // Convert CSV rows to Guest objects
                let guests = await importService.convertToGuests(
                    preview: preview,
                    mappings: columnMappings,
                    coupleId: coupleId
                )
                
                logger.info("Converted \(guests.count) guests, starting import...")
                
                // Import guests to database
                let imported = try await guestRepository.importGuests(guests)
                
                await MainActor.run {
                    importedCount = imported.count
                    importSuccess = true
                    isImporting = false
                    logger.info("Successfully imported \(imported.count) guests")
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
}

// MARK: - Preview

#Preview("Guest Import View") {
    OnboardingGuestImportView()
}
