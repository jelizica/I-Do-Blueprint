//
//  StatItem.swift
//  I Do Blueprint
//
//  Model for statistical data display
//

import SwiftUI

/// Model representing a statistical item with icon, label, value, and optional trend
struct StatItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
    let color: Color
    let trend: Trend?
    let accessibilityLabel: String?

    init(
        icon: String,
        label: String,
        value: String,
        color: Color,
        trend: Trend? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.color = color
        self.trend = trend
        self.accessibilityLabel = accessibilityLabel
    }

    /// Trend indicator for statistical changes
    enum Trend {
        case up(String)
        case down(String)
        case neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return SemanticColors.success
            case .down: return SemanticColors.error
            case .neutral: return SemanticColors.textSecondary
            }
        }

        var text: String {
            switch self {
            case .up(let value), .down(let value):
                return value
            case .neutral:
                return "No change"
            }
        }

        var accessibilityDescription: String {
            switch self {
            case .up(let value):
                return "Up \(value)"
            case .down(let value):
                return "Down \(value)"
            case .neutral:
                return "No change"
            }
        }
    }

    /// Computed accessibility label combining all information
    var fullAccessibilityLabel: String {
        let base = accessibilityLabel ?? "\(label): \(value)"
        if let trend = trend {
            return "\(base), \(trend.accessibilityDescription)"
        }
        return base
    }
}

// MARK: - Factory Methods

extension StatItem {
    /// Guest statistics
    static func guestTotal(count: Int) -> StatItem {
        StatItem(
            icon: "person.3.fill",
            label: "Total Guests",
            value: "\(count)",
            color: .blue,
            accessibilityLabel: "Total guests: \(count)"
        )
    }

    static func guestConfirmed(count: Int, total: Int) -> StatItem {
        StatItem(
            icon: "checkmark.circle.fill",
            label: "Confirmed",
            value: "\(count)",
            color: AppColors.Guest.confirmed,
            accessibilityLabel: "Confirmed guests: \(count) out of \(total)"
        )
    }

    static func guestPending(count: Int) -> StatItem {
        StatItem(
            icon: "clock.fill",
            label: "Pending",
            value: "\(count)",
            color: AppColors.Guest.pending,
            accessibilityLabel: "Pending responses: \(count)"
        )
    }

    static func guestDeclined(count: Int) -> StatItem {
        StatItem(
            icon: "xmark.circle.fill",
            label: "Declined",
            value: "\(count)",
            color: AppColors.Guest.declined,
            accessibilityLabel: "Declined guests: \(count)"
        )
    }

    /// Vendor statistics
    static func vendorTotal(count: Int) -> StatItem {
        StatItem(
            icon: "building.2.fill",
            label: "Total Vendors",
            value: "\(count)",
            color: .blue,
            accessibilityLabel: "Total vendors: \(count)"
        )
    }

    static func vendorBooked(count: Int) -> StatItem {
        StatItem(
            icon: "checkmark.seal.fill",
            label: "Booked",
            value: "\(count)",
            color: AppColors.Vendor.booked,
            accessibilityLabel: "Booked vendors: \(count)"
        )
    }

    static func vendorPending(count: Int) -> StatItem {
        StatItem(
            icon: "clock.fill",
            label: "Pending",
            value: "\(count)",
            color: AppColors.Vendor.pending,
            accessibilityLabel: "Pending vendors: \(count)"
        )
    }

    static func vendorContacted(count: Int) -> StatItem {
        StatItem(
            icon: "envelope.fill",
            label: "Contacted",
            value: "\(count)",
            color: AppColors.Vendor.contacted,
            accessibilityLabel: "Contacted vendors: \(count)"
        )
    }

    /// Budget statistics
    static func budgetTotal(amount: Double, currency: String = "$") -> StatItem {
        StatItem(
            icon: "dollarsign.circle.fill",
            label: "Total Budget",
            value: "\(currency)\(String(format: "%.0f", amount))",
            color: AppColors.Budget.allocated,
            accessibilityLabel: "Total budget: \(currency)\(String(format: "%.2f", amount))"
        )
    }

    static func budgetSpent(amount: Double, total: Double, currency: String = "$") -> StatItem {
        let percentage = total > 0 ? (amount / total) * 100 : 0
        return StatItem(
            icon: "creditcard.fill",
            label: "Spent",
            value: "\(currency)\(String(format: "%.0f", amount))",
            color: AppColors.Budget.expense,
            accessibilityLabel: "Spent: \(currency)\(String(format: "%.2f", amount)), \(String(format: "%.1f", percentage))% of budget"
        )
    }

    static func budgetRemaining(amount: Double, currency: String = "$") -> StatItem {
        StatItem(
            icon: "banknote.fill",
            label: "Remaining",
            value: "\(currency)\(String(format: "%.0f", amount))",
            color: amount >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget,
            accessibilityLabel: "Remaining budget: \(currency)\(String(format: "%.2f", amount))"
        )
    }

    /// Task statistics
    static func taskTotal(count: Int) -> StatItem {
        StatItem(
            icon: "list.bullet",
            label: "Total Tasks",
            value: "\(count)",
            color: .blue,
            accessibilityLabel: "Total tasks: \(count)"
        )
    }

    static func taskCompleted(count: Int, total: Int) -> StatItem {
        let percentage = total > 0 ? (Double(count) / Double(total)) * 100 : 0
        return StatItem(
            icon: "checkmark.circle.fill",
            label: "Completed",
            value: "\(count)",
            color: SemanticColors.success,
            accessibilityLabel: "Completed tasks: \(count) out of \(total), \(String(format: "%.0f", percentage))% complete"
        )
    }

    static func taskOverdue(count: Int) -> StatItem {
        StatItem(
            icon: "exclamationmark.triangle.fill",
            label: "Overdue",
            value: "\(count)",
            color: SemanticColors.error,
            accessibilityLabel: "Overdue tasks: \(count)"
        )
    }
}
