//
//  PaymentScheduleUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified responsive header for Payment Schedule
//  Follows pattern from ExpenseTrackerUnifiedHeader and BudgetOverviewUnifiedHeader
//

import SwiftUI

struct PaymentScheduleUnifiedHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage
    let onAddPayment: () -> Void
    let onRefresh: () async -> Void
    
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
                
                Text("Payment Schedule")
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
            Button(action: onAddPayment) {
                Label("Add Payment", systemImage: "plus")
            }
            
            Button(action: {
                Task {
                    await onRefresh()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            
            Divider()
            
            Button(action: {
                AppLogger.ui.info("Export - Not yet implemented")
            }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(AppColors.textPrimary)
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
            .foregroundColor(AppColors.textPrimary)
            .frame(width: windowSize == .compact ? 44 : nil, height: 44)
        }
        .buttonStyle(.plain)
        .help("Navigate budget pages")
    }
}
