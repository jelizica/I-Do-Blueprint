//
//  PaymentFilterBar.swift
//  I Do Blueprint
//
//  Filter and grouping controls for payment schedule view
//

import SwiftUI

struct PaymentFilterBar: View {
    @Binding var showPlanView: Bool
    @Binding var selectedFilterOption: PaymentFilterOption
    @Binding var groupingStrategy: PaymentPlanGroupingStrategy
    @State private var showGroupingInfo = false
    
    let onViewModeChange: () -> Void
    let onGroupingChange: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // View mode toggle
            HStack(spacing: 12) {
                Text("View")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Picker("View Mode", selection: $showPlanView) {
                    Text("Individual").tag(false)
                    Text("Plans").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .onChange(of: showPlanView) { _ in
                    onViewModeChange()
                }
            }
            
            // Filter/Group By picker (shown for both views)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text(showPlanView ? "Group By" : "Filter")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if showPlanView {
                        Button(action: { showGroupingInfo = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showGroupingInfo) {
                            GroupingInfoView()
                                .frame(width: 320)
                                .padding()
                        }
                    }
                }
                
                if showPlanView {
                    Picker("Group By", selection: $groupingStrategy) {
                        ForEach(PaymentPlanGroupingStrategy.allCases, id: \.self) { strategy in
                            Label(strategy.displayName, systemImage: strategy.icon).tag(strategy)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .onChange(of: groupingStrategy) { _ in
                        onGroupingChange()
                    }
                } else {
                    Picker("Filter", selection: $selectedFilterOption) {
                        ForEach(PaymentFilterOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Filter Options

enum PaymentFilterOption: String, CaseIterable {
    case all = "all"
    case upcoming = "upcoming"
    case overdue = "overdue"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case paid = "paid"

    var displayName: String {
        switch self {
        case .all: "All"
        case .upcoming: "Upcoming"
        case .overdue: "Overdue"
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        case .paid: "Paid"
        }
    }
}
