//
//  GuestSearchAndFilters.swift
//  I Do Blueprint
//
//  Search and filter controls for guest management
//  Matches vendor management design with horizontal layout
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
        HStack(spacing: Spacing.md) {
            // Search Field (left)
            searchField
            
            // Status Filter Tabs (center-left)
            statusFilterTabs
            
            // Invited By Filter Tabs (center-right)
            invitedByFilterTabs
            
            Spacer()
            
            // Sort Menu (right)
            sortMenu
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.backgroundSecondary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
        
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SemanticColors.textSecondary)
                .font(.body)

            TextField("Search guests by name or email...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.white.opacity(0.6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Status Filter Tabs
    
    private var statusFilterTabs: some View {
        HStack(spacing: 2) {
            ForEach([nil, RSVPStatus.confirmed, RSVPStatus.pending, RSVPStatus.declined], id: \.self) { status in
                StatusTabButton(
                    status: status,
                    isSelected: selectedStatus == status,
                    onTap: { selectedStatus = status },
                    settings: settings
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.gray.opacity(0.15))
        )
    }
    
    // MARK: - Invited By Filter Tabs
    
    private var invitedByFilterTabs: some View {
        HStack(spacing: 2) {
            ForEach([nil] + InvitedBy.allCases, id: \.self) { invitedBy in
                InvitedByTabButton(
                    invitedBy: invitedBy,
                    settings: settings,
                    isSelected: selectedInvitedBy == invitedBy,
                    onTap: { selectedInvitedBy = invitedBy }
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.gray.opacity(0.15))
        )
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
                                        .foregroundColor(SemanticColors.primaryAction)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text("Sort:")
                    .font(.system(size: 11))
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text("Name (A-Z)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(SemanticColors.textPrimary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .help("Sort guests")
    }
}

// MARK: - Supporting Views

private struct StatusTabButton: View {
    let status: RSVPStatus?
    let isSelected: Bool
    let onTap: () -> Void
    let settings: CoupleSettings
    
    private var guestCount: Int {
        // This would ideally come from the store, but for now we'll show placeholder
        0
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Text(status?.displayName ?? "All Guests")
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                
                if guestCount > 0 {
                    Text("\(guestCount)")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.3))
                        )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white : Color.clear)
                    .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
            )
            .foregroundColor(isSelected ? SemanticColors.textPrimary : SemanticColors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

private struct InvitedByTabButton: View {
    let invitedBy: InvitedBy?
    let settings: CoupleSettings
    let isSelected: Bool
    let onTap: () -> Void
    
    private var displayText: String {
        if let invitedBy = invitedBy {
            return "Invited By: \(invitedBy.displayName(with: settings))"
        } else {
            return "All Guests"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white : Color.clear)
                        .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
                )
                .foregroundColor(isSelected ? SemanticColors.textPrimary : SemanticColors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
