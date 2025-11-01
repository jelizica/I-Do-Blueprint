//
//  GiftsContributionsSection.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct GiftsContributionsSection: View {
    let totalGifts: Double
    let totalExternal: Double
    let contributions: [ContributionItem]
    let onAddContribution: () -> Void
    let onLinkGifts: () -> Void
    let onEditContribution: (ContributionItem) -> Void
    let onDeleteContribution: (ContributionItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gifts & Contributions")
                .font(.headline)

            // Total Contributions Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Total Contributions")
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gifts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(totalGifts))
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("External")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(totalExternal))
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(totalGifts + totalExternal))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onAddContribution) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(.bordered)

                Button(action: onLinkGifts) {
                    HStack(spacing: 8) {
                        Image(systemName: "link.circle.fill")
                        Text("Link Existing")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(.bordered)
            }

            // Contributions List
            if !contributions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(contributions) { contribution in
                        ContributionRowView(
                            contribution: contribution,
                            onEdit: { onEditContribution(contribution) },
                            onDelete: { onDeleteContribution(contribution) }
                        )
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
