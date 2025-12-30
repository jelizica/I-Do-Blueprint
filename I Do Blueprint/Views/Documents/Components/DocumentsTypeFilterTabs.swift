//
//  DocumentsTypeFilterTabs.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Horizontal scrollable tabs for filtering documents by type
struct DocumentsTypeFilterTabs: View {
    @ObservedObject var viewModel: DocumentStoreV2
    
    var body: some View {
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
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Helper Methods
    
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
