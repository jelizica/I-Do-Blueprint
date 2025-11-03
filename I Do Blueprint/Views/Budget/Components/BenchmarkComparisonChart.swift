import Charts
import SwiftUI

/// Bar chart comparing actual budget allocation to industry benchmarks
struct BenchmarkComparisonChart: View {
    let categories: [BudgetCategory]
    let benchmarks: [CategoryBenchmark]

    private var comparisonData: [BenchmarkComparison] {
        categories.compactMap { category in
            guard let benchmark = benchmarks.first(where: { $0.categoryName == category.categoryName }),
                  let summary = getBudgetSummary() else { return nil }

            let actualPercentage = (category.allocatedAmount / summary.totalBudget) * 100
            return BenchmarkComparison(
                categoryName: category.categoryName,
                actualPercentage: actualPercentage,
                typicalPercentage: benchmark.typicalPercentage,
                color: category.color)
        }
    }

    var body: some View {
        if comparisonData.isEmpty {
            ContentUnavailableView(
                "No Benchmark Data",
                systemImage: "chart.bar.xaxis",
                description: Text("Benchmark data will be available once categories are set up"))
        } else {
            Chart {
                ForEach(comparisonData, id: \.categoryName) { data in
                    BarMark(
                        x: .value("Category", data.categoryName),
                        y: .value("Typical", data.typicalPercentage))
                        .foregroundStyle(.gray.opacity(0.5))

                    BarMark(
                        x: .value("Category", data.categoryName),
                        y: .value("Your Budget", data.actualPercentage))
                        .foregroundStyle(Color(hex: data.color) ?? AppColors.Budget.allocated)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let percentage = value.as(Double.self) {
                            Text("\(Int(percentage))%")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }

    private func getBudgetSummary() -> BudgetSummary? {
        // In a real implementation, this would come from the budget store
        // For now, calculate from categories
        let totalBudget = categories.reduce(0) { $0 + $1.allocatedAmount }
        guard totalBudget > 0 else { return nil }

        return BudgetSummary(
            id: UUID(),
            coupleId: UUID(),
            totalBudget: totalBudget,
            baseBudget: totalBudget,
            currency: "USD",
            weddingDate: nil,
            notes: nil,
            includesEngagementRings: false,
            engagementRingAmount: 0.0,
            createdAt: Date(),
            updatedAt: Date())
    }
}

struct BenchmarkComparison {
    let categoryName: String
    let actualPercentage: Double
    let typicalPercentage: Double
    let color: String
}

