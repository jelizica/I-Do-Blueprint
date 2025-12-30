//
//  GuestCSVImportView.swift
//  I Do Blueprint
//
//  Main coordinator view for CSV guest import wizard
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
        VStack(spacing: 0) {
            // Header
            ImportHeaderView()

            // Content based on state
            if importSuccess, let stats = importStats {
                ImportSuccessView(stats: stats) {
                    Task {
                        await guestStore.loadGuestData()
                        dismiss()
                    }
                }
            } else if let preview = importPreview {
                ImportPreviewView(
                    preview: preview,
                    importMode: importMode,
                    validationResult: validationResult,
                    isImporting: isImporting,
                    onClear: clearImport
                )
            } else {
                ImportFilePickerView(
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
            if importSuccess {
                Task {
                    await guestStore.loadGuestData()
                }
            }
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
                let preview: ImportPreview
                if url.pathExtension.lowercased() == "xlsx" {
                    preview = try await importService.parseXLSX(from: url)
                } else {
                    preview = try await importService.parseCSV(from: url)
                }

                await MainActor.run {
                    importPreview = preview
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

        let targetFields = Guest.importableFields
        columnMappings = importService.inferMappings(headers: preview.headers, targetFields: targetFields)

        let validation = importService.validateImport(preview: preview, mappings: columnMappings)
        validationResult = validation

        guard validation.isValid else {
            logger.warning("Import validation failed with \(validation.errors.count) errors")
            return
        }

        guard let coupleId = sessionManager.currentTenantId else {
            errorMessage = "No couple selected. Please sign in first."
            return
        }

        isImporting = true

        Task {
            do {
                let newGuests = await importService.convertToGuests(
                    preview: preview,
                    mappings: columnMappings,
                    coupleId: coupleId
                )

                logger.info("Converted \(newGuests.count) guests, starting import with mode: \(importMode)")

                let existingGuests = guestStore.guests
                var stats: ImportStats

                if importMode == .addOnly {
                    stats = try await performAddOnlyImport(newGuests: newGuests, existingGuests: existingGuests)
                } else {
                    stats = try await performSyncImport(newGuests: newGuests, existingGuests: existingGuests)
                }

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

        let existingEmails = Set(existingGuests.compactMap { $0.email?.lowercased() })
        let existingNames = Set(existingGuests.map { "\($0.firstName.lowercased())_\($0.lastName.lowercased())" })

        let guestsToAdd = newGuests.filter { guest in
            if let email = guest.email?.lowercased(), !email.isEmpty {
                if existingEmails.contains(email) {
                    stats.skipped += 1
                    return false
                }
            }

            let nameKey = "\(guest.firstName.lowercased())_\(guest.lastName.lowercased())"
            if existingNames.contains(nameKey) {
                stats.skipped += 1
                return false
            }

            return true
        }

        if !guestsToAdd.isEmpty {
            let imported = try await guestRepository.importGuests(guestsToAdd)
            stats.added = imported.count
        }

        return stats
    }

    private func performSyncImport(newGuests: [Guest], existingGuests: [Guest]) async throws -> ImportStats {
        var stats = ImportStats(added: 0, updated: 0, deleted: 0, skipped: 0)

        var existingByEmail: [String: Guest] = [:]
        var existingByName: [String: Guest] = [:]

        for guest in existingGuests {
            if let email = guest.email?.lowercased(), !email.isEmpty {
                existingByEmail[email] = guest
            }
            let nameKey = "\(guest.firstName.lowercased())_\(guest.lastName.lowercased())"
            existingByName[nameKey] = guest
        }

        var matchedGuestIds = Set<UUID>()

        for newGuest in newGuests {
            var existingGuest: Guest?

            if let email = newGuest.email?.lowercased(), !email.isEmpty {
                existingGuest = existingByEmail[email]
            }

            if existingGuest == nil {
                let nameKey = "\(newGuest.firstName.lowercased())_\(newGuest.lastName.lowercased())"
                existingGuest = existingByName[nameKey]
            }

            if let existing = existingGuest {
                matchedGuestIds.insert(existing.id)
                stats.updated += 1
            } else {
                await guestStore.addGuest(newGuest)
                stats.added += 1
            }
        }

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

// MARK: - Guest Extension

extension Guest {
    static var importableFields: [String] {
        [
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
    }
}

// MARK: - Preview

#Preview {
    GuestCSVImportView()
        .environmentObject(GuestStoreV2())
}
