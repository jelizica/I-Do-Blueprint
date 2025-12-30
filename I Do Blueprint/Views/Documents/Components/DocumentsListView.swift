//
//  DocumentsListView.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// List layout view for displaying documents as rows
struct DocumentsListView: View {
    @ObservedObject var viewModel: DocumentStoreV2
    @Binding var selectedDocument: Document?
    
    var body: some View {
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
}
