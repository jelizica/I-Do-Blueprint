//
//  ExpenseTrackerStaticHeader.swift
//  I Do Blueprint
//
//  Static header for Expense Tracker with wedding countdown and budget health dashboard
//  Based on LLM Council recommendation (see: docs/LLM_COUNCIL_EXPENSE_TRACKER_HEADER_DESIGN.md)
//
//  Design: Two-row layout with enhanced visual styling
//  - Row 1: Wedding countdown + Quick actions (Add Expense, Export)
//  - Row 2: Budget health dashboard (spent/budget, status, overdue, pending, per-guest)
//

import SwiftUI

struct ExpenseTrackerStaticHeader: View {
    let windowSize: WindowSize
    let totalSpent: Double
    let totalBudget: Double
    let pendingAmount: Double
    let overdueCount: Int
    let guestCount: Int
    let daysUntilWedding: Int?
    let onAddExpense: () -> Void
    let onOverdueClick: () -> Void
    
    @Binding var guestCountMode: GuestCountMode
    
    // MARK: - Guest Count Mode
    
    enum GuestCountMode: String, CaseIterable, Identifiable {
        case total = "Total"
        case attending = "Attending"
        case confirmed = "Confirmed"
        
        var id: String { rawValue }
    }
    
    // MARK: - Computed Properties
    
    /// Budget health status based on spent percentage with 5% wiggle room
    private var budgetHealthStatus: BudgetHealthStatus {
        guard totalBudget > 0 else { return .onTrack }
        let percentage = (totalSpent / totalBudget) * 100
        
        if percentage < 95 {
            return .onTrack
        } else if percentage <= 105 {
            return .caution
        } else {
            return .overBudget
        }
    }
    
    /// Percentage of budget spent (capped at 100% for progress bar)
    private var spentPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return min((totalSpent / totalBudget) * 100, 100)
    }
    
    /// Cost per guest
    private var perGuestCost: Double {
        guard guestCount > 0 else { return 0 }
        return totalSpent / Double(guestCount)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Wedding countdown + Actions (hidden in compact)
            if windowSize != .compact {
                row1ContextAndActions
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
            }
            
            // Row 2: Budget health dashboard
            row2HealthDashboard
                .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
                .padding(.vertical, windowSize == .compact ? Spacing.md : Spacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    budgetHealthStatus.color.opacity(0.03),
                                    budgetHealthStatus.color.opacity(0.01)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(budgetHealthStatus.color.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(
            color: budgetHealthStatus.color.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Row 1: Context + Actions
    
    private var row1ContextAndActions: some View {
        HStack(alignment: .center) {
            // Left: Wedding countdown with enhanced styling
            weddingCountdownSection
            
            Spacer()
            
            // Right: Quick actions
            quickActionsSection
        }
    }
    
    private var weddingCountdownSection: some View {
        Group {
            if let days = daysUntilWedding {
                HStack(spacing: 10) {
                    // Enhanced icon with background
                    ZStack {
                        Circle()
                            .fill(SemanticColors.primaryAction.opacity(Opacity.light))
                            .frame(width: 36, height: 36)

                        Image(systemName: "heart.circle.fill")
                            .foregroundColor(SemanticColors.primaryAction)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weddingCountdownText(days: days))
                            .font(.headline)
                            .foregroundColor(SemanticColors.textPrimary)

                        if days > 0 {
                            Text("until your big day")
                                .font(.caption)
                                .foregroundColor(SemanticColors.textSecondary)
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(SemanticColors.statusWarning.opacity(Opacity.light))
                            .frame(width: 36, height: 36)

                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(SemanticColors.statusWarning)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text("Wedding Date Not Set")
                        .font(.subheadline)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: Spacing.sm) {
            // Add Expense button (primary action)
            Button(action: onAddExpense) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Expense")
                }
                .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .help("Add a new expense")
            
            // Export button (placeholder)
            Button(action: {
                AppLogger.ui.info("Export - Not yet implemented (see beads issue I Do Blueprint-a9yn)")
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help("Export expenses (coming soon)")
        }
    }
    
    // MARK: - Row 2: Budget Health Dashboard
    
    @ViewBuilder
    private var row2HealthDashboard: some View {
        if windowSize == .compact {
            compactHealthDashboard
        } else {
            regularHealthDashboard
        }
    }
    
    // MARK: - Regular Health Dashboard
    
    private var regularHealthDashboard: some View {
        HStack(spacing: 0) {
            // Spent/Budget with progress bar - takes more space
            spentBudgetSection
                .frame(maxWidth: 280)
            
            // Vertical divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 50)
                .padding(.horizontal, Spacing.lg)
            
            // Status indicator
            statusIndicatorSection
            
            // Overdue badge (only show if there are overdue items)
            if overdueCount > 0 {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                    .padding(.horizontal, Spacing.lg)
                
                overdueBadgeSection
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 50)
                .padding(.horizontal, Spacing.lg)
            
            // Pending amount
            pendingAmountSection
            
            // Per-guest cost (only show if guests exist)
            if guestCount > 0 {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                    .padding(.horizontal, Spacing.lg)
                
                perGuestCostSection
            }
            
            Spacer()
        }
    }
    
    private var spentBudgetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Spent / Budget amounts with enhanced typography
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formatCurrency(totalSpent))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("/")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)

                Text(formatCurrency(totalBudget))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            // Enhanced progress bar
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 10)
                
                // Progress fill with gradient
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    budgetHealthStatus.color,
                                    budgetHealthStatus.color.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (spentPercentage / 100))
                        .animation(.easeInOut(duration: 0.5), value: spentPercentage)
                }
                .frame(height: 10)
            }
            
            // Percentage text
            Text("\(Int(spentPercentage))% of budget spent")
                .font(.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }
    
    private var statusIndicatorSection: some View {
        VStack(spacing: 6) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(budgetHealthStatus.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: budgetHealthStatus.icon)
                    .foregroundColor(budgetHealthStatus.color)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text(budgetHealthStatus.label)
                .font(.caption.weight(.medium))
                .foregroundColor(budgetHealthStatus.color)
        }
        .help(budgetHealthStatus.helpText)
    }
    
    private var overdueBadgeSection: some View {
        Button(action: onOverdueClick) {
            VStack(spacing: 6) {
                // Badge with count
                ZStack {
                    Circle()
                        .fill(SemanticColors.statusWarning)
                        .frame(width: 32, height: 32)

                    Text("\(overdueCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("overdue")
                    .font(.caption.weight(.medium))
                    .foregroundColor(SemanticColors.statusWarning)
            }
        }
        .buttonStyle(.plain)
        .help("Click to filter overdue expenses")
    }
    
    private var pendingAmountSection: some View {
        VStack(spacing: 6) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(SemanticColors.statusPending.opacity(Opacity.light))
                    .frame(width: 32, height: 32)

                Image(systemName: "clock.fill")
                    .foregroundColor(SemanticColors.statusPending)
                    .font(.system(size: 14, weight: .medium))
            }

            Text(formatCurrencyCompact(pendingAmount))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(SemanticColors.textPrimary)

            Text("pending")
                .font(.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }
    
    private var perGuestCostSection: some View {
        VStack(spacing: 6) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(SemanticColors.primaryAction.opacity(Opacity.light))
                    .frame(width: 32, height: 32)

                Image(systemName: "person.2.fill")
                    .foregroundColor(SemanticColors.primaryAction)
                    .font(.system(size: 12, weight: .medium))
            }

            Text(formatCurrencyCompact(perGuestCost))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(SemanticColors.textPrimary)
            
            // Guest count mode toggle
            guestCountToggle
        }
    }
    
    private var guestCountToggle: some View {
        Menu {
            ForEach(GuestCountMode.allCases) { mode in
                Button {
                    guestCountMode = mode
                } label: {
                    HStack {
                        Text(mode.rawValue)
                        if guestCountMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text("/\(guestCountMode.rawValue.lowercased())")
                    .font(.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .help("Toggle guest count mode")
    }
    
    // MARK: - Compact Health Dashboard
    
    private var compactHealthDashboard: some View {
        VStack(spacing: Spacing.sm) {
            // Top row: Most critical info
            HStack(spacing: Spacing.md) {
                // Wedding countdown (compact)
                if let days = daysUntilWedding {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(SemanticColors.primaryAction)
                        Text("\(days)d")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                
                // Spent/Budget (abbreviated)
                HStack(spacing: 4) {
                    Text(formatCurrencyCompact(totalSpent))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("/")
                        .font(.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(formatCurrencyCompact(totalBudget))
                        .font(.caption.weight(.medium))
                        .foregroundColor(SemanticColors.textSecondary)
                }
                
                // Progress percentage with color
                Text("\(Int(spentPercentage))%")
                    .font(.caption.weight(.bold))
                    .foregroundColor(budgetHealthStatus.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(budgetHealthStatus.color.opacity(0.15))
                    .cornerRadius(4)
                
                // Overdue badge (compact)
                if overdueCount > 0 {
                    Button(action: onOverdueClick) {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("\(overdueCount)")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Add button (compact)
                Button(action: onAddExpense) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            
            // Progress bar (compact)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 8)
                
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    budgetHealthStatus.color,
                                    budgetHealthStatus.color.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (spentPercentage / 100))
                        .animation(.easeInOut(duration: 0.5), value: spentPercentage)
                }
                .frame(height: 8)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func weddingCountdownText(days: Int) -> String {
        if days < 0 {
            return "Wedding Day Passed"
        } else if days == 0 {
            return "Wedding Day! 🎉"
        } else if days == 1 {
            return "Tomorrow!"
        } else {
            return "\(days) days"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatCurrencyCompact(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.1fK", value / 1000)
        } else {
            return formatCurrency(value)
        }
    }
}

// MARK: - Budget Health Status

enum BudgetHealthStatus {
    case onTrack    // Green - <95% spent
    case caution    // Yellow - 95-105% spent (5% wiggle room)
    case overBudget // Red - >105% spent
    
    var color: Color {
        switch self {
        case .onTrack: return SemanticColors.statusSuccess
        case .caution: return SemanticColors.statusPending
        case .overBudget: return SemanticColors.statusWarning
        }
    }
    
    var label: String {
        switch self {
        case .onTrack: return "On Track"
        case .caution: return "Attention"
        case .overBudget: return "Over Budget"
        }
    }
    
    var icon: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .overBudget: return "xmark.circle.fill"
        }
    }
    
    var helpText: String {
        switch self {
        case .onTrack: return "You're on track with your budget (under 95% spent)"
        case .caution: return "You're approaching your budget limit (95-105% spent)"
        case .overBudget: return "You've exceeded your budget (over 105% spent)"
        }
    }
}
