//
//  ModernGuestListView.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct ModernGuestListView: View {
    let guests: [Guest]
    let totalCount: Int
    let isLoading: Bool
    let isSearching: Bool
    let onClearSearch: () -> Void
    @Binding var selectedGuest: Guest?
    let onRefresh: () async -> Void

    var body: some View {
        ZStack {
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
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if guests.isEmpty {
                if isSearching {
                    SearchEmptyStateView(searchText: "", onClearSearch: onClearSearch)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    EmptyGuestListView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Count header
                        ListCountHeaderView(
                            filteredCount: guests.count,
                            totalCount: totalCount,
                            itemName: guests.count == 1 ? "guest" : "guests"
                        )
                        .padding(.bottom, Spacing.sm)

                        LazyVStack(spacing: Spacing.md) {
                            ForEach(Array(guests.enumerated()), id: \.element.id) { index, guest in
                                Button {
                                    HapticFeedback.selectionChanged()
                                    selectedGuest = guest
                                } label: {
                                    ModernGuestCard(
                                        guest: guest,
                                        isSelected: selectedGuest?.id == guest.id
                                    )
                                }
                                .buttonStyle(.plain)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(
                                    AnimationPresets.gentleSpring.delay(Double(index) * 0.05),
                                    value: guests.count
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
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(AnimationPresets.mediumEase, value: isLoading)
        .animation(AnimationPresets.mediumEase, value: guests.isEmpty)
    }
}
