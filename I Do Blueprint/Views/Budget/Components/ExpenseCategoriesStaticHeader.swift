//
//  ExpenseCategoriesStaticHeader.swift
//  I Do Blueprint
//
//  Static header for Expense Categories with search, hierarchy counts, and over-budget alert
//  Based on LLM Council decision: Search + Hierarchy Counts + Clickable Over-Budget Alert + Add Button
//  (see: knowledge-repo-bm/architecture/decisions/LLM Council Deliberation - Expense Categories Static Header Design.md)
//

import SwiftUI

struct ExpenseCategoriesStaticHeader: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var showOnlyOverBudget: Bool
    
    let parentCount: Int
    let subcategoryCount: Int
    let overBudgetCount: Int
    
    let onAddCategory: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(spacing: Spacing.sm) {
            // Row 1: Search bar (full-width)
            searchField
            
            // Row 2: Hierarchy counts + Over-budget alert/success + Add button
            HStack(spacing: Spacing.sm) {
                hierarchyCountsCompact
                
                Spacer()
                
                // Status indicator (left of Add button, same size)
                if overBudgetCount > 0 {
                    overBudgetBadgeCompact
                } else {
                    successIndicatorCompact
                }
                
                addButton
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.lg) {
            // Search bar (left, max-width 320px)
            searchField
                .frame(maxWidth: 320)
            
            // Hierarchy counts (center-left)
            hierarchyCounts
            
            Spacer()
            
            // Over-budget alert or success message (center-right)
            if overBudgetCount > 0 {
                overBudgetBadge
            } else {
                successIndicator
            }
            
            // Add button (right)
            addButton
        }
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(.system(size: 14))
            
            TextField("Search categories...", text: $searchText)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Hierarchy Counts (Regular)
    
    private var hierarchyCounts: some View {
        HStack(spacing: Spacing.sm) {
            // Parent count
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                Text("\(parentCount)")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Parents")
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text("•")
                .foregroundColor(AppColors.textSecondary)
                .font(Typography.bodySmall)
            
            // Subcategory count
            HStack(spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("\(subcategoryCount)")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Subcategories")
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Hierarchy Counts (Compact)
    
    private var hierarchyCountsCompact: some View {
        HStack(spacing: 6) {
            // Parent count
            HStack(spacing: 3) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.purple)
                Text("\(parentCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("•")
                .foregroundColor(AppColors.textSecondary)
                .font(.system(size: 12))
            
            // Subcategory count
            HStack(spacing: 3) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                Text("\(subcategoryCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
    
    // MARK: - Over Budget Badge
    
    private var overBudgetBadge: some View {
        Button {
            showOnlyOverBudget.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text("\(overBudgetCount) over budget")
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(AppColors.Budget.overBudget)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.Budget.overBudget.opacity(showOnlyOverBudget ? 0.2 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.Budget.overBudget, lineWidth: showOnlyOverBudget ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .help(showOnlyOverBudget ? "Click to show all categories" : "Click to filter to over-budget categories")
    }
    
    // MARK: - Success Indicator
    
    private var successIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
            Text("All on track")
                .font(.caption.weight(.medium))
        }
        .foregroundColor(AppColors.Budget.underBudget)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.Budget.underBudget.opacity(0.1))
        )
    }
    
    // MARK: - Success Indicator (Compact) - Circle badge (non-clickable)
    
    private var successIndicatorCompact: some View {
        ZStack {
            Circle()
                .fill(AppColors.Budget.underBudget)
                .frame(width: 32, height: 32)
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Over Budget Badge (Compact) - Same size as Add button
    
    private var overBudgetBadgeCompact: some View {
        Button {
            showOnlyOverBudget.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(overBudgetCount)")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.Budget.overBudget.opacity(showOnlyOverBudget ? 1.0 : 0.8))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(showOnlyOverBudget ? 0.5 : 0), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .help(showOnlyOverBudget ? "Click to show all categories" : "Click to filter to over-budget categories")
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button(action: onAddCategory) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                if windowSize != .compact {
                    Text("Add")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, windowSize == .compact ? 10 : 12)
            .padding(.vertical, 6)
            .background(AppColors.primary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help("Add new category (⌘N)")
        .keyboardShortcut("n", modifiers: .command)
    }
}

// MARK: - Preview

#Preview("Regular - With Problems") {
    ExpenseCategoriesStaticHeader(
        windowSize: .regular,
        searchText: .constant(""),
        showOnlyOverBudget: .constant(false),
        parentCount: 11,
        subcategoryCount: 25,
        overBudgetCount: 3,
        onAddCategory: { print("Add category") }
    )
    .frame(width: 900)
}

#Preview("Regular - All On Track") {
    ExpenseCategoriesStaticHeader(
        windowSize: .regular,
        searchText: .constant(""),
        showOnlyOverBudget: .constant(false),
        parentCount: 11,
        subcategoryCount: 25,
        overBudgetCount: 0,
        onAddCategory: { print("Add category") }
    )
    .frame(width: 900)
}

#Preview("Compact") {
    ExpenseCategoriesStaticHeader(
        windowSize: .compact,
        searchText: .constant(""),
        showOnlyOverBudget: .constant(false),
        parentCount: 11,
        subcategoryCount: 25,
        overBudgetCount: 3,
        onAddCategory: { print("Add category") }
    )
    .frame(width: 640)
}

#Preview("Compact - Filter Active") {
    ExpenseCategoriesStaticHeader(
        windowSize: .compact,
        searchText: .constant(""),
        showOnlyOverBudget: .constant(true),
        parentCount: 11,
        subcategoryCount: 25,
        overBudgetCount: 3,
        onAddCategory: { print("Add category") }
    )
    .frame(width: 640)
}
