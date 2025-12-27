//
//  PaymentPlanListView.swift
//  I Do Blueprint
//
//  List view for displaying payment plan summaries with toggle
//  Allows switching between plan view and individual payment view
//

import SwiftUI

/// List view displaying payment plan summaries with view toggle
struct PaymentPlanListView: View {
    @ObservedObject var paymentStore: PaymentScheduleStore
    @State private var selectedPlan: PaymentPlanSummary?
    @State private var showingIndividualPayments = false
    @State private var expandedPlanIds: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                Text("Payments")
                    .font(Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Picker("View", selection: $paymentStore.showPlanView) {
                    Text("Individual").tag(false)
                    Text("Plans").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: paymentStore.showPlanView) { newValue in
                    if newValue {
                        // Load plan summaries when switching to plan view
                        Task {
                            await paymentStore.loadPaymentPlanSummaries()
                        }
                    }
                }
                .accessibilityLabel("Payment view mode")
                .accessibilityHint("Switch between individual payments and payment plans")
            }
            .padding(Spacing.md)
            
            Divider()
            
            // Content
            if paymentStore.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .accessibilityLabel("Loading payments")
                    Spacer()
                }
            } else if let error = paymentStore.error {
                VStack(spacing: Spacing.md) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Error Loading Payments")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(error.localizedDescription)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                    
                    Button("Retry") {
                        Task {
                            if paymentStore.showPlanView {
                                await paymentStore.loadPaymentPlanSummaries()
                            } else {
                                await paymentStore.loadPaymentSchedules()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error loading payments. \(error.localizedDescription)")
            } else if paymentStore.showPlanView {
                // Plan View
                planListView
            } else {
                // Individual Payment View
                individualPaymentView
            }
        }
        .task {
            // Load initial data
            if paymentStore.showPlanView {
                await paymentStore.loadPaymentPlanSummaries()
            } else {
                await paymentStore.loadPaymentSchedules()
            }
        }
        .sheet(item: $selectedPlan) { plan in
            PaymentPlanDetailView(plan: plan, paymentStore: paymentStore)
        }
    }
    
    // MARK: - Plan List View
    
    private var planListView: some View {
        Group {
            if paymentStore.paymentPlanSummaries.isEmpty {
                VStack(spacing: Spacing.md) {
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No Payment Plans")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Payment plans will appear here when you have multiple payments for the same expense.")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                    
                    Spacer()
                }
                .accessibilityLabel("No payment plans available")
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(paymentStore.paymentPlanSummaries) { plan in
                            ExpandablePaymentPlanView(
                                plan: plan,
                                paymentStore: paymentStore,
                                isExpanded: expandedPlanIds.contains(plan.id)
                            ) {
                                toggleExpansion(for: plan.id)
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleExpansion(for planId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedPlanIds.contains(planId) {
                expandedPlanIds.remove(planId)
            } else {
                expandedPlanIds.insert(planId)
            }
        }
    }
    
    // MARK: - Individual Payment View
    
    private var individualPaymentView: some View {
        Group {
            if paymentStore.paymentSchedules.isEmpty {
                VStack(spacing: Spacing.md) {
                    Spacer()
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No Payments")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Add payment schedules to track your wedding expenses.")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                    
                    Spacer()
                }
                .accessibilityLabel("No payment schedules available")
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(paymentStore.paymentSchedules) { schedule in
                            PaymentPlanScheduleRowView(schedule: schedule, paymentStore: paymentStore)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
    }
}

// MARK: - Payment Schedule Row View

private struct PaymentPlanScheduleRowView: View {
    let schedule: PaymentSchedule
    @ObservedObject var paymentStore: PaymentScheduleStore
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Image(systemName: schedule.paid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(schedule.paid ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(schedule.vendor ?? "Unknown Vendor")
                    .font(Typography.subheading)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(schedule.paymentDate, format: .dateTime.month().day().year())
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text(schedule.paymentAmount, format: .currency(code: "USD"))
                .font(Typography.subheading)
                .fontWeight(.semibold)
                .foregroundColor(schedule.paid ? .green : AppColors.textPrimary)
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.sm)
        .onTapGesture {
            Task {
                await paymentStore.togglePaidStatus(schedule)
            }
        }
        .accessibleActionButton(
            label: "Payment to \(schedule.vendor ?? "Unknown Vendor") for $\(String(format: "%.2f", schedule.paymentAmount))",
            hint: "Tap to toggle payment status"
        )
    }
}

// MARK: - Payment Plan Detail View

private struct PaymentPlanDetailView: View {
    let plan: PaymentPlanSummary
    @ObservedObject var paymentStore: PaymentScheduleStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(plan.vendor)
                    .font(Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding(Spacing.md)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Plan Summary Card
                    PaymentPlanSummaryView(plan: plan) {}
                        .disabled(true)
                    
                    // Individual Payments Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Individual Payments")
                            .font(Typography.heading)
                            .foregroundColor(AppColors.textPrimary)
                        
                        // Filter payments for this specific payment plan
                        let planPayments = paymentStore.paymentSchedules.filter { $0.paymentPlanId == plan.id }
                        
                        if planPayments.isEmpty {
                            Text("No individual payments found")
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            ForEach(planPayments.sorted(by: { $0.paymentDate < $1.paymentDate })) { schedule in
                                PaymentPlanScheduleRowView(schedule: schedule, paymentStore: paymentStore)
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - Preview

#if DEBUG
struct PaymentPlanListView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentPlanListView(paymentStore: PaymentScheduleStore())
            .frame(width: 800, height: 600)
    }
}
#endif
