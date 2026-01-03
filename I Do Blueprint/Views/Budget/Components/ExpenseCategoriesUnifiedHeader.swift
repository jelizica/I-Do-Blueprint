//
//  ExpenseCategoriesUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified responsive header for Expense Categories
//  Follows pattern from ExpenseTrackerUnifiedHeader and PaymentScheduleUnifiedHeader
//

import SwiftUI

struct ExpenseCategoriesUnifiedHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage
    let onExpandAll: () -> Void
    let onCollapseAll: () -> Void
    let onExport: () -> Void
    let onImport: () -> Void
    
    // Dual initializer pattern for navigation binding
    init(
        windowSize: WindowSize,
        currentPage: Binding<BudgetPage>,
        onExpandAll: @escaping () -> Void,
        onCollapseAll: @escaping () -> Void,
        onExport: @escaping () -> Void,
        onImport: @escaping () -> Void
    ) {
        self.windowSize = windowSize
        self._currentPage = currentPage
        self.onExpandAll = onExpandAll
        self.onCollapseAll = onCollapseAll
        self.onExport = onExport
        self.onImport = onImport
    }
    
    // Standalone initializer (for when used outside hub navigation)
    init(
        windowSize: WindowSize,
        onExpandAll: @escaping () -> Void,
        onCollapseAll: @escaping () -> Void,
        onExport: @escaping () -> Void,
        onImport: @escaping () -> Void
    ) {
        self.windowSize = windowSize
        self._currentPage = .constant(.expenseCategories)
        self.onExpandAll = onExpandAll
        self.onCollapseAll = onCollapseAll
        self.onExport = onExport
        self.onImport = onImport
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title row with ellipsis menu and navigation
            titleRow
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Title Row
    
    private var titleRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget")
                    .font(Typography.displaySmall)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("Expense Categories")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                ellipsisMenu
                budgetPageDropdown
            }
        }
        .frame(height: 68)  // Fixed height for consistency
    }
    
    // MARK: - Ellipsis Menu
    
    private var ellipsisMenu: some View {
        Menu {
            Button(action: onExport) {
                Label("Export Categories", systemImage: "square.and.arrow.up")
            }
            
            Button(action: onImport) {
                Label("Import Categories", systemImage: "square.and.arrow.down")
            }
            
            Divider()
            
            Button(action: onExpandAll) {
                Label("Expand All", systemImage: "chevron.down.circle")
            }
            
            Button(action: onCollapseAll) {
                Label("Collapse All", systemImage: "chevron.up.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(SemanticColors.textPrimary)
        }
        .buttonStyle(.plain)
        .help("More actions")
    }
    
    // MARK: - Navigation Dropdown
    
    private var budgetPageDropdown: some View {
        Menu {
            Button {
                currentPage = .hub
            } label: {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
                if currentPage == .hub {
                    Image(systemName: "checkmark")
                }
            }
            .keyboardShortcut("1", modifiers: [.command])
            
            Divider()
            
            ForEach(BudgetGroup.allCases) { group in
                Section(group.rawValue) {
                    ForEach(group.pages) { page in
                        Button {
                            currentPage = page
                        } label: {
                            Label(page.rawValue, systemImage: page.icon)
                            if currentPage == page {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: currentPage.icon)
                    .font(.system(size: windowSize == .compact ? 20 : 16))
                if windowSize != .compact {
                    Text(currentPage.rawValue)
                        .font(.headline)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(SemanticColors.textPrimary)
            .frame(width: windowSize == .compact ? 44 : nil, height: 44)
        }
        .buttonStyle(.plain)
        .help("Navigate budget pages")
    }
}

// MARK: - Preview

#Preview("Regular") {
    ExpenseCategoriesUnifiedHeader(
        windowSize: .regular,
        currentPage: .constant(.expenseCategories),
        onExpandAll: { print("Expand all") },
        onCollapseAll: { print("Collapse all") },
        onExport: { print("Export") },
        onImport: { print("Import") }
    )
    .frame(width: 900)
}

#Preview("Compact") {
    ExpenseCategoriesUnifiedHeader(
        windowSize: .compact,
        currentPage: .constant(.expenseCategories),
        onExpandAll: { print("Expand all") },
        onCollapseAll: { print("Collapse all") },
        onExport: { print("Export") },
        onImport: { print("Import") }
    )
    .frame(width: 640)
}
