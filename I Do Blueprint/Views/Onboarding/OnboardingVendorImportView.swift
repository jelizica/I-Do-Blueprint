//
//  OnboardingVendorImportView.swift
//  I Do Blueprint
//
//  Vendor list import view for onboarding
//

import SwiftUI
import UniformTypeIdentifiers
import Dependencies

// MARK: - Theme Migration
// Migrated from AppColors to SemanticColors for theme support
// Status colors: success → statusSuccess
// Text hierarchy: primary → textPrimary, secondary → textSecondary
// Backgrounds: background → backgroundPrimary, cardBackground → backgroundSecondary
// Actions: primary → primaryAction
// Opacity values: 0.1 → Opacity.subtle, 0.5 → Opacity.medium

struct OnboardingVendorImportView: View {
    @Dependency(\.vendorRepository) var repository
    @State private var importService = FileImportService()
    @State private var selectedFileURL: URL?
    @State private var importPreview: ImportPreview?
    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var validationResult: ImportValidationResult?
    @State private var importSuccess = false
    @State private var importedCount = 0

    private let logger = AppLogger.general

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if importSuccess {
                successSection
            } else {
                headerSection

                if let preview = importPreview {
                    previewSection(preview: preview)
                } else {
                    filePickerSection
                }
            }

            Spacer()
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
        .task {
            // Auto-import after preview loads
            if let preview = importPreview, !importSuccess, !isImporting {
                await performImport(preview: preview)
            }
        }
    }

    // MARK: - View Sections

    private var successSection: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(SemanticColors.statusSuccess)

            // Success message
            Text("Import Successful!")
                .font(Typography.title1)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Successfully imported \(importedCount) vendor\(importedCount == 1 ? "" : "s")")
                .font(Typography.bodyLarge)
                .foregroundColor(SemanticColors.textSecondary)

            // Import another file button
            Button(action: { resetForNewImport() }) {
                Text("Import Another File")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .frame(maxWidth: 300)
                    .padding(.vertical, Spacing.md)
                    .background(SemanticColors.primaryAction)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(Spacing.xl)
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 60))
                .foregroundColor(SemanticColors.primaryAction)

            Text("Import Vendor List")
                .font(Typography.title1)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Upload a CSV or Excel file with your vendor contacts to get started quickly")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
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
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("Choose File")
                        .font(Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("Supported formats: CSV, Excel (.xlsx)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .frame(maxWidth: 400)
                .padding(.vertical, Spacing.xxl)
                .padding(.horizontal, Spacing.xl)
                .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.primaryAction, style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose CSV file to import")
            .accessibilityHint("Opens file picker to select a vendor list CSV file")

            // Format help
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Expected CSV Format:")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("• First row should contain column headers")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)

                Text("• Required: Vendor Name, Category")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)

                Text("• Optional: Contact Name, Email, Phone, Website, Notes")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)

                Text("• Categories: Venue, Catering, Photography, Videography, Florist, Music, etc.")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 400)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(8)
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func previewSection(preview: ImportPreview) -> some View {
        VStack(spacing: Spacing.lg) {
            // File info
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(SemanticColors.primaryAction)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(preview.fileName)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("\(preview.totalRows) vendors • \(preview.headers.count) columns")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                Button(action: { clearImport() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear import")
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
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
                                .foregroundColor(SemanticColors.textPrimary)
                                .padding(Spacing.sm)
                                .frame(minWidth: 120, alignment: .leading)
                                .background(SemanticColors.backgroundSecondary)
                        }
                    }

                    Divider()

                    // Rows (show first 10)
                    ForEach(Array(preview.rows.prefix(10).enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(Typography.bodySmall)
                                    .foregroundColor(SemanticColors.textPrimary)
                                    .padding(Spacing.sm)
                                    .frame(minWidth: 120, alignment: .leading)
                            }
                        }
                        .background(index % 2 == 0 ? Color.clear : SemanticColors.backgroundSecondary.opacity(Opacity.medium))
                    }
                }
            }
            .frame(maxHeight: 300)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(8)

            if preview.totalRows > 10 {
                Text("Showing first 10 of \(preview.totalRows) vendors")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            // Importing indicator
            if isImporting {
                HStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Importing vendors...")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(Spacing.md)
                .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
                .cornerRadius(8)
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
    }

    private func performImport(preview: ImportPreview) async {
        guard !isImporting else { return }

        isImporting = true
        logger.info("Starting vendor import from CSV: \(preview.fileName)")

        do {
            // Get couple ID from session
            guard let coupleId = try? SessionManager.shared.requireTenantId() else {
                await MainActor.run {
                    errorMessage = "No couple selected. Please sign in."
                    isImporting = false
                }
                return
            }

            // Define vendor target fields
            let vendorFields = [
                "vendorName", "vendorType", "contactName", "phoneNumber", "email",
                "website", "quotedAmount", "isBooked", "dateBooked",
                "streetAddress", "streetAddress2", "city", "state", "postalCode", "country",
                "latitude", "longitude", "budgetCategoryId", "vendorCategoryId",
                "includeInExport", "imageUrl", "notes"
            ]

            // Infer column mappings
            let mappings = importService.inferMappings(headers: preview.headers, targetFields: vendorFields)

            // Convert CSV rows to vendor objects
            let vendors = importService.convertToVendors(
                preview: preview,
                mappings: mappings,
                coupleId: coupleId
            )

            guard !vendors.isEmpty else {
                await MainActor.run {
                    errorMessage = "No valid vendors found in CSV file"
                    isImporting = false
                }
                return
            }

            logger.info("Converted \(vendors.count) vendors from CSV, starting import...")

            // Import vendors to database
            let imported = try await repository.importVendors(vendors)

            await MainActor.run {
                importedCount = imported.count
                importSuccess = true
                isImporting = false
                logger.info("Successfully imported \(imported.count) vendors")
            }

        } catch {
            await MainActor.run {
                errorMessage = "Failed to import vendors: \(error.localizedDescription)"
                isImporting = false
                logger.error("Vendor import failed", error: error)
            }
        }
    }

    private func resetForNewImport() {
        importPreview = nil
        selectedFileURL = nil
        importSuccess = false
        importedCount = 0
        validationResult = nil
    }
}

// MARK: - Preview

#Preview("Vendor Import View") {
    OnboardingVendorImportView()
}
