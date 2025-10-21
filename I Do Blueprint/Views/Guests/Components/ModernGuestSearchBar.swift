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
    @Binding var groupByStatus: Bool
    @EnvironmentObject var settingsStore: SettingsStoreV2

    var filteredCount: Int = 0
    var totalCount: Int = 0

    private var hasActiveFilters: Bool {
        selectedStatus != nil || selectedInvitedBy != nil || !searchText.isEmpty
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Search Field
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.body)

                TextField("Search by name, email...", text: $searchText)
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
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )

            // Filters Row
            HStack(spacing: Spacing.sm) {
                Menu {
                    Button("All Status") {
                        selectedStatus = nil
                    }
                    Divider()
                    ForEach(RSVPStatus.allCases, id: \.self) { status in
                        Button {
                            selectedStatus = status
                        } label: {
                            Label(status.displayName, systemImage: status.iconName)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedStatus?.displayName ?? "All Status")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(Typography.bodySmall)
                }
                .buttonStyle(.bordered)

                Menu {
                    Button("All Guests") {
                        selectedInvitedBy = nil
                    }
                    Divider()
                    ForEach(InvitedBy.allCases, id: \.self) { invitedBy in
                        Button(invitedBy.displayName(with: settingsStore.settings)) {
                            selectedInvitedBy = invitedBy
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.2")
                        Text(selectedInvitedBy?.displayName(with: settingsStore.settings) ?? "All Guests")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(Typography.bodySmall)
                }
                .buttonStyle(.bordered)

                Spacer()

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
                if selectedStatus != nil || selectedInvitedBy != nil {
                    Button {
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
                                .padding(.leading, 4)
                        }

                        Spacer()

                        // Clear all button
                        Button("Clear all") {
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
