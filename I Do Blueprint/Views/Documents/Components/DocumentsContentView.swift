//
//  DocumentsContentView.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Main content area that switches between grid and list views
struct DocumentsContentView: View {
    @ObservedObject var viewModel: DocumentStoreV2
    @Binding var selectedDocument: Document?
    @Binding var showingTypePickerModal: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Batch operations bar
            if viewModel.isSelectionMode {
                DocumentsBatchOperationsBar(
                    viewModel: viewModel,
                    showingTypePickerModal: $showingTypePickerModal
                )
                Divider()
            }
            
            // Grid or List view
            ScrollView {
                if viewModel.viewMode == .grid {
                    DocumentsGridView(
                        viewModel: viewModel,
                        selectedDocument: $selectedDocument
                    )
                } else {
                    DocumentsListView(
                        viewModel: viewModel,
                        selectedDocument: $selectedDocument
                    )
                }
            }
        }
    }
}
