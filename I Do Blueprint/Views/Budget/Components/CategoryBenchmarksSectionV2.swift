//
//  CategoryBenchmarksSectionV2.swift
//  I Do Blueprint
//
//  Collapsible category benchmarks section for Expense Tracker
//  NO horizontal scrolling - uses chevron-based collapse/expand
//

import SwiftUI

struct CategoryBenchmarksSectionV2: View {
    let benchmarks: [CategoryBenchmarkData]
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with chevron toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Category Benchmarks")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.lg)
                .background(AppColors.cardBackground)
                .cornerRadius(isExpanded ? CornerRadius.lg : CornerRadius.lg)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(spacing: Spacing.sm) {
                    ForEach(benchmarks, id: \.category.id) { benchmark in
                        CategoryBenchmarkRowV2(
                            category: benchmark.category,
                            spent: benchmark.spent,
                            percentage: benchmark.percentage,
                            status: benchmark.status)
                    }
                }
                .padding(Spacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(CornerRadius.lg)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct CategoryBenchmarkRowV2: View {
    let category: BudgetCategory
    let spent: Double
    let percentage: Double
    let status: BenchmarkStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category name and status
            HStack {
                Text(category.categoryName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: status.icon)
                        .font(.caption2)
                    Text(status.label)
                        .font(.caption)
                }
                .foregroundColor(status.color)
            }
            
            // Amount spent vs budgeted
            HStack {
                Text(String(format: "$%.0f / $%.0f", spent, category.allocatedAmount))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.0f%%", percentage))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(status.color)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.textSecondary.opacity(0.15))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(status.color)
                        .frame(
                            width: min(CGFloat(percentage / 100) * geometry.size.width, geometry.size.width),
                            height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

