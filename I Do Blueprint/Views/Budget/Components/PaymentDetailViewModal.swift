//
//  PaymentDetailViewModal.swift
//  I Do Blueprint
//
//  View-only payment detail modal with option to edit
//  Follows V6 design patterns with native macOS materials
//

import SwiftUI

struct PaymentDetailViewModal: View {
    let payment: PaymentSchedule
    @ObservedObject var vendorStore: VendorStoreV2
    @ObservedObject var budgetStore: BudgetStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditMode = false
    @State private var hasAppeared = false
    
    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: settingsStore.settings)
    }
    
    private var vendorName: String {
        guard let vendorId = payment.vendorId else {
            return payment.notes ?? "Payment"
        }
        
        if let vendor = vendorStore.vendors.first(where: { $0.id == vendorId }) {
            return vendor.vendorName
        }
        
        return payment.notes ?? "Payment"
    }
    
    private var relatedExpense: Expense? {
        guard case .loaded(let budgetData) = budgetStore.loadingState else { return nil }
        return budgetData.expenses.first(where: { $0.id == payment.expenseId })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Header Section
                    headerSection
                    
                    NativeDividerStyle(opacity: 0.4)
                    
                    // Payment Details Section
                    paymentDetailsSection
                    
                    NativeDividerStyle(opacity: 0.4)
                    
                    // Status Section
                    statusSection
                    
                    if let notes = payment.notes, !notes.isEmpty {
                        NativeDividerStyle(opacity: 0.4)
                        notesSection(notes)
                    }
                    
                    if let expense = relatedExpense {
                        NativeDividerStyle(opacity: 0.4)
                        relatedExpenseSection(expense)
                    }
                }
                .padding(Spacing.xl)
            }
            .background(
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
            )
            .navigationTitle("Payment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditMode = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .frame(minWidth: 600, maxWidth: 800, minHeight: 500, maxHeight: 700)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingEditMode) {
            PaymentEditModal(
                payment: payment,
                expense: relatedExpense,
                getVendorName: { vendorId in
                    guard let id = vendorId else { return nil }
                    // vendorId is Int64, but Vendor.id is UUID
                    // The vendorId in PaymentSchedule refers to the vendor's database ID
                    // For now, we use the vendorId from payment which is already a UUID
                    // This closure is used by PaymentEditModal for display purposes
                    return vendorStore.vendors.first(where: { $0.id == payment.vendorId })?.vendorName
                },
                onUpdate: { updatedPayment in
                    Task {
                        await budgetStore.payments.updatePayment(updatedPayment)
                    }
                },
                onDelete: {
                    Task {
                        await budgetStore.payments.deletePayment(id: payment.id)
                        dismiss()
                    }
                }
            )
            .environmentObject(settingsStore)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: Spacing.lg) {
            // Status Icon Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                statusColor.opacity(0.2),
                                statusColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: payment.paid ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [statusColor, statusColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: statusColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: hasAppeared)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(vendorName)
                    .font(Typography.title1)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(formatFullDate(payment.paymentDate))
                    .font(Typography.subheading)
                    .foregroundColor(SemanticColors.textSecondary)
                
                // Status Badge
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(payment.paid ? "Paid" : "Unpaid")
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(statusColor.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(x: hasAppeared ? 0 : -20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
            
            Spacer()
        }
    }
    
    // MARK: - Payment Details Section
    
    private var paymentDetailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Payment Information")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            // Amount Card
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.Budget.allocated, AppColors.Budget.allocated.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Payment Amount")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    Spacer()
                }
                
                Text("$\(formatAmount(payment.paymentAmount))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SemanticColors.textPrimary, SemanticColors.textPrimary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(AppColors.Budget.allocated.opacity(0.2), lineWidth: 1)
            )
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: hasAppeared)
            
            // Detail Rows
            VStack(spacing: Spacing.md) {
                detailRow(
                    icon: "calendar",
                    label: "Due Date",
                    value: formatFullDate(payment.paymentDate),
                    color: SemanticColors.statusPending
                )
                
                if payment.isDeposit {
                    detailRow(
                        icon: "banknote",
                        label: "Payment Type",
                        value: "Deposit",
                        color: SemanticColors.statusPending
                    )
                } else if payment.isRetainer {
                    detailRow(
                        icon: "star.fill",
                        label: "Payment Type",
                        value: "Retainer",
                        color: AppColors.Budget.allocated
                    )
                }
                
                if let order = payment.paymentOrder {
                    detailRow(
                        icon: "number",
                        label: "Payment Number",
                        value: "#\(order)",
                        color: SemanticColors.textSecondary
                    )
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: hasAppeared)
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Status")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            HStack(spacing: Spacing.lg) {
                // Paid Status
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: payment.paid ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(payment.paid ? SemanticColors.success : SemanticColors.textTertiary)
                        
                        Text("Payment Status")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                    
                    Text(payment.paid ? "Paid" : "Unpaid")
                        .font(Typography.bodyRegular.weight(.semibold))
                        .foregroundColor(payment.paid ? SemanticColors.success : SemanticColors.warning)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(.ultraThinMaterial)
                )
                
                // Overdue Status
                if !payment.paid && payment.paymentDate < Date() {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(SemanticColors.error)
                            
                            Text("Overdue")
                                .font(Typography.caption)
                                .foregroundColor(SemanticColors.textSecondary)
                        }
                        
                        Text("\(daysOverdue) days")
                            .font(Typography.bodyRegular.weight(.semibold))
                            .foregroundColor(SemanticColors.error)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(SemanticColors.error.opacity(0.1))
                    )
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: hasAppeared)
        }
    }
    
    // MARK: - Notes Section
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "note.text")
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text("Notes")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            Text(notes)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(.ultraThinMaterial)
                )
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: hasAppeared)
    }
    
    // MARK: - Related Expense Section
    
    private func relatedExpenseSection(_ expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "link")
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text("Related Expense")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(expense.expenseName)
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(SemanticColors.textPrimary)
                    
                    Text("$\(formatAmount(expense.amount))")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(.ultraThinMaterial)
            )
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.7), value: hasAppeared)
    }
    
    // MARK: - Helper Views
    
    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(Typography.bodyRegular.weight(.medium))
                .foregroundColor(SemanticColors.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        payment.paid ? SemanticColors.success : SemanticColors.warning
    }
    
    private var daysOverdue: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDate = calendar.startOfDay(for: payment.paymentDate)
        let components = calendar.dateComponents([.day], from: dueDate, to: today)
        return max(components.day ?? 0, 0)
    }
    
    // MARK: - Formatters
    
    private func formatFullDate(_ date: Date) -> String {
        DateFormatting.formatDate(date, format: "MMMM d, yyyy", timezone: userTimezone)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Preview

// Preview temporarily disabled due to missing test data helper
// TODO: Add PaymentSchedule test helper or create sample data
