//
//  DocumentBatchStore.swift
//  I Do Blueprint
//
//  Sub-store for batch document operations (selection, batch delete/update/download)
//  Extracted from DocumentStoreV2 as part of architecture improvement plan
//

import Foundation
import Combine
import AppKit
import Dependencies

/// Sub-store handling batch document operations
@MainActor
class DocumentBatchStore: ObservableObject {
    @Published var selectedDocumentIds: Set<UUID> = []
    @Published var isSelectionMode: Bool = false
    @Published private(set) var isBatchOperationInProgress = false
    @Published private(set) var batchProgress: (completed: Int, total: Int)?
    
    @Dependency(\.documentRepository) var repository
    
    // MARK: - Selection Operations
    
    func toggleSelection(_ id: UUID) {
        if selectedDocumentIds.contains(id) {
            selectedDocumentIds.remove(id)
        } else {
            selectedDocumentIds.insert(id)
        }
    }
    
    func selectAll(from documents: [Document]) {
        selectedDocumentIds = Set(documents.map(\.id))
    }
    
    func deselectAll() {
        selectedDocumentIds.removeAll()
    }
    
    func isSelected(_ id: UUID) -> Bool {
        selectedDocumentIds.contains(id)
    }
    
    func isSelectingAll(from documents: [Document]) -> Bool {
        !documents.isEmpty && selectedDocumentIds.count == documents.count
    }
    
    var selectionCount: Int {
        selectedDocumentIds.count
    }
    
    // MARK: - Batch Delete
    
    /// Delete all selected documents
    /// Returns the IDs that were successfully deleted
    func batchDelete() async throws -> [UUID] {
        let idsToDelete = Array(selectedDocumentIds)
        guard !idsToDelete.isEmpty else { return [] }
        
        isBatchOperationInProgress = true
        batchProgress = (0, idsToDelete.count)
        
        defer {
            isBatchOperationInProgress = false
            batchProgress = nil
        }
        
        try await repository.batchDeleteDocuments(ids: idsToDelete)
        selectedDocumentIds.removeAll()
        
        return idsToDelete
    }
    
    // MARK: - Batch Update Type
    
    /// Update document type for all selected documents
    /// Returns the IDs that were successfully updated
    func batchUpdateType(_ type: DocumentType) async throws -> [UUID] {
        let idsToUpdate = Array(selectedDocumentIds)
        guard !idsToUpdate.isEmpty else { return [] }
        
        isBatchOperationInProgress = true
        batchProgress = (0, idsToUpdate.count)
        
        defer {
            isBatchOperationInProgress = false
            batchProgress = nil
        }
        
        // Update documents with bounded concurrency (max 5 concurrent operations)
        let maxConcurrent = 5
        var completed = 0
        var successfulIds: [UUID] = []
        
        try await withThrowingTaskGroup(of: UUID?.self) { group in
            var iterator = idsToUpdate.makeIterator()
            var activeTasks = 0
            
            // Start initial batch
            while activeTasks < maxConcurrent, let id = iterator.next() {
                group.addTask {
                    do {
                        _ = try await self.repository.updateDocumentType(id: id, type: type)
                        return id
                    } catch {
                        AppLogger.ui.error("Failed to update document type for \(id)", error: error)
                        return nil
                    }
                }
                activeTasks += 1
            }
            
            // Process results and start new tasks
            while activeTasks > 0 {
                if let result = try await group.next() {
                    activeTasks -= 1
                    completed += 1
                    batchProgress = (completed, idsToUpdate.count)
                    
                    if let id = result {
                        successfulIds.append(id)
                    }
                    
                    // Start next task if available
                    if let id = iterator.next() {
                        group.addTask {
                            do {
                                _ = try await self.repository.updateDocumentType(id: id, type: type)
                                return id
                            } catch {
                                AppLogger.ui.error("Failed to update document type for \(id)", error: error)
                                return nil
                            }
                        }
                        activeTasks += 1
                    }
                }
            }
        }
        
        selectedDocumentIds.removeAll()
        return successfulIds
    }
    
    // MARK: - Batch Download
    
    /// Download all selected documents to a user-selected directory
    func batchDownload(documents: [Document]) async {
        let documentsToDownload = documents.filter { selectedDocumentIds.contains($0.id) }
        guard !documentsToDownload.isEmpty else { return }
        
        // Create open panel to select download directory
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select download location for \(documentsToDownload.count) document(s)"
        
        let response = await panel.beginSheetModal(for: NSApp.keyWindow!)
        guard response == .OK, let destinationURL = panel.url else {
            return
        }
        
        isBatchOperationInProgress = true
        batchProgress = (0, documentsToDownload.count)
        
        defer {
            isBatchOperationInProgress = false
            batchProgress = nil
        }
        
        var successCount = 0
        var failedCount = 0
        let maxConcurrent = 3 // Limit concurrent downloads
        
        await withTaskGroup(of: (success: Bool, filename: String).self) { group in
            var iterator = documentsToDownload.makeIterator()
            var activeTasks = 0
            
            // Start initial batch
            while activeTasks < maxConcurrent, let document = iterator.next() {
                group.addTask {
                    do {
                        try await self.downloadDocument(document, to: destinationURL)
                        return (true, document.originalFilename)
                    } catch {
                        AppLogger.ui.error("Failed to download document: \(document.originalFilename)", error: error)
                        return (false, document.originalFilename)
                    }
                }
                activeTasks += 1
            }
            
            // Process results and start new tasks
            while activeTasks > 0 {
                if let result = await group.next() {
                    activeTasks -= 1
                    if result.success {
                        successCount += 1
                    } else {
                        failedCount += 1
                    }
                    
                    batchProgress = (successCount + failedCount, documentsToDownload.count)
                    
                    // Start next download if available
                    if let document = iterator.next() {
                        group.addTask {
                            do {
                                try await self.downloadDocument(document, to: destinationURL)
                                return (true, document.originalFilename)
                            } catch {
                                AppLogger.ui.error("Failed to download document: \(document.originalFilename)", error: error)
                                return (false, document.originalFilename)
                            }
                        }
                        activeTasks += 1
                    }
                }
            }
        }
        
        // Show result
        if failedCount == 0 {
            AlertPresenter.shared.showSuccessToast("Downloaded \(successCount) document(s)")
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
        } else {
            await AlertPresenter.shared.showError(
                message: "Download partially failed",
                error: NSError(
                    domain: "DocumentBatchStore",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Downloaded \(successCount), failed \(failedCount)"]
                )
            )
        }
        
        selectedDocumentIds.removeAll()
    }
    
    /// Download a single document to a specified directory
    private func downloadDocument(_ document: Document, to directory: URL) async throws {
        // Fetch document data from repository
        let data = try await repository.downloadDocument(document: document)
        
        // Create destination file URL
        let destinationURL = directory.appendingPathComponent(document.originalFilename)
        
        // Write to disk
        try data.write(to: destinationURL)
    }
    
    // MARK: - Reset
    
    func reset() {
        selectedDocumentIds.removeAll()
        isSelectionMode = false
        isBatchOperationInProgress = false
        batchProgress = nil
    }
}
