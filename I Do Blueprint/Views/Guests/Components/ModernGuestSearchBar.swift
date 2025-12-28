//
//  ModernGuestSearchBar.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct ModernSearchBar: View {
    @Binding var searchText: String
    @Binding var selectedStatus: RSVPStatus?
    @Binding var selectedInvitedBy: InvitedBy?
    @Binding var selectedSortOption: GuestSortOption
    @Binding var groupByStatus: Bool
    @EnvironmentObject var settingsStore: SettingsStoreV2
    
    // Optional reference to guest store (kept for compatibility but not used for filtering)
    var guestStore: GuestStoreV2?

    var filteredCount: Int = 0
    var totalCount: Int = 0

    private var hasActiveFilters: Bool {
        selectedStatus != nil || selectedInvitedBy != nil || !searchText.isEmpty
    }
    
    // Define the main RSVP status filters we want to show as toggles
    private let mainStatusFilters: [RSVPStatus?] = [nil, .attending, .pending, .declined]

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Single Row: Search + Status Toggles + Invited By Toggles + Sort + View Toggle + Clear
            HStack(spacing: Spacing.sm) {
                // Search Field
                HStack(spacing: Spacing.sm) {
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
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                )

                // RSVP Status Toggle Buttons
                ForEach(mainStatusFilters, id: \.self) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        Text(status?.displayName ?? "All Status")
                            .font(Typography.bodySmall)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(selectedStatus == status ? AppColors.primary : AppColors.cardBackground)
                    )
                    .foregroundColor(selectedStatus == status ? .white : AppColors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .stroke(selectedStatus == status ? AppColors.primary : AppColors.border, lineWidth: 1)
                    )
                }

                // Invited By Toggle Buttons
                ForEach([nil] + InvitedBy.allCases, id: \.self) { invitedBy in
                    Button {
                        selectedInvitedBy = invitedBy
                    } label: {
                        Text(invitedBy?.displayName(with: settingsStore.settings) ?? "All Guests")
                            .font(Typography.bodySmall)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(selectedInvitedBy == invitedBy ? AppColors.primary : AppColors.cardBackground)
                    )
                    .foregroundColor(selectedInvitedBy == invitedBy ? .white : AppColors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .stroke(selectedInvitedBy == invitedBy ? AppColors.primary : AppColors.border, lineWidth: 1)
                    )
                }

                Spacer()

                // Sort Menu
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
                }
                .buttonStyle(.bordered)
                .help("Sort guests")

                // Group Toggle
                Button {
                    groupByStatus.toggle()
                } label: {
                    Image(systemName: groupByStatus ? "square.grid.2x2" : "list.bullet")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .help(groupByStatus ? "List View" : "Group View")

                // Clear Filters
                if selectedStatus != nil || selectedInvitedBy != nil || !searchText.isEmpty {
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

            // Active Filter Chips
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Status filter chip
                        if let status = selectedStatus {
                            ActiveFilterChip(label: "Status: \(status.displayName)") {
                                selectedStatus = nil
                            }
                        }

                        // Invited By filter chip
                        if let invitedBy = selectedInvitedBy {
                            ActiveFilterChip(label: "Invited By: \(invitedBy.displayName(with: settingsStore.settings))") {
                                selectedInvitedBy = nil
                            }
                        }

                        // Search filter chip
                        if !searchText.isEmpty {
                            ActiveFilterChip(label: "Search: \"\(searchText)\"") {
                                searchText = ""
                            }
                        }

                        // Result count
                        if totalCount > 0 {
                            Text("\(filteredCount) of \(totalCount) guests")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.leading, Spacing.xs)
                        }

                        Spacer()

                        // Clear all button
                        Button("Clear all") {
                            // Clear all filter state (filtering is computed in view)
                            searchText = ""
                            selectedStatus = nil
                            selectedInvitedBy = nil
                        }
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.sm)
                }
            }
        }
    }
}
