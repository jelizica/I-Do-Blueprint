//
//  DocumentsGridView.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Grid layout view for displaying documents as cards
struct DocumentsGridView: View {
    @ObservedObject var viewModel: DocumentStoreV2
    @Binding var selectedDocument: Document?
    
    var body: some View {
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
        .padding(Spacing.xl)
    }
}
