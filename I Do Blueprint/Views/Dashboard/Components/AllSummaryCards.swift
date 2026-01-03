//
//  AllSummaryCards.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Combine
import SwiftUI

// MARK: - Guests Summary Card

struct GuestsSummaryCard: View {
    let metrics: GuestMetrics
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "person.3.fill",
            title: "Guests",
            subtitle: "\(metrics.totalGuests) total",
            color: .indigo,
            isHovered: $isHovered) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RSVP'd")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(metrics.rsvpYes)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.Guest.confirmed)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(metrics.rsvpPending)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.Guest.pending)
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SemanticColors.textSecondary.opacity(Opacity.verySubtle)))
            }
        }
    }
}

// MARK: - Vendors Summary Card

struct VendorsSummaryCard: View {
    let metrics: VendorMetrics
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "person.2.fill",
            title: "Vendors",
            subtitle: "\(metrics.totalVendors) total",
            color: .teal,
            isHovered: $isHovered) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickStat(
                    icon: "checkmark.circle.fill",
                    label: "Active",
                    value: "\(metrics.activeContracts)",
                    color: .green)

                QuickStat(
                    icon: "clock.fill",
                    label: "Pending",
                    value: "\(metrics.pendingContracts)",
                    color: .orange)
            }
        }
    }
}

// MARK: - Documents Summary Card

struct DocumentsSummaryCard: View {
    let metrics: DocumentMetrics
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "doc.fill",
            title: "Documents",
            subtitle: "\(metrics.totalDocuments) total",
            color: .cyan,
            isHovered: $isHovered) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickStat(
                    icon: "doc.text.fill",
                    label: "Invoices",
                    value: "\(metrics.invoices)",
                    color: .blue)

                QuickStat(
                    icon: "doc.badge.gearshape",
                    label: "Contracts",
                    value: "\(metrics.contracts)",
                    color: .purple)
            }
        }
    }
}

// MARK: - Budget Summary Card

struct DashboardBudgetSummaryCard: View {
    let metrics: BudgetMetrics
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "dollarsign.circle.fill",
            title: "Budget",
            subtitle: formatCurrency(metrics.totalBudget),
            color: .green,
            isHovered: $isHovered,
            hasAlert: metrics.overBudgetCategories > 0) {
            VStack(spacing: 12) {
                CircularProgress(
                    value: min(metrics.percentageUsed / 100, 1.0),
                    color: metrics.percentageUsed >= 90 ? .red : metrics.percentageUsed >= 75 ? .orange : .green,
                    lineWidth: 12,
                    size: 100,
                    showPercentage: true
                )

                VStack(spacing: 8) {
                    HStack {
                        Text("Spent")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formatCurrency(metrics.spent))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formatCurrency(metrics.remaining))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(metrics.remaining < 0 ? .red : .green)
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SemanticColors.textSecondary.opacity(Opacity.verySubtle)))
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsStore.settings.global.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Gifts Summary Card

struct GiftsSummaryCard: View {
    let metrics: GiftMetrics
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "gift.fill",
            title: "Gifts",
            subtitle: "\(metrics.totalGifts) received",
            color: .pink,
            isHovered: $isHovered,
            hasAlert: metrics.unthankedGifts > 0) {
            VStack(spacing: 12) {
                HStack {
                    Text("Total Value")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatCurrency(metrics.totalValue))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SemanticColors.textSecondary.opacity(Opacity.verySubtle)))

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    QuickStat(
                        icon: "checkmark.circle.fill",
                        label: "Thanked",
                        value: "\(metrics.thankedGifts)",
                        color: .green)

                    QuickStat(
                        icon: "exclamationmark.circle.fill",
                        label: "To Thank",
                        value: "\(metrics.unthankedGifts)",
                        color: .orange)
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsStore.settings.global.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Notes Summary Card

struct NotesSummaryCard: View {
    let metrics: NoteMetrics
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "note.text",
            title: "Notes",
            subtitle: "\(metrics.totalNotes) total",
            color: .yellow,
            isHovered: $isHovered) {
            VStack(spacing: 12) {
                HStack {
                    Text("Recent Notes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(metrics.recentNotes)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SemanticColors.textSecondary.opacity(Opacity.verySubtle)))

                if !metrics.notesByType.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("By Type")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(Array(metrics.notesByType.prefix(3)), id: \.key) { type, count in
                            HStack {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 6, height: 6)

                                Text(type.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.primary)

                                Spacer()

                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
