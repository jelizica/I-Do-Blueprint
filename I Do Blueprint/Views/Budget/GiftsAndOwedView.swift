import SwiftUI

struct GiftsAndOwedView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var showingAddGift = false
    @State private var editingGift: GiftOrOwed?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Warning: Feature not yet persisted to database
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.Budget.pending)
                    Text("Note: Changes in this view are local only and not yet persisted to the database.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(AppColors.Budget.pending.opacity(0.1))

                // Header with summary cards
                summaryCardsView
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Items list
                if budgetStore.giftsAndOwed.isEmpty {
                    emptyStateView
                } else {
                    itemsListView
                }
            }
            .navigationTitle("Gifts & Money Owed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddGift = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    Button(action: {
                        Task {
                            await budgetStore.refreshBudgetData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddGift) {
                AddGiftOrOwedModal(
                    onSave: { newGift in
                        Task {
                            await budgetStore.gifts.addGiftOrOwed(newGift)
                        }
                    })
                #if os(macOS)
                    .frame(minWidth: 500, maxWidth: 600, minHeight: 400, maxHeight: 500)
                #endif
            }
            .sheet(item: $editingGift) { gift in
                EditGiftOrOwedModal(
                    giftOrOwed: gift,
                    onSave: { updatedGift in
                        Task {
                            await budgetStore.gifts.updateGiftOrOwed(updatedGift)
                        }
                    },
                    onDelete: { giftToDelete in
                        Task {
                            await budgetStore.gifts.deleteGiftOrOwed(id: giftToDelete.id)
                        }
                    })
                #if os(macOS)
                    .frame(minWidth: 500, maxWidth: 600, minHeight: 400, maxHeight: 500)
                #endif
            }
        }
        .task {
            await budgetStore.loadBudgetData()
        }
    }

    // MARK: - Summary Cards - Using Component Library

    private var summaryCardsView: some View {
        StatsGridView(
            stats: [
                StatItem(
                    icon: "checkmark.circle.fill",
                    label: "Received",
                    value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.totalReceived)) ?? "$0",
                    color: AppColors.Budget.income
                ),
                StatItem(
                    icon: "clock.fill",
                    label: "Pending",
                    value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.totalPending)) ?? "$0",
                    color: AppColors.Budget.pending
                ),
                StatItem(
                    icon: "plus.circle.fill",
                    label: "Total Budget Addition",
                    value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.totalBudgetAddition)) ?? "$0",
                    color: AppColors.Budget.allocated
                )
            ],
            columns: 3
        )
    }

    // MARK: - Empty State - Using Component Library

    private var emptyStateView: some View {
        UnifiedEmptyStateView(
            config: .custom(
                icon: "gift.circle",
                title: "No Gifts or Money Owed",
                message: "Track gifts received and money owed that expand your wedding budget",
                actionTitle: "Add Item",
                onAction: { showingAddGift = true }
            )
        )
        .padding()
    }

    // MARK: - Items List

    private var itemsListView: some View {
        List {
            ForEach(budgetStore.giftsAndOwed) { item in
                GiftOrOwedRowView(
                    giftOrOwed: item,
                    onEdit: { gift in
                        editingGift = gift
                    },
                    onDelete: { gift in
                        Task {
                            await budgetStore.gifts.deleteGiftOrOwed(id: gift.id)
                        }
                    })
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Supporting Views

// Note: GiftSummaryCard replaced with StatsGridView from component library

struct GiftOrOwedRowView: View {
    let giftOrOwed: GiftOrOwed
    let onEdit: (GiftOrOwed) -> Void
    let onDelete: (GiftOrOwed) -> Void

    var body: some View {
        Button(action: {
            onEdit(giftOrOwed)
        }) {
            HStack(spacing: 16) {
                // Type icon
                Circle()
                    .fill(giftOrOwed.status.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: giftOrOwed.type.iconName)
                            .foregroundColor(giftOrOwed.status.color)
                            .font(.title3))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(giftOrOwed.title)
                            .font(.headline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(NumberFormatter.currency.string(from: NSNumber(value: giftOrOwed.amount)) ?? "$0")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(giftOrOwed.status.color)
                    }

                    HStack {
                        Text(giftOrOwed.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())

                        if let fromPerson = giftOrOwed.fromPerson, !fromPerson.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("from \(fromPerson)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(giftOrOwed.status.displayName)
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(giftOrOwed.status.color.opacity(0.2))
                            .foregroundColor(giftOrOwed.status.color)
                            .clipShape(Capsule())
                    }

                    if let description = giftOrOwed.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // Date information
                    if let expectedDate = giftOrOwed.expectedDate, giftOrOwed.status == .pending {
                        Text("Expected: \(formatDateInUserTimezone(expectedDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let receivedDate = giftOrOwed.receivedDate {
                        Text("Received: \(formatDateInUserTimezone(receivedDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit") {
                onEdit(giftOrOwed)
            }

            Button("Delete", role: .destructive) {
                onDelete(giftOrOwed)
            }
        }
    }
}

// MARK: - Helper Functions

private func formatDateInUserTimezone(_ date: Date) -> String {
    // Use user's timezone for date formatting
    let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    return DateFormatting.formatDateMedium(date, timezone: userTimezone)
}

#Preview {
    GiftsAndOwedView()
        .environmentObject(BudgetStoreV2())
}
