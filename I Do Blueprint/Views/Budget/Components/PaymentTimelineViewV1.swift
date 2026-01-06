//
//  PaymentTimelineViewV1.swift
//  I Do Blueprint
//
//  Timeline visualization for payment schedules with glassmorphic design
//  Displays payments on a horizontal timeline with status-colored cards
//  positioned above and below the track line
//
//  Version: V1
//  Integration: Used within PaymentScheduleView as an alternative to list views
//

import SwiftUI

// MARK: - Month Event Selection (for sheet presentation)

/// Identifiable wrapper for month event selection to use with sheet(item:)
/// This prevents the empty modal flash by ensuring the sheet only presents when data is ready
private struct MonthEventSelection: Identifiable {
    let id = UUID()
    let month: Date
    let payments: [PaymentSchedule]
}

// MARK: - Timeline Event Model (moved to top for stable ID generation)

/// Timeline event with STABLE identity based on month
/// This prevents SwiftUI from recreating views on every render
private struct TimelineEvent: Identifiable, Equatable {
    /// Stable ID based on month timestamp - one event per month
    var id: String {
        "\(month.timeIntervalSince1970)"
    }
    
    let month: Date
    let status: TimelinePaymentStatus
    let paymentCount: Int
    let totalAmount: Double
    let paidAmount: Double  // Amount already paid this month
    let payments: [PaymentSchedule]
    let position: Int
    let isAboveLine: Bool
    
    /// Remaining amount to be paid
    var remainingAmount: Double {
        totalAmount - paidAmount
    }
    
    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        lhs.id == rhs.id &&
        lhs.paymentCount == rhs.paymentCount &&
        lhs.totalAmount == rhs.totalAmount &&
        lhs.paidAmount == rhs.paidAmount &&
        lhs.isAboveLine == rhs.isAboveLine
    }
}

// MARK: - Timeline Payment Status

private enum TimelinePaymentStatus: String {
    case paid
    case upcoming
    case overdue
    
    var displayName: String {
        switch self {
        case .paid: return "Paid"
        case .upcoming: return "Upcoming"
        case .overdue: return "Overdue"
        }
    }
    
    var icon: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .upcoming: return "clock"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Static Formatters (avoid recreating on every render)

private enum TimelineFormatters {
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

// MARK: - Payment Timeline View V1

struct PaymentTimelineViewV1: View {
    let windowSize: WindowSize
    let filteredPayments: [PaymentSchedule]
    let expenses: [Expense]
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var hoveredEventId: String?  // Use event ID instead of payment ID
    @State private var selectedPayment: PaymentSchedule?
    @State private var showingEditModal = false
    @State private var selectedMonthEvent: MonthEventSelection?
    
    private var isDarkMode: Bool { colorScheme == .dark }
    
    // MARK: - Computed Properties (cached via struct identity)
    
    /// Group payments by month for timeline positioning
    /// Note: This is computed but the result is stable (same input = same output)
    private var paymentsByMonth: [(month: Date, payments: [PaymentSchedule])] {
        let calendar = Calendar.current
        var grouped: [Date: [PaymentSchedule]] = [:]
        
        for payment in filteredPayments {
            if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: payment.paymentDate)) {
                grouped[monthStart, default: []].append(payment)
            }
        }
        
        return grouped.map { (month: $0.key, payments: $0.value) }
            .sorted { $0.month < $1.month }
    }
    
    /// Unique months for the timeline header
    private var timelineMonths: [Date] {
        paymentsByMonth.map { $0.month }
    }
    
    /// One aggregated event per month showing total payments
    /// Status is determined by: all paid = paid, any overdue = overdue, else upcoming
    private var eventsByMonth: [(month: Date, event: TimelineEvent)] {
        var result: [(month: Date, event: TimelineEvent)] = []
        
        for (index, monthData) in paymentsByMonth.enumerated() {
            let paidPayments = monthData.payments.filter { $0.paid }
            let unpaidPayments = monthData.payments.filter { !$0.paid }
            let overduePayments = unpaidPayments.filter { $0.paymentDate < Date() }
            
            // Determine overall status for the month
            let status: TimelinePaymentStatus
            if unpaidPayments.isEmpty {
                status = .paid  // All payments are paid
            } else if !overduePayments.isEmpty {
                status = .overdue  // Has overdue payments
            } else {
                status = .upcoming  // Has upcoming payments
            }
            
            // Calculate totals
            let totalAmount = monthData.payments.reduce(0) { $0 + $1.paymentAmount }
            let paidAmount = paidPayments.reduce(0) { $0 + $1.paymentAmount }
            
            let event = TimelineEvent(
                month: monthData.month,
                status: status,
                paymentCount: monthData.payments.count,
                totalAmount: totalAmount,
                paidAmount: paidAmount,
                payments: monthData.payments,
                position: index,
                isAboveLine: index % 2 == 0  // Alternate above/below for visual interest
            )
            
            result.append((month: monthData.month, event: event))
        }
        
        return result
    }
    
    // MARK: - Body
    
    var body: some View {
        if filteredPayments.isEmpty {
            emptyStateView
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                timelineContent
                    .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
                    .padding(.vertical, Spacing.md)
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
            .sheet(item: $selectedMonthEvent) { monthEvent in
                MonthlyPaymentDetailsViewV1(
                    month: monthEvent.month,
                    payments: monthEvent.payments,
                    expenses: expenses,
                    getVendorName: getVendorName,
                    userTimezone: userTimezone,
                    onUpdate: onUpdate,
                    onDelete: onDelete,
                    onDismiss: { selectedMonthEvent = nil }
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Payment Schedules",
            systemImage: "calendar.circle",
            description: Text("Add payment schedules to see them on the timeline")
        )
        .frame(minHeight: 400)
    }
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            // Glass panel container - timeline with month columns
            timelineHStackView
                .padding(.vertical, Spacing.lg)
                .background(timelineBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDarkMode ? 0.2 : 0.6),
                                    Color.white.opacity(isDarkMode ? 0.05 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
        }
    }
    
    private var timelineBackground: some View {
        ZStack {
            // Base blur layer
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(.ultraThinMaterial)
            
            // Semi-transparent overlay - more transparent for glassmorphism
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.15))
        }
    }
    
    // MARK: - Constants
    
    private let monthColumnWidth: CGFloat = 240  // Width for each month column
    
    // MARK: - Timeline Column-Based View
    
    /// Timeline with month columns - each month has one card
    private var timelineHStackView: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(eventsByMonth, id: \.month) { monthData in
                MonthColumn(
                    month: monthData.month,
                    event: monthData.event,
                    columnWidth: monthColumnWidth,
                    isDarkMode: isDarkMode,
                    isHovered: hoveredEventId == monthData.event.id,
                    userTimezone: userTimezone,
                    onEventTap: {
                        // Show monthly payment details view using sheet(item:) pattern
                        selectedMonthEvent = MonthEventSelection(
                            month: monthData.month,
                            payments: monthData.event.payments
                        )
                    },
                    onEventHover: { hovering in
                        hoveredEventId = hovering ? monthData.event.id : nil
                    }
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatMonth(_ date: Date) -> String {
        TimelineFormatters.monthFormatter.timeZone = userTimezone
        return TimelineFormatters.monthFormatter.string(from: date)
    }
}

// MARK: - Timeline Event Card Wrapper (handles arrow + card + hover)

private struct TimelineEventCardWrapper: View {
    let event: TimelineEvent
    let isHovered: Bool
    let isDarkMode: Bool
    let showArrowBelow: Bool  // true = arrow below card, false = arrow above card
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    private var arrowColor: Color {
        switch event.status {
        case .paid:
            return Color.fromHex("587C65").opacity(0.85)
        case .upcoming:
            return Color.fromHex("F3E3DB").opacity(0.9)
        case .overdue:
            return Color.fromHex("D15144").opacity(0.85)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !showArrowBelow {
                // Arrow pointing up (for cards below the line)
                Triangle()
                    .fill(arrowColor)
                    .frame(width: 16, height: 8)
                    .rotationEffect(.degrees(180))
            }
            
            TimelineEventCard(
                event: event,
                isHovered: isHovered,
                isDarkMode: isDarkMode,
                onTap: onTap
            )
            .onHover(perform: onHover)
            
            if showArrowBelow {
                // Arrow pointing down (for cards above the line)
                Triangle()
                    .fill(arrowColor)
                    .frame(width: 16, height: 8)
            }
        }
    }
}

// MARK: - Timeline Event Card

private struct TimelineEventCard: View {
    let event: TimelineEvent
    let isHovered: Bool
    let isDarkMode: Bool
    let onTap: () -> Void
    
    private var cardColors: (background: Color, text: Color, shadow: Color) {
        switch event.status {
        case .paid:
            return (
                Color.fromHex("587C65").opacity(0.85),
                .white,
                Color.fromHex("486B52").opacity(0.3)
            )
        case .upcoming:
            return (
                Color.fromHex("F3E3DB").opacity(0.9),
                Color.fromHex("333333"),
                Color.black.opacity(0.05)
            )
        case .overdue:
            return (
                Color.fromHex("D15144").opacity(0.85),
                .white,
                Color.fromHex("B93626").opacity(0.4)
            )
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            cardContent
                .frame(width: 220)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .offset(y: isHovered ? (event.isAboveLine ? -4 : 4) : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
    }
    
    private var cardContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Payment count
                Text(paymentCountText)
                    .font(.system(size: 11))
                    .foregroundColor(cardColors.text.opacity(0.8))
                
                // Amount and status
                HStack(spacing: Spacing.xs) {
                    if event.status == .paid {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(cardColors.text.opacity(0.8))
                    } else if event.status == .overdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(cardColors.text)
                    }
                    
                    Text(formatCurrency(event.totalAmount))
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(cardColors.text)
                    
                    Text(event.status.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(cardColors.text.opacity(0.9))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(cardColors.text.opacity(0.6))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(cardColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(event.status == .upcoming ? 0.6 : 0.2), lineWidth: 1)
                )
                .shadow(
                    color: cardColors.shadow,
                    radius: event.status == .overdue ? 12 : 6,
                    x: 0,
                    y: 3
                )
        )
    }
    
    private var paymentCountText: String {
        let count = event.paymentCount
        return "\(count) Payment\(count > 1 ? "s" : ""), Total"
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        TimelineFormatters.currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Month Column (contains header, single card, and track segment)

private struct MonthColumn: View {
    let month: Date
    let event: TimelineEvent  // Single event per month
    let columnWidth: CGFloat
    let isDarkMode: Bool
    let isHovered: Bool
    let userTimezone: TimeZone
    let onEventTap: () -> Void
    let onEventHover: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Month header
            Text(formatMonth(month))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isDarkMode ? .white.opacity(0.9) : SemanticColors.textPrimary)
                .frame(width: columnWidth)
                .padding(.bottom, Spacing.sm)
            
            // Card above the line (if isAboveLine)
            if event.isAboveLine {
                TimelineEventCardWrapper(
                    event: event,
                    isHovered: isHovered,
                    isDarkMode: isDarkMode,
                    showArrowBelow: true,
                    onTap: onEventTap,
                    onHover: onEventHover
                )
                .frame(height: 100, alignment: .bottom)
            } else {
                // Empty space for alignment
                Spacer()
                    .frame(height: 100)
            }
            
            // Timeline track segment with marker
            ZStack {
                // Track segment
                Rectangle()
                    .fill(trackColor)
                    .frame(height: 16)
                
                // Month marker dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .frame(width: columnWidth)
            .padding(.vertical, Spacing.sm)
            
            // Card below the line (if !isAboveLine)
            if !event.isAboveLine {
                TimelineEventCardWrapper(
                    event: event,
                    isHovered: isHovered,
                    isDarkMode: isDarkMode,
                    showArrowBelow: false,
                    onTap: onEventTap,
                    onHover: onEventHover
                )
                .frame(height: 100, alignment: .top)
            } else {
                // Empty space for alignment
                Spacer()
                    .frame(height: 100)
            }
        }
        .frame(width: columnWidth)
    }
    
    private var trackColor: Color {
        switch event.status {
        case .paid:
            return Color.fromHex("6D9E79")  // Green for paid
        case .upcoming:
            return Color.fromHex("E0CDA7")  // Cream for upcoming
        case .overdue:
            return Color.fromHex("D96C6C")  // Red for overdue
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        TimelineFormatters.monthFormatter.timeZone = userTimezone
        return TimelineFormatters.monthFormatter.string(from: date)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Light Mode - With Data") {
    PaymentTimelineViewV1(
        windowSize: .regular,
        filteredPayments: [],
        expenses: [],
        getVendorName: { _ in nil },
        userTimezone: .current,
        onUpdate: { _ in },
        onDelete: { _ in }
    )
    .preferredColorScheme(.light)
    .frame(width: 1200, height: 500)
}

#Preview("Dark Mode") {
    PaymentTimelineViewV1(
        windowSize: .regular,
        filteredPayments: [],
        expenses: [],
        getVendorName: { _ in nil },
        userTimezone: .current,
        onUpdate: { _ in },
        onDelete: { _ in }
    )
    .preferredColorScheme(.dark)
    .frame(width: 1200, height: 500)
}
