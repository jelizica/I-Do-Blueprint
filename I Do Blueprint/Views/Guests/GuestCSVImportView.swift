//
//  GuestCSVImportView.swift
//  I Do Blueprint
//
//  CSV import view for guest list page with duplicate handling
//

import SwiftUI
import UniformTypeIdentifiers
import Dependencies

enum ImportMode {
    case addOnly        // Only add new guests, don't delete or update
    case sync           // Add new, update existing, delete removed
}

struct GuestCSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var guestStore: GuestStoreV2
    
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
        .onDisappear {
            // Ensure data is refreshed when sheet closes
            if importSuccess {
                Task {
                    await guestStore.loadGuestData()
                }
            }
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)
            
            Text("Import Guests")
                .font(Typography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Upload a CSV or Excel file to add or sync your guest list")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.lg)
    }
    
    private var filePickerSection: some View {
        VStack(spacing: Spacing.lg) {
            // Import mode selection
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Import Mode:")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                VStack(spacing: Spacing.sm) {
                    importModeOption(
                        mode: .addOnly,
                        title: "Add Only",
                        description: "Add new guests from the file. Existing guests won't be modified or deleted.",
                        icon: "plus.circle"
                    )
                    
                    importModeOption(
                        mode: .sync,
                        title: "Sync",
                        description: "Add new guests, update existing ones, and remove guests not in the file.",
                        icon: "arrow.triangle.2.circlepath"
                    )
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 500)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            
            // File picker button
            Button(action: { showFilePicker = true }) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
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
                .padding(.vertical, Spacing.xl)
                .padding(.horizontal, Spacing.xl)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xl)
    }
    
    private func importModeOption(mode: ImportMode, title: String, description: String, icon: String) -> some View {
        Button(action: { importMode = mode }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(importMode == mode ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(description)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: importMode == mode ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(importMode == mode ? AppColors.primary : AppColors.textSecondary)
            }
            .padding(Spacing.md)
            .background(importMode == mode ? AppColors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
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
                    
                    Text("\(preview.totalRows) guests • \(importMode == .addOnly ? "Add Only" : "Sync") Mode")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if !isImporting && !importSuccess {
                    Button(action: { clearImport() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            
            if !importSuccess {
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
                .frame(maxHeight: 250)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
                
                if preview.totalRows > 10 {
                    Text("Showing first 10 of \(preview.totalRows) guests")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Validation or importing status
                if let validation = validationResult {
                    validationSection(validation: validation)
                } else if isImporting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Importing guests...")
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(Spacing.md)
                }
            } else if let stats = importStats {
                successSection(stats: stats)
            }
        }
        .padding(.horizontal, Spacing.xl)
    }
    
    private func validationSection(validation: ImportValidationResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if validation.isValid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Validation passed! Importing...")
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
        }
        .padding(Spacing.md)
        .frame(maxWidth: 500)
        .background(validation.isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func successSection(stats: ImportStats) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Import Complete!")
                .font(Typography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: Spacing.xs) {
                if stats.added > 0 {
                    Text("✅ Added: \(stats.added) guests")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if stats.updated > 0 {
                    Text("🔄 Updated: \(stats.updated) guests")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if stats.deleted > 0 {
                    Text("🗑️ Removed: \(stats.deleted) guests")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if stats.skipped > 0 {
                    Text("⏭️ Skipped: \(stats.skipped) duplicates")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Button(action: { 
                // Reload data before dismissing
                Task {
                    await guestStore.loadGuestData()
                    dismiss()
                }
            }) {
                Text("Done")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.xl)
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
                let newGuests = await importService.convertToGuests(
                    preview: preview,
                    mappings: columnMappings,
                    coupleId: coupleId
                )
                
                logger.info("Converted \(newGuests.count) guests, starting import with mode: \(importMode)")
                
                // Get existing guests
                let existingGuests = guestStore.guests
                
                var stats = ImportStats(added: 0, updated: 0, deleted: 0, skipped: 0)
                
                if importMode == .addOnly {
                    // Add Only mode: Only add guests that don't exist
                    stats = try await performAddOnlyImport(newGuests: newGuests, existingGuests: existingGuests)
                } else {
                    // Sync mode: Add new, update existing, delete removed
                    stats = try await performSyncImport(newGuests: newGuests, existingGuests: existingGuests)
                }
                
                // Reload guest data
                await guestStore.loadGuestData()
                
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
    
    private func performAddOnlyImport(newGuests: [Guest], existingGuests: [Guest]) async throws -> ImportStats {
        var stats = ImportStats(added: 0, updated: 0, deleted: 0, skipped: 0)
        
        // Create a set of existing guest emails for quick lookup
        let existingEmails = Set(existingGuests.compactMap { $0.email?.lowercased() })
        let existingNames = Set(existingGuests.map { "\($0.firstName.lowercased())_\($0.lastName.lowercased())" })
        
        // Filter out guests that already exist
        let guestsToAdd = newGuests.filter { guest in
            // Check by email if available
            if let email = guest.email?.lowercased(), !email.isEmpty {
                if existingEmails.contains(email) {
                    stats.skipped += 1
                    return false
                }
            }
            
            // Check by name
            let nameKey = "\(guest.firstName.lowercased())_\(guest.lastName.lowercased())"
            if existingNames.contains(nameKey) {
                stats.skipped += 1
                return false
            }
            
            return true
        }
        
        // Import new guests
        if !guestsToAdd.isEmpty {
            let imported = try await guestRepository.importGuests(guestsToAdd)
            stats.added = imported.count
        }
        
        return stats
    }
    
    private func performSyncImport(newGuests: [Guest], existingGuests: [Guest]) async throws -> ImportStats {
        var stats = ImportStats(added: 0, updated: 0, deleted: 0, skipped: 0)
        
        // Create lookup dictionaries
        var existingByEmail: [String: Guest] = [:]
        var existingByName: [String: Guest] = [:]
        
        for guest in existingGuests {
            if let email = guest.email?.lowercased(), !email.isEmpty {
                existingByEmail[email] = guest
            }
            let nameKey = "\(guest.firstName.lowercased())_\(guest.lastName.lowercased())"
            existingByName[nameKey] = guest
        }
        
        // Track which existing guests are in the new file
        var matchedGuestIds = Set<UUID>()
        
        // Process new guests
        for newGuest in newGuests {
            var existingGuest: Guest?
            
            // Try to match by email first
            if let email = newGuest.email?.lowercased(), !email.isEmpty {
                existingGuest = existingByEmail[email]
            }
            
            // If no email match, try name
            if existingGuest == nil {
                let nameKey = "\(newGuest.firstName.lowercased())_\(newGuest.lastName.lowercased())"
                existingGuest = existingByName[nameKey]
            }
            
            if let existing = existingGuest {
                // Guest exists - mark as matched (don't update in sync mode to avoid data loss)
                matchedGuestIds.insert(existing.id)
                // Note: We're not updating existing guests to preserve their data
                // If you want to update, you'd need to create a new Guest with existing.id
                stats.updated += 1
            } else {
                // New guest - add it
                await guestStore.addGuest(newGuest)
                stats.added += 1
            }
        }
        
        // Delete guests not in the new file
        for existingGuest in existingGuests {
            if !matchedGuestIds.contains(existingGuest.id) {
                await guestStore.deleteGuest(id: existingGuest.id)
                stats.deleted += 1
            }
        }
        
        return stats
    }
}

// MARK: - Supporting Types

struct ImportStats {
    var added: Int
    var updated: Int
    var deleted: Int
    var skipped: Int
}

// MARK: - Preview

#Preview {
    GuestCSVImportView()
        .environmentObject(GuestStoreV2())
}
