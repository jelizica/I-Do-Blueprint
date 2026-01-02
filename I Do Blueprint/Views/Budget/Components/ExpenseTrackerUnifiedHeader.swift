//
//  ExpenseTrackerUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified responsive header for Expense Tracker
//  Follows pattern from VendorManagementHeader and BudgetOverviewUnifiedHeader
//

import SwiftUI

struct ExpenseTrackerUnifiedHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage
    let onAddExpense: () -> Void
    
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
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Expense Tracker")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
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
            Button(action: onAddExpense) {
                Label("Add Expense", systemImage: "plus")
            }
            
            Divider()
            
            Button(action: {
                AppLogger.ui.info("Export CSV - Not yet implemented")
            }) {
                Label("Export as CSV", systemImage: "tablecells")
            }
            
            Button(action: {
                AppLogger.ui.info("Export PDF - Not yet implemented")
            }) {
                Label("Export as PDF", systemImage: "doc.richtext")
            }
            
            Divider()
            
            Button(action: {
                AppLogger.ui.info("Bulk Edit - Not yet implemented")
            }) {
                Label("Bulk Edit", systemImage: "pencil.and.list.clipboard")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(AppColors.textPrimary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation Dropdown
    
    private var budgetPageDropdown: some View {
        Menu {
            Button {
                currentPage = .hub
            } label: {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            
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
            .foregroundColor(AppColors.textPrimary)
            .frame(width: windowSize == .compact ? 44 : nil, height: 44)
        }
        .buttonStyle(.plain)
    }
    
    }
