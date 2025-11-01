//
//  DashboardGridLayout.swift
//  My Wedding Planning App
//
//  Bento grid layout component for dashboard cards
//  Created by Claude Code on 1/9/25.
//

import SwiftUI

struct DashboardGridLayout: View {
    let summary: DashboardSummary?
    let weddingDate: Date?
    let daysUntilWedding: Int

    var body: some View {
        VStack(spacing: 4) {
            heroMetricsRow
            statsAndCountdownRow
            visualizationRow
        }
    }

    // MARK: - Row 1: Hero Metrics

    private var heroMetricsRow: some View {
        HStack(spacing: 4) {
            // Budget percentage - Large
            if let budgetMetrics = summary?.budget {
                HeroMetricCard(
                    value: "\(budgetMetrics.percentageUsed)%",
                    subtitle: "Budget Spent",
                    detail: "$\(Int(budgetMetrics.spent)) of $\(Int(budgetMetrics.totalBudget))",
                    backgroundColor: AppColors.Dashboard.budgetCard,
                    foregroundColor: .black)
                .accessibilityLabel("Budget Summary")
                .accessibilityValue("Spent \(budgetMetrics.percentageUsed)% of total budget")
            }

            // RSVP Rate - Large
            if let guestMetrics = summary?.guests {
                let rsvpRate = guestMetrics.totalGuests > 0 ?
                    Double(guestMetrics.rsvpYes + guestMetrics.rsvpNo) / Double(guestMetrics.totalGuests) * 100 : 0
                HeroMetricCard(
                    value: String(format: "%.1f%%", rsvpRate),
                    subtitle: "RSVP Response Rate",
                    detail: "\(guestMetrics.rsvpYes) attending",
                    backgroundColor: AppColors.Dashboard.rsvpCard,
                    foregroundColor: .white)
                .accessibilityLabel("RSVP Response Rate")
                .accessibilityValue("\(Int(rsvpRate))% of guests have responded")
            }
        }
        .frame(height: 280)
    }

    // MARK: - Row 2: Stats and Countdown

    private var statsAndCountdownRow: some View {
        HStack(spacing: 4) {
            VStack(spacing: 4) {
                // Vendors - Small
                if let vendorMetrics = summary?.vendors {
                    CompactSummaryCard(
                        title: "Vendors Booked",
                        value: "\(vendorMetrics.totalVendors)",
                        icon: "briefcase.fill",
                        color: AppColors.Dashboard.vendorCard
                    )
                }

                // Guests - Small
                if let guestMetrics = summary?.guests {
                    CompactSummaryCard(
                        title: "Total Guests",
                        value: "\(guestMetrics.totalGuests)",
                        icon: "person.3.fill",
                        color: AppColors.Dashboard.guestCard
                    )
                }
            }

            // Days until wedding - Large
            if let weddingDate = weddingDate {
                LargeCountdownCard(
                    daysRemaining: daysUntilWedding,
                    weddingDate: weddingDate,
                    backgroundColor: AppColors.Dashboard.countdownCard,
                    foregroundColor: .white)
                .accessibilityLabel("Wedding Countdown")
                .accessibilityValue("\(daysUntilWedding) days until wedding")
            }
        }
        .frame(height: 260)
    }

    // MARK: - Row 3: Visualizations

    private var visualizationRow: some View {
        HStack(spacing: 4) {
            // Budget breakdown - Wide
            if let budgetMetrics = summary?.budget {
                BudgetVisualizationCard(
                    totalBudget: budgetMetrics.totalBudget,
                    spent: budgetMetrics.spent,
                    remaining: budgetMetrics.remaining,
                    backgroundColor: AppColors.Dashboard.budgetVisualizationCard,
                    foregroundColor: .black)
                .accessibilityLabel("Budget Breakdown")
                .accessibilityValue("Spent $\(Int(budgetMetrics.spent)), remaining $\(Int(budgetMetrics.remaining))")
            }

            // Task completion - Medium
            if let taskMetrics = summary?.tasks {
                let completionRate = taskMetrics.total > 0 ?
                    Double(taskMetrics.completed) / Double(taskMetrics.total) * 100 : 0
                DashboardProgressCard(
                    value: "\(taskMetrics.completed)/\(taskMetrics.total)",
                    percentage: completionRate,
                    label: "Tasks Complete",
                    backgroundColor: AppColors.Dashboard.taskProgressCard,
                    foregroundColor: .white)
            }
        }
        .frame(height: 240)
    }
}

// MARK: - Preview

#Preview {
    DashboardGridLayout(
        summary: DashboardSummary(
            tasks: TaskMetrics(
                total: 50,
                completed: 30,
                inProgress: 10,
                notStarted: 10,
                onHold: 0,
                cancelled: 0,
                overdue: 5,
                dueThisWeek: 8,
                highPriority: 12,
                urgent: 3,
                completionRate: 60.0,
                recentTasks: []
            ),
            payments: PaymentMetrics(
                totalPayments: 20,
                paidPayments: 15,
                unpaidPayments: 5,
                overduePayments: 1,
                upcomingPayments: 4,
                totalAmount: 45000,
                paidAmount: 30000,
                unpaidAmount: 15000,
                overdueAmount: 2000,
                recentPayments: []
            ),
            reminders: ReminderMetrics(
                total: 25,
                active: 15,
                completed: 10,
                overdue: 2,
                dueToday: 3,
                dueThisWeek: 7,
                recentReminders: []
            ),
            timeline: TimelineMetrics(
                totalItems: 30,
                completedItems: 18,
                upcomingItems: 12,
                overdueItems: 2,
                milestones: 8,
                completedMilestones: 5,
                recentItems: []
            ),
            guests: GuestMetrics(
                totalGuests: 150,
                rsvpYes: 90,
                rsvpNo: 10,
                rsvpPending: 50,
                attended: 0,
                mealSelections: [:],
                recentRsvps: []
            ),
            vendors: VendorMetrics(
                totalVendors: 12,
                activeContracts: 8,
                pendingContracts: 4,
                completedServices: 2,
                totalSpent: 25000,
                recentVendors: []
            ),
            documents: DocumentMetrics(
                totalDocuments: 45,
                invoices: 20,
                contracts: 15,
                other: 10,
                recentDocuments: []
            ),
            budget: BudgetMetrics(
                totalBudget: 50000,
                spent: 25000,
                remaining: 25000,
                percentageUsed: 50,
                categories: 10,
                overBudgetCategories: 2,
                recentExpenses: []
            ),
            gifts: GiftMetrics(
                totalGifts: 30,
                totalValue: 5000,
                thankedGifts: 20,
                unthankedGifts: 10,
                recentGifts: []
            ),
            notes: NoteMetrics(
                totalNotes: 50,
                recentNotes: 10,
                notesByType: [:],
                recentNotesList: []
            )
        ),
        weddingDate: Date().addingTimeInterval(180 * 24 * 60 * 60),
        daysUntilWedding: 180
    )
    .padding()
    .background(AppColors.textPrimary)
    .frame(width: 1400)
}
