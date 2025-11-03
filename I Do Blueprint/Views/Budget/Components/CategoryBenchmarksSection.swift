import SwiftUI

struct CategoryBenchmarkData {
    let category: BudgetCategory
    let spent: Double
    let percentage: Double
    let status: BenchmarkStatus
}

/// Section displaying category performance benchmarks
struct CategoryBenchmarksSection: View {
    let benchmarks: [CategoryBenchmarkData]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Performance vs Budget")
                .font(.headline)
                .fontWeight(.semibold)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(benchmarks, id: \.category.id) { benchmark in
                        CategoryBenchmarkRow(
                            category: benchmark.category,
                            spent: benchmark.spent,
                            percentage: benchmark.percentage,
                            status: benchmark.status)
                    }
                }
            }
            .frame(maxHeight: 300)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct CategoryBenchmarkRow: View {
    let category: BudgetCategory
    let spent: Double
    let percentage: Double
    let status: BenchmarkStatus

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(category.categoryName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                        Text(status.label)
                            .font(.caption)
                            .foregroundColor(status.color)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "$%.2f", spent))
                        .font(.headline)
                    Text(String(format: "of $%.2f", category.allocatedAmount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.textSecondary.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(status.color)
                        .frame(
                            width: min(CGFloat(percentage / 100) * geometry.size.width, geometry.size.width),
                            height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f%% of budget", percentage))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

enum BenchmarkStatus {
    case under, onTrack, over

    var color: Color {
        switch self {
        case .under: AppColors.Budget.underBudget
        case .onTrack: AppColors.Budget.income
        case .over: AppColors.Budget.overBudget
        }
    }

    var icon: String {
        switch self {
        case .under: "arrow.down.circle.fill"
        case .onTrack: "checkmark.circle.fill"
        case .over: "exclamationmark.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .under: "Under Budget"
        case .onTrack: "On Track"
        case .over: "Over Budget"
        }
    }
}
