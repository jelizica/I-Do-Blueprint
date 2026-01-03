import SwiftUI

/// Payment schedule preview panel showing calculated payment schedule
struct PaymentSchedulePreview: View {
    let schedule: [PaymentScheduleItem]
    let totalAmount: Double

    private var totalScheduleAmount: Double {
        schedule.reduce(0) { $0 + $1.amount }
    }

    private var amountDifference: Double {
        totalScheduleAmount - totalAmount
    }

    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            previewContent
        }
        .frame(width: 350)
        .background(Color(NSColor.textBackgroundColor))
    }

    private var previewHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.Budget.allocated)
                Text("Payment Schedule Preview")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Total Amount:")
                    Spacer()
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: totalAmount)) ?? "$0")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Number of Payments:")
                    Spacer()
                    Text("\(schedule.count)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Schedule Total:")
                    Spacer()
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: totalScheduleAmount)) ?? "$0")
                        .fontWeight(.semibold)
                        .foregroundColor(abs(amountDifference) > 0.01 ? AppColors.Budget.overBudget : .primary)
                }

                if abs(amountDifference) > 0.01 {
                    HStack {
                        Text("Difference:")
                        Spacer()
                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: amountDifference)) ?? "$0")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.Budget.overBudget)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(AppColors.Budget.allocated.opacity(0.1))
    }

    private var previewContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if schedule.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(schedule.enumerated()), id: \.element.id) { index, item in
                        PaymentScheduleItemRow(item: item, index: index)
                    }
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.title)
                .foregroundColor(SemanticColors.textSecondary)

            Text("Configure payment details to see schedule")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.huge)
    }
}

/// Individual payment schedule item row
struct PaymentScheduleItemRow: View {
    let item: PaymentScheduleItem
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.description)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(item.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(NumberFormatter.currencyShort.string(from: NSNumber(value: item.amount)) ?? "$0")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    if item.description.contains("Deposit") || item.description.contains("Retainer") {
                        Text(item.description.contains("Retainer") ? "Retainer" : "Deposit")
                            .font(.caption2)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.Budget.allocated.opacity(0.2))
                            .foregroundColor(AppColors.Budget.allocated)
                            .clipShape(Capsule())
                    }

                    if item.description.contains("Final") {
                        Text("Final")
                            .font(.caption2)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.Budget.income.opacity(0.2))
                            .foregroundColor(AppColors.Budget.income)
                            .clipShape(Capsule())
                    }

                    if item.isRecurring {
                        Text("Recurring")
                            .font(.caption2)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.Budget.pending.opacity(0.2))
                            .foregroundColor(AppColors.Budget.pending)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.description.contains("Deposit") || item.description.contains("Retainer") ? AppColors.Budget.allocated
                    .opacity(0.1) :
                    item.description.contains("Final") ? AppColors.Budget.income.opacity(0.1) :
                    Color(NSColor.controlBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    item.description.contains("Deposit") || item.description.contains("Retainer") ? AppColors.Budget.allocated
                        .opacity(0.3) :
                        item.description.contains("Final") ? AppColors.Budget.income.opacity(0.3) :
                        SemanticColors.textSecondary.opacity(Opacity.light),
                    lineWidth: 1))
    }
}

#Preview {
    PaymentSchedulePreview(
        schedule: [
            PaymentScheduleItem(
                id: "1",
                description: "Deposit",
                amount: 500,
                vendorName: "Sample Vendor",
                dueDate: Date(),
                isPaid: false,
                isRecurring: false),
            PaymentScheduleItem(
                id: "2",
                description: "Monthly Payment #1",
                amount: 250,
                vendorName: "Sample Vendor",
                dueDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isPaid: false,
                isRecurring: true)
        ],
        totalAmount: 1000)
}
