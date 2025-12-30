//
//  GiftRowView.swift
//  I Do Blueprint
//
//  Individual gift row component
//

import SwiftUI

struct GiftRowView: View {
    let gift: GiftReceived
    let onTap: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    var body: some View {
        HStack(spacing: 12) {
            // Gift type icon
            giftTypeIconView
            
            // Gift details
            giftDetailsView
            
            Spacer()
            
            // Amount and thank you status
            amountAndStatusView
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    // MARK: - Subviews
    
    private var giftTypeIconView: some View {
        ZStack {
            Circle()
                .fill(giftTypeColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: giftTypeIcon)
                .foregroundColor(AppColors.textPrimary)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var giftDetailsView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(gift.fromPerson)
                    .font(.system(size: 14, weight: .medium))
                
                if !gift.isThankYouSent {
                    Text("THANK YOU")
                        .font(.caption2)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(AppColors.Budget.pending)
                        .foregroundColor(AppColors.textPrimary)
                        .cornerRadius(4)
                }
            }
            
            Text(gift.giftType.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(gift.dateReceived, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var amountAndStatusView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("$\(gift.amount, specifier: "%.0f")")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.Budget.income)
            
            Button(action: toggleThankYouStatus) {
                Image(systemName: gift.isThankYouSent ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(gift.isThankYouSent ? AppColors.Budget.income : .gray)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Computed Properties
    
    private var giftTypeColor: Color {
        switch gift.giftType {
        case .cash: AppColors.Budget.income
        case .check: AppColors.Budget.allocated
        case .gift: .purple
        case .giftCard: AppColors.Budget.pending
        case .other: .gray
        }
    }
    
    private var giftTypeIcon: String {
        switch gift.giftType {
        case .cash: "dollarsign"
        case .check: "doc.text"
        case .gift: "gift"
        case .giftCard: "creditcard"
        case .other: "ellipsis"
        }
    }
    
    // MARK: - Actions
    
    private func toggleThankYouStatus() {
        var updatedGift = gift
        updatedGift.isThankYouSent.toggle()
        Task {
            await budgetStore.gifts.updateGiftReceived(updatedGift)
        }
    }
}

// MARK: - Preview

#Preview {
    GiftRowView(
        gift: GiftReceived(
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
        onTap: {}
    )
    .environmentObject(BudgetStoreV2())
    .frame(width: 600)
}
