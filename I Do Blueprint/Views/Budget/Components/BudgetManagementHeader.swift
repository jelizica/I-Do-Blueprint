//
//  BudgetManagementHeader.swift
//  I Do Blueprint
//
//  Created by Claude on 1/1/26.
//  Standardized header component following Management View Header Alignment Pattern
//

import SwiftUI

struct BudgetManagementHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Title and subtitle
            VStack(alignment: .leading, spacing: 8) {
                Text("Budget")
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)

                if windowSize != .compact {
                    Text(currentPage == .hub ? "Your wedding budget at a glance" : currentPage.rawValue)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Navigation dropdown (replaces refresh button)
            budgetPageDropdown
        }
        .frame(height: 68)
    }

    // MARK: - Budget Page Dropdown

    private var budgetPageDropdown: some View {
        Menu {
            // Dashboard (always first, outside sections)
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

            // All sections with all pages visible (no expansion needed)
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

// MARK: - Preview

#Preview {
    @Previewable @State var currentPage: BudgetPage = .hub

    VStack(spacing: 0) {
        BudgetManagementHeader(
            windowSize: .regular,
            currentPage: $currentPage
        )
        .padding(.horizontal, Spacing.huge)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.lg)
        .background(Color(NSColor.windowBackgroundColor))

        Spacer()
    }
    .frame(width: 900, height: 600)
}
