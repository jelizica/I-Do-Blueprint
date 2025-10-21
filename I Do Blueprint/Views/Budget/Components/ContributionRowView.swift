//
//  ContributionRowView.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct ContributionRowView: View {
    let contribution: ContributionItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: contribution.contributionType == .gift ? "gift.fill" : "dollarsign.circle.fill")
                .foregroundStyle(contribution.contributionType == .gift ? AppColors.Budget.income : AppColors.Budget.allocated)

            VStack(alignment: .leading, spacing: 4) {
                Text(contribution.contributorName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let notes = contribution.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(formatCurrency(contribution.amount))
                .font(.subheadline)
                .fontWeight(.semibold)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(AppColors.Budget.allocated)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(AppColors.Budget.overBudget)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
