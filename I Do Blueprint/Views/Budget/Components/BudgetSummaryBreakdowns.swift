// Extracted from BudgetDevelopmentView.swift

import SwiftUI

struct BudgetSummaryBreakdowns: View {
    @Binding var expandedCategories: Set<String>

    let eventBreakdown: [String: Double]
    let categoryBreakdown: [String: (total: Double, subcategories: [String: Double])]
    let categoryItems: [String: [String: [BudgetItem]]] // category -> subcategory -> items
    let personBreakdown: [String: Double]
    let totalWithTax: Double
    let responsibleOptions: [String]
    
    @State private var expandedSubcategories: Set<String> = []

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Event breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Event Breakdown")
                    .font(.headline)

                Text("Costs divided across selected events")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(eventBreakdown.keys.sorted()), id: \.self) { eventName in
                    HStack {
                        Text(eventName)
                            .font(.subheadline)

                        Spacer()

                        Text("$\(String(format: "%.0f", eventBreakdown[eventName] ?? 0))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Category breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Category Totals")
                    .font(.headline)

                Text("Summary by category and subcategory")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(categoryBreakdown.keys.sorted()), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 4) {
                        Button(action: {
                            if expandedCategories.contains(category) {
                                expandedCategories.remove(category)
                            } else {
                                expandedCategories.insert(category)
                            }
                        }) {
                            HStack {
                                Image(systemName: expandedCategories
                                    .contains(category) ? "chevron.down" : "chevron.right")
                                    .font(.caption)

                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                Text("$\(String(format: "%.0f", categoryBreakdown[category]?.total ?? 0))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.plain)

                        if expandedCategories.contains(category),
                           let subcategories = categoryBreakdown[category]?.subcategories {
                            ForEach(Array(subcategories.keys.sorted()), id: \.self) { subcategory in
                                VStack(alignment: .leading, spacing: 2) {
                                    // Subcategory header (clickable to expand/collapse)
                                    Button(action: {
                                        let subcategoryKey = "\(category)_\(subcategory)"
                                        if expandedSubcategories.contains(subcategoryKey) {
                                            expandedSubcategories.remove(subcategoryKey)
                                        } else {
                                            expandedSubcategories.insert(subcategoryKey)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: expandedSubcategories.contains("\(category)_\(subcategory)") ? "chevron.down" : "chevron.right")
                                                .font(.system(size: 8))
                                                .foregroundStyle(.tertiary)
                                            
                                            Text(subcategory)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            
                                            Spacer()
                                            
                                            Text("$\(String(format: "%.0f", subcategories[subcategory] ?? 0))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.leading, Spacing.lg)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(subcategory) subcategory, \(String(format: "%.0f", subcategories[subcategory] ?? 0)) dollars")
                                    .accessibilityHint(expandedSubcategories.contains("\(category)_\(subcategory)") ? "Double tap to collapse items" : "Double tap to expand items")
                                    
                                    // Individual items under this subcategory
                                    if expandedSubcategories.contains("\(category)_\(subcategory)"),
                                       let items = categoryItems[category]?[subcategory] {
                                        ForEach(items, id: \.id) { item in
                                            HStack {
                                                Text("  ◦ \(item.itemName)")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.tertiary)
                                                    .padding(.leading, Spacing.xl)
                                                
                                                Spacer()
                                                
                                                Text("$\(String(format: "%.0f", item.vendorEstimateWithTax))")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.tertiary)
                                            }
                                            .accessibilityElement(children: .combine)
                                            .accessibilityLabel("\(item.itemName), \(String(format: "%.0f", item.vendorEstimateWithTax)) dollars")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Person responsibility breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Responsibility")
                    .font(.headline)

                Text("Budget by person responsible")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(responsibleOptions, id: \.self) { person in
                    let amount = personBreakdown[person] ?? 0
                    let percentage = totalWithTax > 0 ? (amount / totalWithTax) * 100 : 0

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(person)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text(String(format: "$%.0f (%.1f%%)", amount, percentage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: percentage / 100)
                            .progressViewStyle(LinearProgressViewStyle(
                                tint: colorForPerson(person)))
                            .scaleEffect(y: 0.5)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func colorForPerson(_ person: String) -> Color {
        if let idx = responsibleOptions.firstIndex(of: person) {
            switch idx {
            case 0: return .blue
            case 1: return .purple
            default: return .green
            }
        }
        return .green
    }
}
