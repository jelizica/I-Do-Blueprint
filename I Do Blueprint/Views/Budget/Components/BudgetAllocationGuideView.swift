import SwiftUI

/// Sheet view providing budget allocation guidance and recommendations
struct BudgetAllocationGuideView: View {
    let unallocatedAmount: Double
    let categories: [BudgetCategory]

    @Environment(\.dismiss) private var dismiss

    private var recommendations: [AllocationRecommendation] {
        // Calculate recommendations based on typical wedding budget percentages
        let typicalAllocations: [String: Double] = [
            "Venue": 0.30,
            "Catering": 0.25,
            "Photography": 0.10,
            "Music/Entertainment": 0.08,
            "Flowers": 0.07,
            "Attire": 0.05,
            "Other": 0.15
        ]

        return categories.compactMap { category in
            if let typical = typicalAllocations[category.categoryName] {
                let suggestedAmount = unallocatedAmount * typical
                if suggestedAmount > 10 { // Only suggest if meaningful amount
                    return AllocationRecommendation(
                        categoryName: category.categoryName,
                        currentAllocation: category.allocatedAmount,
                        suggestedAllocation: suggestedAmount,
                        percentage: typical)
                }
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Unallocated amount header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available to Allocate")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: unallocatedAmount)) ?? "$0")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppColors.Budget.allocated)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppColors.Budget.allocated.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Divider()

                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Allocation")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if recommendations.isEmpty {
                            Text("Create budget categories to see allocation recommendations.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(recommendations, id: \.categoryName) { recommendation in
                                RecommendationRow(recommendation: recommendation)
                            }
                        }
                    }

                    Divider()

                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.title3)
                            .fontWeight(.semibold)

                        TipRow(
                            icon: "lightbulb.fill",
                            text: "Allocate 10-15% as a contingency buffer for unexpected expenses.")

                        TipRow(
                            icon: "chart.pie.fill",
                            text: "Review your allocations monthly and adjust as needed based on actual spending.")

                        TipRow(
                            icon: "dollarsign.circle.fill",
                            text: "Prioritize must-have categories before nice-to-have items.")
                    }
                }
                .padding()
            }
            .navigationTitle("Budget Allocation Guide")
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

struct AllocationRecommendation {
    let categoryName: String
    let currentAllocation: Double
    let suggestedAllocation: Double
    let percentage: Double
}

struct RecommendationRow: View {
    let recommendation: AllocationRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.categoryName)
                    .font(.headline)

                Spacer()

                Text("\(Int(recommendation.percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Current:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(NumberFormatter.currencyShort.string(from: NSNumber(value: recommendation.currentAllocation)) ?? "$0")
                    .font(.caption)

                Spacer()

                Text("Suggested:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(NumberFormatter.currencyShort.string(from: NSNumber(value: recommendation.suggestedAllocation)) ?? "$0")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.Budget.allocated)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.Budget.allocated)
                .font(.title3)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

