//
//  MoneyReceivedViewV2.swift
//  I Do Blueprint
//
//  Refactored money received view with extracted components
//  Reduced complexity and nesting by decomposing into focused subviews
//

import SwiftUI

struct MoneyReceivedViewV2: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var searchText = ""
    @State private var selectedGiftType: GiftType?
    @State private var sortOrder: MoneyReceivedSortOrder = .dateDescending
    @State private var showingNewGiftForm = false
    @State private var selectedGift: GiftReceived?
    
    var body: some View {
        VStack(spacing: 0) {
            // Summary section
            MoneyReceivedSummaryCard(
                totalReceived: totalReceived,
                giftCount: filteredGifts.count,
                averageGiftAmount: averageGiftAmount,
                thankYouSentCount: thankYouSentCount,
                thankYouPendingCount: thankYouPendingCount
            )
            
            // Filters and sorting
            MoneyReceivedFiltersSection(
                selectedGiftType: $selectedGiftType,
                sortOrder: $sortOrder
            )
            
            // Gift type breakdown chart
            MoneyReceivedChartSection(
                giftTypeData: giftTypeData,
                totalReceived: totalReceived
            )
            
            // Gifts list
            MoneyReceivedListSection(
                gifts: filteredGifts,
                onAddGift: { showingNewGiftForm = true },
                onSelectGift: { selectedGift = $0 }
            )
            .environmentObject(budgetStore)
        }
        .searchable(text: $searchText, prompt: "Search gifts...")
        .sheet(isPresented: $showingNewGiftForm) {
            AddGiftOrOwedModal { newGift in
                Task {
                    await budgetStore.gifts.addGiftOrOwed(newGift)
                }
            }
        }
        .sheet(item: $selectedGift) { gift in
            GiftDetailView(gift: gift)
                .environmentObject(budgetStore)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalReceived: Double {
        filteredGifts.reduce(0) { $0 + $1.amount }
    }
    
    private var averageGiftAmount: Double {
        guard !filteredGifts.isEmpty else { return 0 }
        return totalReceived / Double(filteredGifts.count)
    }
    
    private var thankYouSentCount: Int {
        filteredGifts.filter(\.isThankYouSent).count
    }
    
    private var thankYouPendingCount: Int {
        filteredGifts.filter { !$0.isThankYouSent }.count
    }
    
    private var filteredGifts: [GiftReceived] {
        var gifts = budgetStore.giftsReceived
        
        // Apply search filter
        if !searchText.isEmpty {
            gifts = gifts.filter { gift in
                gift.fromPerson.localizedCaseInsensitiveContains(searchText) ||
                gift.giftType.rawValue.localizedCaseInsensitiveContains(searchText) ||
                (gift.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply gift type filter
        if let selectedType = selectedGiftType {
            gifts = gifts.filter { $0.giftType == selectedType }
        }
        
        // Apply sorting
        return sortGifts(gifts, by: sortOrder)
    }
    
    private var giftTypeData: [GiftTypeData] {
        let grouped = Dictionary(grouping: filteredGifts) { $0.giftType }
        let colors: [Color] = [
            AppColors.Budget.allocated,
            AppColors.Budget.income,
            AppColors.Budget.pending,
            .purple,
            AppColors.Budget.expense,
            .pink
        ]
        
        return GiftType.allCases.enumerated().compactMap { index, type in
            let gifts = grouped[type] ?? []
            let amount = gifts.reduce(0) { $0 + $1.amount }
            guard amount > 0 else { return nil }
            
            return GiftTypeData(
                type: type,
                amount: amount,
                count: gifts.count,
                color: colors[index % colors.count]
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func sortGifts(_ gifts: [GiftReceived], by order: MoneyReceivedSortOrder) -> [GiftReceived] {
        switch order {
        case .dateDescending:
            return gifts.sorted { $0.dateReceived > $1.dateReceived }
        case .dateAscending:
            return gifts.sorted { $0.dateReceived < $1.dateReceived }
        case .amountDescending:
            return gifts.sorted { $0.amount > $1.amount }
        case .amountAscending:
            return gifts.sorted { $0.amount < $1.amount }
        case .personAscending:
            return gifts.sorted { $0.fromPerson < $1.fromPerson }
        }
    }
}

// MARK: - Preview

#Preview {
    MoneyReceivedViewV2()
        .environmentObject(BudgetStoreV2())
}
