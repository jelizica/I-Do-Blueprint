//
//  PaymentPlansListView.swift
//  I Do Blueprint
//
//  List view for payment plans with loading and error states
//

import SwiftUI

struct PaymentPlansListView: View {
    let isLoadingPlans: Bool
    let loadError: String?
    let groupingStrategy: PaymentPlanGroupingStrategy
    let paymentPlanSummaries: [PaymentPlanSummary]
    let paymentPlanGroups: [PaymentPlanGroup]
    let paymentSchedules: [PaymentSchedule]
    let expandedPlanIds: Set<UUID>
    
    let onRetry: () -> Void
    let onToggleExpansion: (UUID) -> Void
    let onTogglePaidStatus: (PaymentSchedule) -> Void
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    
    var body: some View {
        if isLoadingPlans {
            loadingView
        } else if let loadError {
            errorView(message: loadError)
        } else if groupingStrategy == .byPlanId {
            flatListView
        } else {
            hierarchicalGroupsView
        }
    }
    
    // MARK: - Loading State
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading payment plans...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
            Spacer()
        }
    }
    
    // MARK: - Error State
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to Load Payment Plans")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
    }
    
    // MARK: - Flat List View (By Plan ID)
    
    @ViewBuilder
    private var flatListView: some View {
        if paymentPlanSummaries.isEmpty {
            ContentUnavailableView(
                "No Payment Plans",
                systemImage: "calendar.badge.clock",
                description: Text("Payment plans will appear here when you have multiple payments for the same expense."))
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(paymentPlanSummaries) { plan in
                        ExpandablePaymentPlanCardView(
                            plan: plan,
                            paymentSchedules: paymentSchedules,
                            isExpanded: expandedPlanIds.contains(plan.id),
                            onToggle: {
                                onToggleExpansion(plan.id)
                            },
                            onTogglePaidStatus: onTogglePaidStatus,
                            onUpdate: onUpdate,
                            onDelete: onDelete,
                            getVendorName: getVendorName
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    // MARK: - Hierarchical Groups View (By Expense/Vendor)
    
    @ViewBuilder
    private var hierarchicalGroupsView: some View {
        if paymentPlanGroups.isEmpty {
            ContentUnavailableView(
                "No Payment Plans",
                systemImage: "calendar.badge.clock",
                description: Text("Payment plans will appear here when you have multiple payments."))
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(paymentPlanGroups) { group in
                        HierarchicalPaymentGroupView(
                            group: group,
                            paymentSchedules: paymentSchedules,
                            onTogglePaidStatus: onTogglePaidStatus,
                            onUpdate: onUpdate,
                            onDelete: onDelete,
                            getVendorName: getVendorName
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}
