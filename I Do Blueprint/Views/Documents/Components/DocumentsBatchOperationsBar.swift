//
//  DocumentsBatchOperationsBar.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Batch operations bar for selecting and performing actions on multiple documents
struct DocumentsBatchOperationsBar: View {
    @ObservedObject var viewModel: DocumentStoreV2
    @Binding var showingTypePickerModal: Bool
    
    var body: some View {
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
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
