//
//  MonthlyPaymentDetailsViewV1.swift
//  I Do Blueprint
//
//  Monthly payment details view - drill-down from PaymentTimelineViewV1
//  Displays payments for a specific month with glassmorphism design
//  Features: donut chart progress, summary cards, payment schedule table
//
//  Version: V1
//  Integration: Presented as sheet from PaymentTimelineViewV1 month card tap
//

import SwiftUI

// MARK: - Monthly Payment Details View V1

struct MonthlyPaymentDetailsViewV1: View {
    let month: Date
    let payments: [PaymentSchedule]
    let expenses: [Expense]
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var searchQuery: String = ""
    @State private var selectedFilter: PaymentStatusFilter = .all
    @State private var selectedPayment: PaymentSchedule?
    @State private var showingEditModal = false
    @State private var hoveredPaymentId: Int64?
    @State private var isContentReady = false

    private var isDarkMode: Bool { colorScheme == .dark }

    // MARK: - Proportional Modal Sizing Pattern

    private let minWidth: CGFloat = 900
    private let maxWidth: CGFloat = 1200
    private let minHeight: CGFloat = 700
    private let maxHeight: CGFloat = 900
    private let widthProportion: CGFloat = 0.75
    private let heightProportion: CGFloat = 0.85

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion
        let finalWidth = min(maxWidth, max(minWidth, targetWidth))
        let finalHeight = min(maxHeight, max(minHeight, targetHeight))
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
    // MARK: - Computed Properties
    
    private var filteredPayments: [PaymentSchedule] {
        var result = payments
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .paid:
            result = result.filter { $0.paid }
        case .dueSoon:
            let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            result = result.filter { !$0.paid && $0.paymentDate <= sevenDaysFromNow && $0.paymentDate >= Date() }
        case .scheduled:
            let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            result = result.filter { !$0.paid && $0.paymentDate > sevenDaysFromNow }
        case .overdue:
            result = result.filter { !$0.paid && $0.paymentDate < Date() }
        }
        
        // Apply search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { payment in
                payment.vendor.lowercased().contains(query) ||
                (payment.notes?.lowercased().contains(query) ?? false)
            }
        }
        
        return result.sorted { $0.paymentDate < $1.paymentDate }
    }
    
    private var totalAmount: Double {
        payments.reduce(0) { $0 + $1.paymentAmount }
    }
    
    private var paidAmount: Double {
        payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
    }
    
    private var remainingAmount: Double {
        totalAmount - paidAmount
    }
    
    private var completionPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return (paidAmount / totalAmount) * 100
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.timeZone = userTimezone
        return formatter.string(from: month)
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            
            ZStack {
                // Background
                backgroundView
                
                // Content - show immediately since sheet(item:) guarantees data is ready
                VStack(spacing: 0) {
                    // Header with back button
                    headerView(windowSize: windowSize)
                    
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Progress section with donut chart
                            progressSection(windowSize: windowSize)
                            
                            // Summary cards
                            summaryCardsSection(windowSize: windowSize)
                            
                            // Payment schedule table
                            paymentTableSection(windowSize: windowSize)
                        }
                        .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
                        .padding(.vertical, Spacing.lg)
                    }
                }
                .opacity(isContentReady ? 1 : 0)
            }
        }
        .onAppear {
            // Brief delay for smooth animation, but content is ready immediately
            withAnimation(.easeOut(duration: 0.15)) {
                isContentReady = true
            }
        }
        .sheet(isPresented: $showingEditModal) {
            if let payment = selectedPayment {
                PaymentEditModal(
                    payment: payment,
                    expense: expenses.first { $0.id == payment.expenseId },
                    getVendorName: getVendorName,
                    onUpdate: onUpdate,
                    onDelete: { onDelete(payment) }
                )
            }
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Base color
            (isDarkMode ? Color.black.opacity(0.95) : Color.fromHex("F3F4F6"))
                .ignoresSafeArea()
            
            // Gradient overlay for depth
            LinearGradient(
                colors: isDarkMode
                    ? [Color.fromHex("1A1A2E").opacity(0.8), Color.black.opacity(0.9)]
                    : [Color.white.opacity(0.3), Color.fromHex("F3F4F6").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header
    
    private func headerView(windowSize: WindowSize) -> some View {
        HStack(spacing: Spacing.md) {
            // Back button with enhanced styling
            Button(action: onDismiss) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back to Timeline")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(Color.white.opacity(isDarkMode ? 0.2 : 0.6), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Month badge on the right
            HStack(spacing: Spacing.xs) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .medium))
                Text(monthTitle)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(isDarkMode ? .white.opacity(0.9) : SemanticColors.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: isDarkMode
                                ? [Color.white.opacity(0.15), Color.white.opacity(0.08)]
                                : [Color.white.opacity(0.8), Color.white.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDarkMode ? 0.3 : 0.8),
                                        Color.white.opacity(isDarkMode ? 0.1 : 0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Progress Section
    
    private func progressSection(windowSize: WindowSize) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Donut chart and stats
            HStack(spacing: windowSize == .compact ? Spacing.lg : Spacing.xxl) {
                // Donut Chart
                DonutChartView(
                    percentage: completionPercentage,
                    paidColor: Color.fromHex("10B981"),
                    remainingColor: Color.fromHex("F87171"),
                    isDarkMode: isDarkMode
                )
                .frame(width: 180, height: 180)
                
                // Stats
                VStack(alignment: windowSize == .compact ? .center : .leading, spacing: Spacing.xs) {
                    Text("Total Paid vs Total Due")
                        .font(.system(size: 16))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : SemanticColors.textSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(formatCurrency(paidAmount))
                            .font(.system(size: windowSize == .compact ? 32 : 48, weight: .heavy))
                            .foregroundColor(Color.fromHex("10B981"))
                        
                        Text("/")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(isDarkMode ? .white.opacity(0.4) : SemanticColors.textTertiary)
                        
                        Text(formatCurrency(totalAmount))
                            .font(.system(size: windowSize == .compact ? 24 : 32, weight: .heavy))
                            .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                    }
                    
                    Text(progressMessage)
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textSecondary)
                        .frame(maxWidth: 400, alignment: windowSize == .compact ? .center : .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .glassPanel(cornerRadius: CornerRadius.xxl, padding: 0)
    }
    
    private var progressMessage: String {
        let percentage = Int(completionPercentage)
        if percentage >= 100 {
            return "All payments for \(monthTitle) are complete! 🎉"
        } else if percentage >= 75 {
            return "Almost there! Just a few more payments to go."
        } else if percentage >= 50 {
            return "You're making great progress on your payments."
        } else if percentage > 0 {
            return "Keep up the momentum with your payment schedule."
        } else {
            return "Start tracking your payments for \(monthTitle)."
        }
    }
    
    // MARK: - Summary Cards
    
    private func summaryCardsSection(windowSize: WindowSize) -> some View {
        HStack(spacing: Spacing.md) {
            // Total Plan Value
            MonthlySummaryCard(
                icon: "doc.text.fill",
                iconBackgroundColor: Color.fromHex("DBEAFE"),
                iconColor: Color.fromHex("3B82F6"),
                title: "Total Plan Value",
                value: formatCurrency(totalAmount),
                valueColor: isDarkMode ? .white : SemanticColors.textPrimary,
                isDarkMode: isDarkMode
            )
            
            // Paid Amount
            MonthlySummaryCard(
                icon: "checkmark.circle.fill",
                iconBackgroundColor: Color.fromHex("D1FAE5"),
                iconColor: Color.fromHex("10B981"),
                title: "Paid Amount",
                value: formatCurrency(paidAmount),
                valueColor: Color.fromHex("047857"),
                isDarkMode: isDarkMode
            )
            
            // Remaining Amount
            MonthlySummaryCard(
                icon: "banknote.fill",
                iconBackgroundColor: Color.fromHex("FFE4E6"),
                iconColor: Color.fromHex("F43F5E"),
                title: "Remaining Amount",
                value: formatCurrency(remainingAmount),
                valueColor: Color.fromHex("E11D48"),
                isDarkMode: isDarkMode
            )
        }
    }
    
    // MARK: - Payment Table Section
    
    private func paymentTableSection(windowSize: WindowSize) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section header
            Text("Payment Schedule")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
            
            // Table
            VStack(spacing: 0) {
                // Table header
                tableHeaderRow
                
                Divider()
                    .background(Color.white.opacity(isDarkMode ? 0.1 : 0.3))
                
                // Table rows
                if filteredPayments.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredPayments, id: \.id) { payment in
                        PaymentTableRow(
                            payment: payment,
                            getVendorName: getVendorName,
                            userTimezone: userTimezone,
                            isDarkMode: isDarkMode,
                            isHovered: hoveredPaymentId == payment.id,
                            onTap: {
                                selectedPayment = payment
                                showingEditModal = true
                            },
                            onHover: { hovering in
                                hoveredPaymentId = hovering ? payment.id : nil
                            },
                            onMarkPaid: {
                                var updatedPayment = payment
                                updatedPayment.paid = true
                                onUpdate(updatedPayment)
                            }
                        )
                        
                        if payment.id != filteredPayments.last?.id {
                            Divider()
                                .background(Color.white.opacity(isDarkMode ? 0.05 : 0.2))
                        }
                    }
                }
                
                // Footer with search and filters
                tableFooter(windowSize: windowSize)
            }
            .glassPanel(cornerRadius: CornerRadius.xxl, padding: Spacing.md)
        }
    }
    
    private var tableHeaderRow: some View {
        HStack {
            Text("Date")
                .frame(width: 120, alignment: .leading)
            Text("Description")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Amount")
                .frame(width: 100, alignment: .leading)
            Text("Status")
                .frame(width: 100, alignment: .leading)
            Text("Action")
                .frame(width: 100, alignment: .trailing)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(isDarkMode ? .white.opacity(0.3) : SemanticColors.textTertiary)
            
            Text("No payments found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)
            
            if !searchQuery.isEmpty || selectedFilter != .all {
                Text("Try adjusting your search or filter")
                    .font(.system(size: 14))
                    .foregroundColor(isDarkMode ? .white.opacity(0.4) : SemanticColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
    private func tableFooter(windowSize: WindowSize) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(isDarkMode ? 0.1 : 0.3))
            
            HStack(spacing: Spacing.md) {
                // Search
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)
                    
                    TextField("Search transactions...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .frame(width: windowSize == .compact ? nil : 250)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.white.opacity(isDarkMode ? 0.1 : 0.6), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Filter dropdown
                filterDropdown
                
                // Sort dropdown
                sortDropdown
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
    }
    
    private var filterDropdown: some View {
        Menu {
            ForEach(PaymentStatusFilter.allCases, id: \.self) { filter in
                Button(action: { selectedFilter = filter }) {
                    HStack {
                        Text(filter.displayName)
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text("Filter: \(selectedFilter.displayName)")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(isDarkMode ? .white.opacity(0.7) : SemanticColors.textSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.white.opacity(isDarkMode ? 0.1 : 0.6), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var sortDropdown: some View {
        Menu {
            Button("Sort: By Date") { }
            Button("Sort: Amount") { }
            Button("Sort: Status") { }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text("Sort: By Date")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(isDarkMode ? .white.opacity(0.7) : SemanticColors.textSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.white.opacity(isDarkMode ? 0.1 : 0.6), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Payment Status Filter

private enum PaymentStatusFilter: String, CaseIterable {
    case all = "All Statuses"
    case paid = "Paid"
    case dueSoon = "Due Soon"
    case scheduled = "Scheduled"
    case overdue = "Overdue"
    
    var displayName: String { rawValue }
}

// MARK: - Donut Chart View

private struct DonutChartView: View {
    let percentage: Double
    let paidColor: Color
    let remainingColor: Color
    let isDarkMode: Bool
    
    @State private var animatedPercentage: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle (remaining)
            Circle()
                .stroke(remainingColor.opacity(0.3), lineWidth: 12)
            
            // Foreground circle (paid)
            Circle()
                .trim(from: 0, to: animatedPercentage / 100)
                .stroke(
                    paidColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: animatedPercentage)
            
            // Center text
            VStack(spacing: Spacing.xxs) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                
                Text("Completed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedPercentage = percentage
            }
        }
    }
}

// MARK: - Monthly Summary Card

private struct MonthlySummaryCard: View {
    let icon: String
    let iconBackgroundColor: Color
    let iconColor: Color
    let title: String
    let value: String
    let valueColor: Color
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                )
            
            // Title
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            // Value
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.md)
    }
}

// MARK: - Payment Table Row

private struct PaymentTableRow: View {
    let payment: PaymentSchedule
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    let isDarkMode: Bool
    let isHovered: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    let onMarkPaid: () -> Void
    
    private var status: PaymentRowStatus {
        if payment.paid {
            return .paid
        } else if payment.paymentDate < Date() {
            return .overdue
        } else {
            let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            if payment.paymentDate <= sevenDaysFromNow {
                return .dueSoon
            }
            return .scheduled
        }
    }
    
    private var vendorName: String {
        if !payment.vendor.isEmpty {
            return payment.vendor
        }
        return getVendorName(payment.vendorId) ?? "Unknown Vendor"
    }
    
    var body: some View {
        HStack {
            // Date
            Text(formatDate(payment.paymentDate))
                .font(.system(size: 14, weight: status == .dueSoon ? .semibold : .medium))
                .foregroundColor(dateColor)
                .frame(width: 120, alignment: .leading)
            
            // Description (Vendor name)
            Text(vendorName)
                .font(.system(size: 14, weight: status == .dueSoon ? .bold : .medium))
                .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Amount
            Text(formatCurrency(payment.paymentAmount))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(amountColor)
                .frame(width: 100, alignment: .leading)
            
            // Status badge
            statusBadge
                .frame(width: 100, alignment: .leading)
            
            // Action button
            actionButton
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(rowBackground)
        .onHover(perform: onHover)
        .onTapGesture(perform: onTap)
    }
    
    private var dateColor: Color {
        switch status {
        case .dueSoon, .overdue:
            return Color.fromHex("881337")
        case .paid:
            return isDarkMode ? .white : SemanticColors.textPrimary
        case .scheduled:
            return isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary
        }
    }
    
    private var amountColor: Color {
        switch status {
        case .dueSoon, .overdue:
            return isDarkMode ? .white : SemanticColors.textPrimary
        case .paid:
            return isDarkMode ? .white : SemanticColors.textPrimary
        case .scheduled:
            return isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary
        }
    }
    
    @ViewBuilder
    private var rowBackground: some View {
        if status == .dueSoon {
            LinearGradient(
                colors: [
                    Color.red.opacity(0.1),
                    Color.red.opacity(0.2)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .border(width: 1, edges: [.top, .bottom], color: Color.red.opacity(0.3))
            )
        } else if isHovered {
            Color.white.opacity(isDarkMode ? 0.05 : 0.3)
        } else {
            Color.clear
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: status.icon)
                .font(.system(size: 10))
            Text(status.displayName)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(status.textColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(status.backgroundColor)
                .shadow(color: status == .dueSoon ? Color.red.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if status == .paid {
            Button(action: onTap) {
                Text("View Receipt")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : SemanticColors.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.white.opacity(isDarkMode ? 0.1 : 0.7), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        } else if status == .dueSoon || status == .overdue {
            Button(action: onMarkPaid) {
                Text("Pay Now")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.fromHex("10B981"))
                            .shadow(color: Color.fromHex("10B981").opacity(0.4), radius: 8, x: 0, y: 4)
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        } else {
            Button(action: onTap) {
                Text("View Details")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textTertiary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.white.opacity(isDarkMode ? 0.1 : 0.7), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.timeZone = userTimezone
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Payment Row Status

private enum PaymentRowStatus {
    case paid
    case dueSoon
    case scheduled
    case overdue
    
    var displayName: String {
        switch self {
        case .paid: return "Paid"
        case .dueSoon: return "Due Soon"
        case .scheduled: return "Scheduled"
        case .overdue: return "Overdue"
        }
    }
    
    var icon: String {
        switch self {
        case .paid: return "checkmark"
        case .dueSoon: return "clock"
        case .scheduled: return "circle"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .paid: return Color.fromHex("D1FAE5")
        case .dueSoon: return Color.fromHex("FFE4E6")
        case .scheduled: return Color.fromHex("E5E7EB")
        case .overdue: return Color.fromHex("FEE2E2")
        }
    }
    
    var textColor: Color {
        switch self {
        case .paid: return Color.fromHex("047857")
        case .dueSoon: return Color.fromHex("BE123C")
        case .scheduled: return Color.fromHex("4B5563")
        case .overdue: return Color.fromHex("DC2626")
        }
    }
}

// MARK: - Border Helper

private extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

private struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }
            
            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }
            
            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }
            
            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    MonthlyPaymentDetailsViewV1(
        month: Date(),
        payments: [],
        expenses: [],
        getVendorName: { _ in "Sample Vendor" },
        userTimezone: .current,
        onUpdate: { _ in },
        onDelete: { _ in },
        onDismiss: { }
    )
    .preferredColorScheme(.light)
    .frame(width: 1200, height: 800)
}

#Preview("Dark Mode") {
    MonthlyPaymentDetailsViewV1(
        month: Date(),
        payments: [],
        expenses: [],
        getVendorName: { _ in "Sample Vendor" },
        userTimezone: .current,
        onUpdate: { _ in },
        onDelete: { _ in },
        onDismiss: { }
    )
    .preferredColorScheme(.dark)
    .frame(width: 1200, height: 800)
}
