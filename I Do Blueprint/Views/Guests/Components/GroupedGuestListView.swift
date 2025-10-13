//
//  GroupedGuestListView.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct GroupedGuestListView: View {
    let guests: [Guest]
    let isLoading: Bool
    @Binding var selectedGuest: Guest?
    let onRefresh: () async -> Void

    private var groupedGuests: [(RSVPStatus, [Guest])] {
        Dictionary(grouping: guests, by: \.rsvpStatus)
            .sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        if isLoading {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(0..<6, id: \.self) { _ in
                        GuestCardSkeleton()
                    }
                }
                .padding(Spacing.lg)
            }
            .background(AppColors.background)
        } else if guests.isEmpty {
            EmptyGuestListView()
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.xl, pinnedViews: [.sectionHeaders]) {
                    ForEach(groupedGuests, id: \.0) { status, statusGuests in
                        Section {
                            LazyVStack(spacing: Spacing.md) {
                                ForEach(statusGuests) { guest in
                                    Button {
                                        selectedGuest = guest
                                    } label: {
                                        ModernGuestCard(
                                            guest: guest,
                                            isSelected: selectedGuest?.id == guest.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } header: {
                            StatusSectionHeader(
                                status: status,
                                count: statusGuests.count
                            )
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(AppColors.background)
            .refreshable {
                await onRefresh()
            }
        }
    }
}
