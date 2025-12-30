//
//  DocumentsEmptyStateView.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Empty state view for when no documents are available or filters return no results
struct DocumentsEmptyStateView: View {
    @ObservedObject var viewModel: DocumentStoreV2
    let onAddDocument: () -> Void
    
    var body: some View {
        Group {
            if viewModel.hasActiveFilters {
                UnifiedEmptyStateView(config: .filteredResults())
            } else {
                UnifiedEmptyStateView(config: .documents(onAdd: onAddDocument))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
