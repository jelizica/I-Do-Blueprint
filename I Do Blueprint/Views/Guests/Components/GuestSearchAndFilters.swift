//
//  GuestSearchAndFilters.swift
//  I Do Blueprint
//
//  Search and filter controls for guest management
//

import SwiftUI

struct GuestSearchAndFilters: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var selectedStatus: RSVPStatus?
    @Binding var selectedInvitedBy: InvitedBy?
    @Binding var selectedSortOption: GuestSortOption
    let settings: CoupleSettings
    
    private var hasActiveFilters: Bool {
        selectedStatus != nil || selectedInvitedBy != nil || !searchText.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if windowSize == .compact {
                // Compact: Collapsible menus
                compactLayout
            } else {
                // Regular/Large: Single row layout
                regularLayout
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Search bar (full width, aligned)
            searchField
            
            // Filter menus row (aligned with search bar edges)
            HStack(spacing: Spacing.sm) {
                statusFilterMenu
                    .frame(maxWidth: .infinity, alignment: .leading)
                invitedByFilterMenu
                    .frame(maxWidth: .infinity, alignment: .center)
                sortMenu
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Clear all button (centered, only when filters active)
            if hasActiveFilters {
                HStack {
                    Spacer()
                    clearAllFiltersButton
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.sm) {
            // Search Field
            searchField
            
            // RSVP Status Toggle Buttons (Blue - Primary)
            statusFilters
            
            // Invited By Toggle Buttons (Teal - Different color to differentiate)
            invitedByFilters
            
            Spacer()
            
            // Sort Menu
            sortMenu
            
            // Clear Filters
            if hasActiveFilters {
                clearFiltersButton
            }
        }
    }
    
    // MARK: - Status Filter Menu (Compact Mode)
    
    private var statusFilterMenu: some View {
        Menu {
            ForEach([nil, RSVPStatus.attending, RSVPStatus.pending, RSVPStatus.declined], id: \.self) { status in
                Button {
                    selectedStatus = status
                } label: {
                    HStack {
                        Text(status?.displayName ?? "All Status")
                        if selectedStatus == status {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                // Filter icon on LEFT (always visible)
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.caption)
                
                Text(selectedStatus?.displayName ?? "Status")
                    .font(Typography.bodySmall)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.bordered)
        .tint(AppColors.primary)
        .help("Filter by RSVP status")
    }
    
    // MARK: - Invited By Filter Menu (Compact Mode)
    
    private var invitedByFilterMenu: some View {
        Menu {
            ForEach([nil] + InvitedBy.allCases, id: \.self) { invitedBy in
                Button {
                    selectedInvitedBy = invitedBy
                } label: {
                    HStack {
                        Text(invitedBy?.displayName(with: settings) ?? "All Guests")
                        if selectedInvitedBy == invitedBy {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                // Filter icon on LEFT (always visible)
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.caption)
                
                Text(selectedInvitedBy?.displayName(with: settings) ?? "Invited By")
                    .font(Typography.bodySmall)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.bordered)
        .tint(Color.teal)
        .help("Filter by who invited the guest")
    }
    
    // MARK: - Search Field
    
    @ViewBuilder
    private var searchField: some View {
        let content = HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(.body)

            TextField("Search guests...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        
        if windowSize == .compact {
            content
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                )
        } else {
            content
                .frame(minWidth: 150, idealWidth: 200, maxWidth: 250)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Status Filters (Regular Mode)
    
    private var statusFilters: some View {
        ForEach([nil, RSVPStatus.attending, RSVPStatus.pending, RSVPStatus.declined], id: \.self) { status in
            StatusFilterButton(
                status: status,
                isSelected: selectedStatus == status,
                onTap: { selectedStatus = status }
            )
        }
    }
    
    // MARK: - Invited By Filters (Regular Mode)
    
    private var invitedByFilters: some View {
        ForEach([nil] + InvitedBy.allCases, id: \.self) { invitedBy in
            InvitedByFilterButton(
                invitedBy: invitedBy,
                settings: settings,
                isSelected: selectedInvitedBy == invitedBy,
                onTap: { selectedInvitedBy = invitedBy }
            )
        }
    }
    
    // MARK: - Sort Menu
    
    private var sortMenu: some View {
        Menu {
            ForEach(GuestSortOption.grouped, id: \.0) { group in
                Section(group.0) {
                    ForEach(group.1) { option in
                        Button {
                            selectedSortOption = option
                        } label: {
                            HStack {
                                Label(option.displayName, systemImage: option.iconName)
                                if selectedSortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                Text(selectedSortOption.groupLabel)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .font(Typography.bodySmall)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.bordered)
        .help("Sort guests")
    }
    
    // MARK: - Clear All Filters Button (Compact Mode)
    
    private var clearAllFiltersButton: some View {
        Button {
            searchText = ""
            selectedStatus = nil
            selectedInvitedBy = nil
        } label: {
            Text("Clear All Filters")
                .font(Typography.bodySmall)
        }
        .buttonStyle(.borderless)
        .foregroundColor(AppColors.primary)
    }
    
    // MARK: - Clear Filters Button (Regular Mode)
    
    private var clearFiltersButton: some View {
        Button {
            searchText = ""
            selectedStatus = nil
            selectedInvitedBy = nil
        } label: {
            Text("Clear")
                .font(Typography.bodySmall)
        }
        .buttonStyle(.borderless)
        .foregroundColor(AppColors.primary)
    }
}

// MARK: - Supporting Views (Regular Mode)

private struct StatusFilterButton: View {
    let status: RSVPStatus?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(status?.displayName ?? "All Status")
                .font(Typography.bodySmall)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.pill)
                .fill(isSelected ? AppColors.primary : AppColors.cardBackground)
        )
        .foregroundColor(isSelected ? .white : AppColors.textPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.pill)
                .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 1)
        )
    }
}

private struct InvitedByFilterButton: View {
    let invitedBy: InvitedBy?
    let settings: CoupleSettings
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(invitedBy?.displayName(with: settings) ?? "All Guests")
                .font(Typography.bodySmall)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.pill)
                .fill(isSelected ? Color.teal : AppColors.cardBackground)
        )
        .foregroundColor(isSelected ? .white : AppColors.textPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.pill)
                .stroke(isSelected ? Color.teal : AppColors.border, lineWidth: 1)
        )
    }
}
