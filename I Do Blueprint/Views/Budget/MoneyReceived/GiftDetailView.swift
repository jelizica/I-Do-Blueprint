//
//  GiftDetailView.swift
//  I Do Blueprint
//
//  Detail modal for viewing and editing a gift
//

import SwiftUI

struct GiftDetailView: View {
    let gift: GiftReceived
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var showingEditForm = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Gift amount and thank you status
                headerView
                
                // Gift details
                detailsView
                
                Spacer()
            }
            .padding()
            .navigationTitle("Gift Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditForm = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            editFormSheet
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("$\(gift.amount, specifier: "%.2f")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.Budget.income)
            
            Spacer()
            
            Button(action: toggleThankYouStatus) {
                HStack(spacing: 4) {
                    Image(systemName: gift.isThankYouSent ? "checkmark.circle.fill" : "circle")
                    Text(gift.isThankYouSent ? "Thank You Sent" : "Send Thank You")
                }
                .font(.caption)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(gift.isThankYouSent ? AppColors.Budget.income : AppColors.Budget.pending)
                .foregroundColor(SemanticColors.textPrimary)
                .cornerRadius(8)
            }
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            GiftDetailRow(label: "From", value: gift.fromPerson)
            GiftDetailRow(label: "Type", value: gift.giftType.rawValue)
            GiftDetailRow(
                label: "Date Received",
                value: gift.dateReceived.formatted(date: .abbreviated, time: .omitted)
            )
            
            if let notes = gift.notes, !notes.isEmpty {
                GiftDetailRow(label: "Notes", value: notes)
            }
        }
    }
    
    @ViewBuilder
    private var editFormSheet: some View {
        if let giftOrOwed = convertToGiftOrOwed(gift: gift) {
            EditGiftOrOwedModal(
                giftOrOwed: giftOrOwed,
                onSave: { updatedGift in
                    Task {
                        await budgetStore.gifts.updateGiftOrOwed(updatedGift)
                    }
                },
                onDelete: { giftToDelete in
                    Task {
                        await budgetStore.gifts.deleteGiftOrOwed(id: giftToDelete.id)
                    }
                }
            )
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
    
    private func convertToGiftOrOwed(gift: GiftReceived) -> GiftOrOwed? {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            return nil
        }
        return GiftOrOwed(
            id: UUID(),
            coupleId: coupleId,
            title: "Gift from \(gift.fromPerson)",
            amount: gift.amount,
            type: .giftReceived,
            description: gift.notes,
            fromPerson: gift.fromPerson,
            expectedDate: nil,
            receivedDate: gift.dateReceived,
            status: .received,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}

// MARK: - Supporting Views

private struct GiftDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14))
        }
    }
}

// MARK: - Preview

#Preview {
    GiftDetailView(
        gift: GiftReceived(
            id: UUID(),
            coupleId: UUID(),
            fromPerson: "John & Jane Doe",
            amount: 500,
            dateReceived: Date(),
            giftType: .cash,
            notes: "Wedding gift from our neighbors",
            isThankYouSent: false,
            createdAt: Date(),
            updatedAt: nil
        )
    )
    .environmentObject(BudgetStoreV2())
}
