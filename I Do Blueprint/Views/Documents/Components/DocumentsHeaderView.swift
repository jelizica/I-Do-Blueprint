//
//  DocumentsHeaderView.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Header view for documents screen with search, view mode toggle, filters, and selection controls
struct DocumentsHeaderView: View {
    @ObservedObject var viewModel: DocumentStoreV2
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
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
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Circle().fill(Color.blue))
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                }
            }
            .buttonStyle(.plain)
            
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
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
