import SwiftUI

/// Sheet view displaying a list of budget categories
struct BudgetCategoriesListView: View {
    let categories: [BudgetCategory]
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.categoryName)
                                .font(.headline)

                            Spacer()

                            if category.isOverBudget {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppColors.Budget.pending)
                            }
                        }

                        HStack {
                            Text("Allocated:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(NumberFormatter.currency.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")
                                .font(.caption)
                                .fontWeight(.medium)

                            Spacer()

                            Text("Spent:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(NumberFormatter.currency.string(from: NSNumber(value: category.spentAmount)) ?? "$0")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(category.isOverBudget ? AppColors.Budget.overBudget : .primary)
                        }

                        if category.isOverBudget {
                            let overAmount = category.spentAmount - category.allocatedAmount
                            Text("Over by: \(NumberFormatter.currency.string(from: NSNumber(value: overAmount)) ?? "$0")")
                                .font(.caption)
                                .foregroundColor(AppColors.Budget.overBudget)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

