//
//  MoneyReceivedListSection.swift
//  I Do Blueprint
//
//  List section displaying all gifts with empty state
//

import SwiftUI

struct MoneyReceivedListSection: View {
    let gifts: [GiftReceived]
    let onAddGift: () -> Void
    let onSelectGift: (GiftReceived) -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            // Content
            if gifts.isEmpty {
                emptyStateView
            } else {
                giftsListView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("Gifts Received")
                .font(.headline)
            Spacer()
            Button("Add Gift") {
                onAddGift()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No gifts received yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Add your first gift to start tracking")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Button("Add Gift") {
                onAddGift()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var giftsListView: some View {
        LazyVStack(spacing: 0) {
            ForEach(gifts, id: \.id) { gift in
                GiftRowView(gift: gift) {
                    onSelectGift(gift)
                }
                .environmentObject(budgetStore)
                
                if gift.id != gifts.last?.id {
                    Divider()
                        .padding(.leading, Spacing.huge)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MoneyReceivedListSection(
        gifts: [
            GiftReceived(
                id: UUID(),
                coupleId: UUID(),
                fromPerson: "John & Jane Doe",
                amount: 500,
                dateReceived: Date(),
                giftType: .cash,
                notes: "Wedding gift",
                isThankYouSent: false,
                createdAt: Date(),
                updatedAt: nil
            ),
            GiftReceived(
                id: UUID(),
                coupleId: UUID(),
                fromPerson: "Bob Smith",
                amount: 250,
                dateReceived: Date().addingTimeInterval(-86400),
                giftType: .check,
                notes: nil,
                isThankYouSent: true,
                createdAt: Date(),
                updatedAt: nil
            )
        ],
        onAddGift: {},
        onSelectGift: { _ in }
    )
    .environmentObject(BudgetStoreV2())
    .frame(width: 600, height: 400)
}
