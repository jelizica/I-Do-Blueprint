//
//  DocumentsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct DocumentsView: View {
    @StateObject private var viewModel = DocumentStoreV2()
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var showingUploadModal = false
    @State private var showingFilterSheet = false
    @State private var showingTypePickerModal = false
    @State private var selectedDocument: Document?

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header with inline controls
                customHeader

                Divider()

                // Type filter tabs
                typeFilterTabs

                Divider()

                // Content
                if viewModel.isLoading, viewModel.documents.isEmpty {
                    loadingView
                } else if viewModel.filteredDocuments.isEmpty {
                    emptyStateView
                } else {
                    documentListView
                }
            }
            .navigationTitle("Documents")
            .toolbar {
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
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        HStack(spacing: 16) {
            // Search bar
            SearchField(
                searchText: $viewModel.searchText,
                placeholder: "Search documents...",
                onClear: { viewModel.clearSearch() }
            )

            Spacer()

            // View mode toggle
            Picker("View", selection: $viewModel.viewMode) {
                ForEach(DocumentViewMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)

            // Advanced filters button
            Button(action: { showingFilterSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    if viewModel.filters.hasActiveFilters {
                        Text("\(viewModel.filters.activeFilterCount)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Circle().fill(Color.blue))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }

            // Selection mode toggle
            if !viewModel.filteredDocuments.isEmpty {
                Button(action: {
                    viewModel.isSelectionMode.toggle()
                    if !viewModel.isSelectionMode {
                        viewModel.deselectAll()
                    }
                }) {
                    Image(systemName: viewModel.isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Type Filter Tabs

    private var typeFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All tab
                FilterTabButton(
                    title: "All",
                    count: viewModel.documents.count,
                    isSelected: viewModel.filters.selectedType == nil,
                    color: .primary) {
                    viewModel.setTypeFilter(nil)
                }

                // Type tabs
                ForEach(DocumentType.allCases, id: \.self) { type in
                    FilterTabButton(
                        title: type.displayName,
                        count: viewModel.typeCounts[type] ?? 0,
                        isSelected: viewModel.filters.selectedType == type,
                        color: colorForType(type)) {
                        viewModel.setTypeFilter(type)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Document List View

    private var documentListView: some View {
        VStack(spacing: 0) {
            // Batch operations bar
            if viewModel.isSelectionMode {
                batchOperationsBar
                Divider()
            }

            // Grid or List view
            ScrollView {
                if viewModel.viewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 250, maximum: 300), spacing: 20)
        ], spacing: 20) {
            ForEach(viewModel.filteredDocuments) { document in
                DocumentCard(
                    document: document,
                    isSelected: viewModel.selectedDocumentIds.contains(document.id),
                    isSelectionMode: viewModel.isSelectionMode,
                    onTap: {
                        if viewModel.isSelectionMode {
                            viewModel.toggleSelection(document.id)
                        } else {
                            selectedDocument = document
                        }
                    },
                    onToggleSelection: {
                        viewModel.toggleSelection(document.id)
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteDocument(document.id)
                        }
                    })
            }
        }
        .padding(20)
    }

    // MARK: - List View

    private var listView: some View {
        LazyVStack(spacing: 1) {
            ForEach(viewModel.filteredDocuments) { document in
                DocumentListRow(
                    document: document,
                    isSelected: viewModel.selectedDocumentIds.contains(document.id),
                    isSelectionMode: viewModel.isSelectionMode,
                    onTap: {
                        if viewModel.isSelectionMode {
                            viewModel.toggleSelection(document.id)
                        } else {
                            selectedDocument = document
                        }
                    },
                    onToggleSelection: {
                        viewModel.toggleSelection(document.id)
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteDocument(document.id)
                        }
                    })
            }
        }
    }

    // MARK: - Batch Operations Bar

    private var batchOperationsBar: some View {
        HStack(spacing: 16) {
            Button(action: {
                if viewModel.isSelectingAll {
                    viewModel.deselectAll()
                } else {
                    viewModel.selectAll()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isSelectingAll ? "checkmark.square.fill" : "square")
                    Text(viewModel.isSelectingAll ? "Deselect All" : "Select All")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            Text("\(viewModel.selectedDocumentIds.count) selected")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if !viewModel.selectedDocumentIds.isEmpty {
                HStack(spacing: 12) {
                    Button("Download") {
                        Task {
                            await viewModel.batchDownload()
                        }
                    }
                    .buttonStyle(.borderless)

                    Button("Change Type") {
                        showingTypePickerModal = true
                    }
                    .buttonStyle(.borderless)

                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.batchDelete()
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        Group {
            if viewModel.hasActiveFilters {
                SharedEmptyStateView(
                    icon: "doc.fill",
                    title: "No Documents Found",
                    message: "No documents match your current filters. Try adjusting or clearing your filters.",
                    actionTitle: "Clear Filters",
                    action: { viewModel.clearFilters() }
                )
            } else {
                SharedEmptyStateView(
                    icon: "doc.fill",
                    title: "No Documents Yet",
                    message: "Upload your first document to get started organizing your wedding files.",
                    actionTitle: "Upload Document",
                    action: { showingUploadModal = true }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: Spacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    DocumentCardSkeleton()
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Helper Methods

    private func handleUpload(_ metadata: FileUploadMetadata) async {
        guard let coupleId = settingsViewModel.coupleId else {
            logger.warning("No couple ID available")
            return
        }

        do {
            // TODO: Get actual user email from auth system
            let uploadedBy = "current-user@example.com"
            _ = try await viewModel.uploadFile(metadata: metadata, coupleId: coupleId, uploadedBy: uploadedBy)
            showingUploadModal = false
        } catch {
            logger.error("Failed to upload file", error: error)
        }
    }

    private func colorForType(_ type: DocumentType) -> Color {
        switch type.color {
        case "blue": .blue
        case "green": .green
        case "orange": .orange
        case "purple": .purple
        case "gray": .gray
        default: .primary
        }
    }
}

// MARK: - Filter Tab Button

struct FilterTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.1)))
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2))
            .foregroundColor(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Batch Type Picker Modal

struct BatchTypePickerModal: View {
    let selectedCount: Int
    let onSelectType: (DocumentType) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("Change Document Type")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(selectedCount) document\(selectedCount == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                Divider()

                // Type selection list
                VStack(spacing: 0) {
                    ForEach(DocumentType.allCases, id: \.self) { type in
                        Button(action: {
                            onSelectType(type)
                        }) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(colorForType(type).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: iconForType(type))
                                            .foregroundColor(colorForType(type))
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(descriptionForType(type))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .frame(width: 500, height: 600)
            .navigationTitle("Change Type")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }

    private func colorForType(_ type: DocumentType) -> Color {
        switch type {
        case .contract: .blue
        case .invoice: .green
        case .receipt: .orange
        case .photo: .purple
        case .other: .gray
        }
    }

    private func iconForType(_ type: DocumentType) -> String {
        switch type {
        case .contract: "doc.text"
        case .invoice: "doc.plaintext"
        case .receipt: "receipt"
        case .photo: "photo"
        case .other: "doc"
        }
    }

    private func descriptionForType(_ type: DocumentType) -> String {
        switch type {
        case .contract: "Legal agreements and contracts"
        case .invoice: "Bills and invoices"
        case .receipt: "Payment receipts"
        case .photo: "Photos and images"
        case .other: "Miscellaneous documents"
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentsView()
        .environmentObject(SettingsViewModel())
}
