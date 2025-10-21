import SwiftUI

/// Filter bar for expense tracker with search, status, category, and view mode controls
struct ExpenseFiltersBar: View {
    @Binding var searchText: String
    @Binding var selectedFilterStatus: PaymentStatus?
    @Binding var selectedCategoryFilter: UUID?
    @Binding var viewMode: ExpenseViewMode
    @Binding var showBenchmarks: Bool
    
    let categories: [BudgetCategory]
    
    var body: some View {
        HStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search expenses...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            // Status Filter
            Picker("Status", selection: $selectedFilterStatus) {
                Text("All Status").tag(nil as PaymentStatus?)
                Text("Pending").tag(PaymentStatus.pending as PaymentStatus?)
                Text("Paid").tag(PaymentStatus.paid as PaymentStatus?)
                Text("Partial").tag(PaymentStatus.partial as PaymentStatus?)
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 150)
            
            // Category Filter
            Picker("Category", selection: $selectedCategoryFilter) {
                Text("All Categories").tag(nil as UUID?)
                ForEach(categories) { category in
                    Text(category.categoryName).tag(category.id as UUID?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 200)
            
            Spacer()
            
            // View Mode Toggle
            ExpenseViewModeToggle(viewMode: $viewMode)
            
            // Toggle Benchmarks
            Button(action: { withAnimation { showBenchmarks.toggle() } }) {
                HStack {
                    Image(systemName: showBenchmarks ? "chevron.up" : "chevron.down")
                    Text("Benchmarks")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

enum ExpenseViewMode {
    case cards, list
    
    var icon: String {
        switch self {
        case .cards: "rectangle.grid.2x2"
        case .list: "list.bullet"
        }
    }
    
    var title: String {
        switch self {
        case .cards: "Card View"
        case .list: "List View"
        }
    }
}

struct ExpenseViewModeToggle: View {
    @Binding var viewMode: ExpenseViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([ExpenseViewMode.cards, ExpenseViewMode.list], id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(mode == .cards ? "Cards" : "List")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewMode == mode ? AppColors.Budget.allocated : Color(NSColor.controlBackgroundColor))
                    .foregroundColor(viewMode == mode ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}
