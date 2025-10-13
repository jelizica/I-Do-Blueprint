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
                        .foregroundColor(.orange)
                    Text("Note: Changes in this view are local only and not yet persisted to the database.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))

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
                            await budgetStore.addGiftOrOwed(newGift)
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
                            await budgetStore.updateGiftOrOwed(updatedGift)
                        }
                    },
                    onDelete: { giftToDelete in
                        Task {
                            await budgetStore.deleteGiftOrOwed(id: giftToDelete.id)
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

    // MARK: - Summary Cards

    private var summaryCardsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                GiftSummaryCard(
                    title: "Received",
                    value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.totalReceived)) ?? "$0",
                    subtitle: "Available now",
                    icon: "checkmark.circle.fill",
                    color: .green)

                GiftSummaryCard(
                    title: "Pending",
                    value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.totalPending)) ?? "$0",
                    subtitle: "Expected",
                    icon: "clock.fill",
                    color: .orange)

                GiftSummaryCard(
                    title: "Total Budget Addition",
                    value: NumberFormatter.currency
                        .string(from: NSNumber(value: budgetStore.totalBudgetAddition)) ?? "$0",
                    subtitle: "Total expansion",
                    icon: "plus.circle.fill",
                    color: .blue)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Gifts or Money Owed",
            systemImage: "gift.circle",
            description: Text("Track gifts received and money owed that expand your wedding budget"))
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
                            await budgetStore.deleteGiftOrOwed(id: gift.id)
                        }
                    })
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Supporting Views

struct GiftSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1))
    }
}

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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
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
                        Text("Expected: \(formatDate(expectedDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let receivedDate = giftOrOwed.receivedDate {
                        Text("Received: \(formatDate(receivedDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
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

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

#Preview {
    GiftsAndOwedView()
        .environmentObject(BudgetStoreV2())
}
