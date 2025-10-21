//
//  MoneyOwedRow.swift
//  I Do Blueprint
//
//  Row and detail view components for money owed
//

import SwiftUI

// MARK: - Owed Row View

struct OwedRowView: View {
    let owed: MoneyOwed
    let onTap: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            ZStack {
                Circle()
                    .fill(owed.priority.color)
                    .frame(width: 40, height: 40)

                Text(owed.priority.abbreviation)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(owed.toPerson)
                        .font(.system(size: 14, weight: .medium))

                    if isOverdue {
                        Text("OVERDUE")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.Budget.overBudget)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    if owed.isPaid {
                        Text("PAID")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.Budget.income)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text(owed.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let dueDate = owed.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption2)
                        .foregroundStyle(isOverdue ? AppColors.Budget.overBudget : .secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(owed.amount, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.Budget.expense)

                Button(action: {
                    togglePaidStatus()
                }) {
                    Image(systemName: owed.isPaid ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(owed.isPaid ? AppColors.Budget.income : .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = owed.dueDate else { return false }
        return !owed.isPaid && dueDate < Date()
    }

    private func togglePaidStatus() {
        var updatedOwed = owed
        updatedOwed.isPaid.toggle()
        Task {
            await budgetStore.gifts.updateMoneyOwed(updatedOwed)
        }
    }
}

// MARK: - Money Owed Detail Row

struct MoneyOwedDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Owed Detail View

struct OwedDetailView: View {
    let owed: MoneyOwed
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var authContext: AuthContext
    @State private var showingEditForm = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Amount
                HStack {
                    Text("$\(owed.amount, specifier: "%.2f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.Budget.expense)

                    Spacer()

                    Button(action: {
                        var updatedOwed = owed
                        updatedOwed.isPaid.toggle()
                        Task {
                            await budgetStore.gifts.updateMoneyOwed(updatedOwed)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: owed.isPaid ? "checkmark.circle.fill" : "circle")
                            Text(owed.isPaid ? "Paid" : "Mark as Paid")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(owed.isPaid ? AppColors.Budget.income : AppColors.Budget.pending)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    MoneyOwedDetailRow(label: "To", value: owed.toPerson)
                    MoneyOwedDetailRow(label: "Reason", value: owed.reason)
                    MoneyOwedDetailRow(label: "Priority", value: owed.priority.rawValue)

                    if let dueDate = owed.dueDate {
                        MoneyOwedDetailRow(
                            label: "Due Date",
                            value: dueDate.formatted(date: .abbreviated, time: .omitted))
                    }

                    if let notes = owed.notes, !notes.isEmpty {
                        MoneyOwedDetailRow(label: "Notes", value: notes)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Owed Details")
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
            // Convert MoneyOwed to GiftOrOwed for editing
            if let giftOrOwed = convertToGiftOrOwed(owed: owed) {
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
                    })
            }
        }
    }

    private func convertToGiftOrOwed(owed: MoneyOwed) -> GiftOrOwed? {
        do {
            let coupleId = try authContext.requireCoupleId()
            
            return GiftOrOwed(
                id: UUID(), // Will be handled by database
                coupleId: coupleId,
                title: owed.reason,
                amount: owed.amount,
                type: .moneyOwed,
                description: owed.notes,
                fromPerson: owed.toPerson,
                expectedDate: owed.dueDate,
                receivedDate: owed.isPaid ? Date() : nil,
                status: owed.isPaid ? .received : .pending,
                createdAt: Date(),
                updatedAt: nil)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
