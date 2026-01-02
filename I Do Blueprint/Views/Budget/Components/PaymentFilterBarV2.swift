//
//  PaymentFilterBarV2.swift
//  I Do Blueprint
//
//  Responsive filter bar for Payment Schedule
//  Follows pattern from ExpenseFiltersBarV2
//

import SwiftUI

struct PaymentFilterBarV2: View {
    let windowSize: WindowSize
    @Binding var showPlanView: Bool
    @Binding var selectedFilterOption: PaymentFilterOption
    @Binding var groupingStrategy: PaymentPlanGroupingStrategy
    @State private var showGroupingInfo = false
    
    let onViewModeChange: () -> Void
    let onGroupingChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(spacing: Spacing.sm) {
            // View mode toggle (full width)
            viewModeToggle
                .frame(maxWidth: .infinity)
            
            // Filter/Grouping row
            HStack(spacing: Spacing.sm) {
                if showPlanView {
                    groupingMenu
                    groupingInfoButton
                } else {
                    filterMenu
                }
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.md) {
            Text("View")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
            
            viewModeToggle
                .frame(width: 200)
            
            Spacer()
            
            HStack(spacing: Spacing.xs) {
                Text(showPlanView ? "Group By" : "Filter")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                
                if showPlanView {
                    groupingInfoButton
                }
            }
            
            if showPlanView {
                groupingPicker
                    .frame(width: 250)
            } else {
                filterPicker
                    .frame(width: 200)
            }
        }
    }
    
    // MARK: - View Mode Toggle
    
    private var viewModeToggle: some View {
        Picker("View Mode", selection: $showPlanView) {
            Text("Individual").tag(false)
            Text("Plans").tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: showPlanView) { oldValue, newValue in
            onViewModeChange()
        }
    }
    
    // MARK: - Filter Menu (Compact)
    
    private var filterMenu: some View {
        Menu {
            ForEach(PaymentFilterOption.allCases, id: \.self) { option in
                Button(option.displayName) {
                    selectedFilterOption = option
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.caption)
                Text(selectedFilterOption.displayName)
                    .font(Typography.bodySmall)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppColors.primary)
    }
    
    // MARK: - Filter Picker (Regular)
    
    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilterOption) {
            ForEach(PaymentFilterOption.allCases, id: \.self) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
    
    // MARK: - Grouping Menu (Compact)
    
    private var groupingMenu: some View {
        Menu {
            ForEach(PaymentPlanGroupingStrategy.allCases, id: \.self) { strategy in
                Button {
                    groupingStrategy = strategy
                    onGroupingChange()
                } label: {
                    Label(strategy.displayName, systemImage: strategy.icon)
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: groupingStrategy.icon)
                    .font(.caption)
                Text(groupingStrategy.displayName)
                    .font(Typography.bodySmall)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.teal)
    }
    
    // MARK: - Grouping Picker (Regular)
    
    private var groupingPicker: some View {
        Picker("Group By", selection: $groupingStrategy) {
            ForEach(PaymentPlanGroupingStrategy.allCases, id: \.self) { strategy in
                Label(strategy.displayName, systemImage: strategy.icon).tag(strategy)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .onChange(of: groupingStrategy) { oldValue, newValue in
            onGroupingChange()
        }
    }
    
    // MARK: - Grouping Info Button
    
    private var groupingInfoButton: some View {
        Button(action: { showGroupingInfo = true }) {
            Image(systemName: "info.circle")
                .font(.system(size: windowSize == .compact ? 16 : 13))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: windowSize == .compact ? 36 : nil, height: windowSize == .compact ? 36 : nil)
                .background(windowSize == .compact ? Color(NSColor.controlBackgroundColor) : Color.clear)
                .cornerRadius(windowSize == .compact ? 6 : 0)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showGroupingInfo) {
            GroupingInfoView()
                .frame(width: 320)
                .padding()
        }
        .help("Grouping information")
    }
}

