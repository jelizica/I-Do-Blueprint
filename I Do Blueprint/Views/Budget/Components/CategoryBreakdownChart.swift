import Charts
import SwiftUI

/// Pie chart showing spending breakdown by category
struct CategoryBreakdownChart: View {
    let categories: [BudgetCategory]
    let expenses: [Expense]
    
    @State private var selectedCategory: (category: BudgetCategory, spending: Double)?
    @State private var showTooltip = false
    
    private let logger = AppLogger.ui
    
    private func projectedSpending(for categoryId: UUID) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        let total = categoryExpenses.reduce(0) { $0 + $1.amount }
        
        if total > 0 {
                    }
        
        return total
    }
    
    private var categoriesWithSpending: [(category: BudgetCategory, spending: Double)] {
                if !categories.isEmpty {
                    }
        if !expenses.isEmpty {
                    }
        
        let result = categories.compactMap { category in
            let spending = projectedSpending(for: category.id)
            return spending > 0 ? (category: category, spending: spending) : nil
        }
        
                return result
    }
    
    private var totalSpending: Double {
        categoriesWithSpending.reduce(0) { $0 + $1.spending }
    }
    
    private func categoryAtLocation(
        _ location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy) -> (category: BudgetCategory, spending: Double)? {
        // Convert location to chart coordinate space
        guard let plotFrame = proxy.plotFrame else { return nil }
        let plotRect = geometry[plotFrame]
        let center = CGPoint(
            x: plotRect.midX,
            y: plotRect.midY)
        
        // Calculate angle from center
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        let angle = atan2(deltaY, deltaX)
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        let angleDegrees = normalizedAngle * 180 / .pi
        
        // Find which category this angle corresponds to
        var currentAngle: Double = -90 // Start from top (12 o'clock position)
        for item in categoriesWithSpending {
            let itemAngle = (item.spending / totalSpending) * 360
            let startAngle = currentAngle
            let endAngle = currentAngle + itemAngle
            
            // Normalize angles for comparison
            let normalizedClickAngle = angleDegrees >= 270 ? angleDegrees - 360 : angleDegrees
            let normalizedStartAngle = startAngle >= 270 ? startAngle - 360 : startAngle
            let normalizedEndAngle = endAngle >= 270 ? endAngle - 360 : endAngle
            
            if normalizedClickAngle >= normalizedStartAngle, normalizedClickAngle < normalizedEndAngle {
                return item
            }
            currentAngle += itemAngle
        }
        
        return nil
    }
    
    var body: some View {
        if categoriesWithSpending.isEmpty {
            ContentUnavailableView(
                "No Budget Data",
                systemImage: "chart.pie",
                description: Text("Add expenses to see category breakdown"))
        } else {
            ZStack {
                Chart(categoriesWithSpending, id: \.category.id) { item in
                    SectorMark(
                        angle: .value("Projected Spending", item.spending),
                        innerRadius: .ratio(0.5),
                        angularInset: 1)
                        .foregroundStyle(Color(hex: item.category.color) ?? AppColors.Budget.allocated)
                        .opacity(selectedCategory?.category.id == item.category.id ? 1.0 : 0.8)
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if let tappedCategory = categoryAtLocation(
                                        location,
                                        proxy: proxy,
                                        geometry: geometry) {
                                        if selectedCategory?.category.id == tappedCategory.category.id {
                                            // Deselect if same category is tapped
                                            selectedCategory = nil
                                            showTooltip = false
                                        } else {
                                            // Select new category
                                            selectedCategory = tappedCategory
                                            showTooltip = true
                                        }
                                    } else {
                                        // Deselect if tapped outside
                                        selectedCategory = nil
                                        showTooltip = false
                                    }
                                }
                            }
                    }
                }
                
                // Tap tooltip
                if let selectedItem = selectedCategory, showTooltip {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: selectedItem.category.color) ?? AppColors.Budget.allocated)
                                .frame(width: 12, height: 12)
                            Text(selectedItem.category.categoryName)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text(
                            "Projected Spending: \(NumberFormatter.currency.string(from: NSNumber(value: selectedItem.spending)) ?? "$0")")
                            .font(.subheadline)
                        
                        Text(
                            "Allocated: \(NumberFormatter.currency.string(from: NSNumber(value: selectedItem.category.allocatedAmount)) ?? "$0")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        let percentage = totalSpending > 0 ? (selectedItem.spending / totalSpending) * 100 : 0
                        Text("Share: \(String(format: "%.1f", percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if selectedItem.spending > selectedItem.category.allocatedAmount {
                            Text("Over Budget")
                                .font(.caption)
                                .foregroundColor(AppColors.Budget.overBudget)
                                .fontWeight(.medium)
                        }
                        
                        Text("Tap to dismiss")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .chartLegend(position: .bottom, alignment: .center) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(categoriesWithSpending, id: \.category.id) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: item.category.color) ?? AppColors.Budget.allocated)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category.categoryName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(NumberFormatter.currency.string(from: NSNumber(value: item.spending)) ?? "$0")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .opacity(selectedCategory?.category.id == item.category.id ? 1.0 : 0.7)
                        .scaleEffect(selectedCategory?.category.id == item.category.id ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedCategory?.category.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedCategory?.category.id == item.category.id {
                                    selectedCategory = nil
                                    showTooltip = false
                                } else {
                                    selectedCategory = item
                                    showTooltip = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

