//
//  DocumentsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//  Refactored: Decomposed into focused components to reduce complexity
//

import SwiftUI

struct DocumentsView: View {
    @EnvironmentObject private var viewModel: DocumentStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @State private var showingUploadModal = false
    @State private var showingFilterSheet = false
    @State private var showingTypePickerModal = false
    @State private var selectedDocument: Document?

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header with inline controls
                DocumentsHeaderView(
                    viewModel: viewModel,
                    showingFilterSheet: $showingFilterSheet
                )

                Divider()

                // Type filter tabs
                DocumentsTypeFilterTabs(viewModel: viewModel)

                Divider()

                // Content
                contentView
            }
            .navigationTitle("Documents")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingUploadModal) {
                DocumentUploadModal(
                    onUpload: { metadata in
                        await handleUpload(metadata)
                    },
                    onCancel: {
                        showingUploadModal = false
                    })
            }
            .sheet(item: $selectedDocument) { document in
                DocumentDetailView(
                    document: document,
                    viewModel: viewModel)
            }
            .sheet(isPresented: $showingTypePickerModal) {
                BatchTypePickerModal(
                    selectedCount: viewModel.selectedDocumentIds.count,
                    onSelectType: { type in
                        Task {
                            await viewModel.batchUpdateType(type)
                            showingTypePickerModal = false
                        }
                    },
                    onCancel: {
                        showingTypePickerModal = false
                    })
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading, viewModel.documents.isEmpty {
            DocumentsLoadingView()
        } else if viewModel.filteredDocuments.isEmpty {
            DocumentsEmptyStateView(
                viewModel: viewModel,
                onAddDocument: { showingUploadModal = true }
            )
        } else {
            DocumentsContentView(
                viewModel: viewModel,
                selectedDocument: $selectedDocument,
                showingTypePickerModal: $showingTypePickerModal
            )
        }
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isRefreshing)
        }

        ToolbarItem(placement: .automatic) {
            Button(action: { showingUploadModal = true }) {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Helper Methods

    private func handleUpload(_ metadata: FileUploadMetadata) async {
        guard let coupleId = settingsStore.coupleId else {
            logger.warning("No couple ID available")
            return
        }

        do {
            // Get user email from auth context
            let uploadedBy = try AuthContext.shared.requireUserEmail()
            _ = try await viewModel.uploadFile(metadata: metadata, coupleId: coupleId, uploadedBy: uploadedBy)
            showingUploadModal = false
        } catch {
            logger.error("Failed to upload file", error: error)
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentsView()
        .environmentObject(SettingsStoreV2())
}
