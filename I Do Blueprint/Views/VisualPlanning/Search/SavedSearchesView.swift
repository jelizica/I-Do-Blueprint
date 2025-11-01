//
//  SavedSearchesView.swift
//  I Do Blueprint
//
//  Manage saved search queries for quick access
//

import SwiftUI

struct SavedSearchesView: View {
    @Binding var savedSearches: [SavedSearch]
    let onSelect: (SavedSearch) -> Void
    let onDelete: (SavedSearch) -> Void
    let onDismiss: () -> Void
    
    @State private var editingSearch: SavedSearch?
    @State private var showingRenameAlert = false
    @State private var newName = ""
    @State private var searchFilter = ""
    @State private var sortOption: SortOption = .lastUsed
    
    private let logger = AppLogger.ui
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Search and sort
            controlsSection
            
            Divider()
            
            // Saved searches list
            if filteredSearches.isEmpty {
                emptyStateSection
            } else {
                savedSearchesListSection
            }
            
            Divider()
            
            // Footer
            footerSection
        }
        .frame(width: 550, height: 650)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Saved Searches")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(savedSearches.count) saved search\(savedSearches.count == 1 ? "" : "es")")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close saved searches")
        }
        .padding()
    }
    
    // MARK: - Controls
    
    private var controlsSection: some View {
        HStack(spacing: Spacing.md) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Search saved searches...", text: $searchFilter)
                    .textFieldStyle(.plain)
                
                if !searchFilter.isEmpty {
                    Button(action: { searchFilter = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            // Sort picker
            Picker("Sort", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
        }
        .padding()
    }
    
    // MARK: - Saved Searches List
    
    private var savedSearchesListSection: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(filteredSearches) { search in
                    SavedSearchRow(
                        search: search,
                        onSelect: {
                            logger.info("Loading saved search: \(search.name)")
                            onSelect(search)
                        },
                        onRename: {
                            editingSearch = search
                            newName = search.name
                            showingRenameAlert = true
                        },
                        onDelete: {
                            logger.info("Deleting saved search: \(search.name)")
                            onDelete(search)
                        }
                    )
                }
            }
            .padding()
        }
        .alert("Rename Search", isPresented: $showingRenameAlert) {
            TextField("Search name", text: $newName)
            Button("Cancel", role: .cancel) {
                editingSearch = nil
                newName = ""
            }
            Button("Rename") {
                if let search = editingSearch, !newName.isEmpty {
                    renameSearch(search, to: newName)
                }
                editingSearch = nil
                newName = ""
            }
        } message: {
            Text("Enter a new name for this saved search")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateSection: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)
            
            Text(searchFilter.isEmpty ? "No Saved Searches" : "No Matching Searches")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
            
            Text(searchFilter.isEmpty ?
                 "Save your frequently used searches for quick access" :
                 "Try adjusting your search filter")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if !searchFilter.isEmpty {
                Button("Clear Filter") {
                    searchFilter = ""
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            Text("Tip: Save searches from the main search view")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private var filteredSearches: [SavedSearch] {
        let filtered = searchFilter.isEmpty ? savedSearches : savedSearches.filter { search in
            search.name.localizedCaseInsensitiveContains(searchFilter) ||
            search.query.localizedCaseInsensitiveContains(searchFilter)
        }
        
        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .name:
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            case .dateCreated:
                return lhs.createdAt > rhs.createdAt
            case .lastUsed:
                // Sort by last used, with never-used searches at the end
                switch (lhs.lastUsed, rhs.lastUsed) {
                case (nil, nil):
                    // Both never used - sort by creation date
                    return lhs.createdAt > rhs.createdAt
                case (nil, _):
                    // lhs never used - put it after rhs
                    return false
                case (_, nil):
                    // rhs never used - put lhs before it
                    return true
                case let (lhsDate?, rhsDate?):
                    // Both have been used - sort by most recent
                    return lhsDate > rhsDate
                }
            }
        }
    }
    
    private func renameSearch(_ search: SavedSearch, to newName: String) {
        if let index = savedSearches.firstIndex(where: { $0.id == search.id }) {
            // Create new SavedSearch with updated name
            let updatedSearch = SavedSearch(
                name: newName,
                query: search.query,
                filters: search.filters,
                createdAt: search.createdAt,
                lastUsed: search.lastUsed
            )
            savedSearches[index] = updatedSearch
            logger.info("Renamed search to: \(newName)")
        }
    }
    
    // MARK: - Sort Option
    
    enum SortOption: String, CaseIterable {
        case lastUsed = "Last Used"
        case name = "Name"
        case dateCreated = "Date Created"
        
        var displayName: String {
            rawValue
        }
    }
}

// MARK: - Saved Search Row

struct SavedSearchRow: View {
    let search: SavedSearch
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: "bookmark.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 30)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(search.name)
                        .font(Typography.subheading)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    if !search.query.isEmpty {
                        Text("Query: \"\(search.query)\"")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: Spacing.sm) {
                        Label(formatDate(search.createdAt), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if let lastUsed = search.lastUsed {
                            Text("•")
                                .foregroundColor(AppColors.textSecondary)
                            
                            Label("Used \(formatRelativeDate(lastUsed))", systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        if activeFilterCount > 0 {
                            Text("•")
                                .foregroundColor(AppColors.textSecondary)
                            
                            Label("\(activeFilterCount) filter\(activeFilterCount == 1 ? "" : "s")", systemImage: "line.3.horizontal.decrease")
                                .font(.caption2)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
                
                Spacer()
                
                // Actions (shown on hover)
                if isHovered {
                    HStack(spacing: 4) {
                        Button(action: onRename) {
                            Image(systemName: "pencil")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("Rename")
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        count += search.filters.styleCategories.count
        count += search.filters.seasons.count
        count += search.filters.colors.count
        if search.filters.favoritesOnly { count += 1 }
        if search.filters.showTemplatesOnly { count += 1 }
        if search.filters.finalizedOnly { count += 1 }
        if search.filters.dateRange != nil { count += 1 }
        return count
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    SavedSearchesView(
        savedSearches: .constant([
            SavedSearch(
                name: "Romantic Mood Boards",
                query: "romantic",
                filters: SearchFilters(tenantId: "preview"),
                createdAt: Date().addingTimeInterval(-86400 * 7),
                lastUsed: Date().addingTimeInterval(-3600)
            ),
            SavedSearch(
                name: "Spring Color Palettes",
                query: "spring",
                filters: SearchFilters(tenantId: "preview"),
                createdAt: Date().addingTimeInterval(-86400 * 14)
            )
        ]),
        onSelect: { _ in },
        onDelete: { _ in },
        onDismiss: {}
    )
}
