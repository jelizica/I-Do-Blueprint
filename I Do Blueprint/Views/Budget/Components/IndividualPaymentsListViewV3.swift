//
//  IndividualPaymentsListViewV3.swift
//  I Do Blueprint
//
//  Individual payments list view following HTML reference design
//  Features month groupings, simplified row styling, and floating action button
//

import SwiftUI

struct IndividualPaymentsListViewV3: View {
    let windowSize: WindowSize
    let filteredPayments: [PaymentSchedule]
    let expenses: [Expense]
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    let onPaymentTap: (PaymentSchedule) -> Void
    var onPartialPayment: ((PaymentSchedule) -> Void)?
    let onAddPayment: () -> Void

    // Selection mode support
    @Binding var isSelectionMode: Bool
    @Binding var selectedPaymentIds: Set<Int64>
    let onBulkDelete: ([Int64]) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool { colorScheme == .dark }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            if filteredPayments.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedPayments, id: \.key) { group in
                            monthSection(title: group.key, payments: group.value)
                        }

                        // Bottom padding for floating button
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
                    .padding(.top, Spacing.md)
                }
            }

            // Floating Add Payment button
            floatingAddButton
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Payment Schedules",
            systemImage: "calendar.circle",
            description: Text("Add payment schedules to track upcoming payments and deadlines")
        )
        .frame(minHeight: 400)
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        Button(action: onAddPayment) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text("Add Payment")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(
                        isDarkMode
                            ? Color.white.opacity(0.9)
                            : Color.fromHex("1F2937").opacity(0.9)
                    )
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isDarkMode ? Color.black : Color.white)
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Month Section

    private func monthSection(title: String, payments: [PaymentSchedule]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sticky month header
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(SemanticColors.textTertiary)

                if isSelectionMode {
                    Spacer()

                    let monthPaymentIds = Set(payments.map { $0.id })
                    let allSelected = monthPaymentIds.isSubset(of: selectedPaymentIds)

                    Button(action: {
                        if allSelected {
                            selectedPaymentIds.subtract(monthPaymentIds)
                        } else {
                            selectedPaymentIds.formUnion(monthPaymentIds)
                        }
                    }) {
                        Text(allSelected ? "Deselect All" : "Select All")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(SemanticColors.primaryAction)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, 2)
            .background(
                isDarkMode
                    ? Color(NSColor.windowBackgroundColor).opacity(0.95)
                    : Color.white.opacity(0.95)
            )
            .background(.ultraThinMaterial)
            .overlay(
                Divider()
                    .foregroundColor(SemanticColors.borderLight.opacity(0.5)),
                alignment: .bottom
            )

            // Payment rows
            VStack(spacing: Spacing.sm) {
                ForEach(payments, id: \.id) { payment in
                    HStack(spacing: Spacing.sm) {
                        // Selection checkbox
                        if isSelectionMode {
                            Button(action: {
                                if selectedPaymentIds.contains(payment.id) {
                                    selectedPaymentIds.remove(payment.id)
                                } else {
                                    selectedPaymentIds.insert(payment.id)
                                }
                            }) {
                                Image(systemName: selectedPaymentIds.contains(payment.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedPaymentIds.contains(payment.id) ? SemanticColors.primaryAction : SemanticColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }

                        PaymentRowV3(
                            payment: payment,
                            expense: getExpenseForPayment(payment),
                            isDarkMode: isDarkMode,
                            onUpdate: onUpdate,
                            onDelete: onDelete,
                            getVendorName: getVendorName,
                            userTimezone: userTimezone,
                            isSelectionMode: isSelectionMode,
                            onPartialPayment: onPartialPayment,
                            onTap: {
                                if isSelectionMode {
                                    if selectedPaymentIds.contains(payment.id) {
                                        selectedPaymentIds.remove(payment.id)
                                    } else {
                                        selectedPaymentIds.insert(payment.id)
                                    }
                                } else {
                                    onPaymentTap(payment)
                                }
                            }
                        )
                    }
                }
            }

            // Section bottom spacing
            Spacer()
                .frame(height: Spacing.lg)
        }
    }

    // MARK: - Helpers

    private var groupedPayments: [(key: String, value: [PaymentSchedule])] {
        let grouped = Dictionary(grouping: filteredPayments) { payment in
            DateFormatting.formatDate(payment.paymentDate, format: "MMMM yyyy", timezone: userTimezone)
        }
        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.timeZone = userTimezone

            guard let firstDate = formatter.date(from: first.key),
                  let secondDate = formatter.date(from: second.key) else {
                return first.key < second.key
            }

            return firstDate < secondDate
        }
    }

    private func getExpenseForPayment(_ payment: PaymentSchedule) -> Expense? {
        expenses.first { $0.id == payment.expenseId }
    }
}

// MARK: - Payment Row V3

private struct PaymentRowV3: View {
    let payment: PaymentSchedule
    let expense: Expense?
    let isDarkMode: Bool
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    var isSelectionMode: Bool = false
    var onPartialPayment: ((PaymentSchedule) -> Void)?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Vendor icon (square with rounded corners, not circle)
                vendorIconView

                // Payment details
                VStack(alignment: .leading, spacing: 2) {
                    Text(vendorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.xs) {
                        Text(paymentDescription)
                            .font(.system(size: 11))
                            .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(isDarkMode ? .white.opacity(0.4) : SemanticColors.textTertiary)

                        Text("Due \(formattedDate)")
                            .font(.system(size: 11))
                            .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)
                    }
                }

                Spacer()

                // Amount and status
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .trailing, spacing: 2) {
                        // Amount display
                        if payment.isPartiallyPaid {
                            HStack(spacing: 4) {
                                Text("\(formattedAmountPaid)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.fromHex("F59E0B"))
                                Text("paid")
                                    .font(.system(size: 11))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textTertiary)
                            }
                            Text("of \(formattedAmount)")
                                .font(.system(size: 10))
                                .foregroundColor(isDarkMode ? .white.opacity(0.4) : SemanticColors.textTertiary)
                        } else {
                            Text(formattedAmount)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                        }

                        // Status badge
                        statusBadge
                    }

                    // Inline paid toggle button (visible without click-through)
                    Button(action: {
                        if payment.paid {
                            togglePaidStatus()
                        } else {
                            markAsPaidFull()
                        }
                    }) {
                        Image(systemName: payment.paid ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(payment.paid ? Color.fromHex("10B981") : Color.gray.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            ZStack {
                // Base blur layer
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.ultraThinMaterial)

                // Semi-transparent overlay
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.white.opacity(isDarkMode ? 0.08 : 0.25))

                // Inner glow
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.03 : 0.12),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 12)
        .contextMenu {
            if !payment.paid {
                Button(action: markAsPaidFull) {
                    Label("Mark as Paid (Full Amount)", systemImage: "checkmark.circle.fill")
                }

                if let partialHandler = onPartialPayment {
                    Button(action: { partialHandler(payment) }) {
                        Label("Make Partial Payment...", systemImage: "dollarsign.circle")
                    }
                }

                Divider()
            } else {
                Button(action: togglePaidStatus) {
                    Label("Mark as Unpaid", systemImage: "xmark.circle")
                }

                Divider()
            }

            Button(role: .destructive, action: { onDelete(payment) }) {
                Label("Delete Payment", systemImage: "trash")
            }
        }
    }

    // MARK: - Vendor Icon (Square style from HTML)

    private var vendorIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    isDarkMode
                        ? Color.white.opacity(0.05)
                        : Color.fromHex("F3F4F6")
                )
                .frame(width: 40, height: 40)

            Image(systemName: vendorTypeIcon)
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.textSecondary)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    isDarkMode ? Color.white.opacity(0.08) : SemanticColors.borderLight,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Text(statusText)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(statusTextColor)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(statusBackgroundColor)
            )
            .frame(width: 70)
    }

    // MARK: - Computed Properties

    private var vendorName: String {
        if let name = getVendorName(payment.vendorId), !name.isEmpty {
            return name
        }
        if !payment.vendor.isEmpty {
            return payment.vendor
        }
        return expense?.expenseName ?? "Unknown Vendor"
    }

    private var paymentDescription: String {
        if let order = payment.paymentOrder, let total = payment.totalPaymentCount {
            if payment.isDeposit && order == 1 {
                return "Deposit \(order) of \(total)"
            }
            return "Payment \(order) of \(total)"
        }
        if payment.isDeposit {
            return "Deposit"
        }
        if payment.isRetainer {
            return "Retainer"
        }
        if let notes = payment.notes, !notes.isEmpty {
            return notes
        }
        return "Payment"
    }

    private var formattedDate: String {
        DateFormatting.formatDate(payment.paymentDate, format: "MMM d, yyyy", timezone: userTimezone)
    }

    private var formattedAmount: String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: payment.paymentAmount)) ?? "$0"
    }

    private var formattedAmountPaid: String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: payment.amountPaid)) ?? "$0"
    }

    private var statusText: String {
        if payment.paid {
            return "Paid"
        } else if payment.isPartiallyPaid {
            return "Partial"
        } else if isOverdue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }

    private var isOverdue: Bool {
        !payment.paid && payment.paymentDate < Date()
    }

    private var statusBackgroundColor: Color {
        if payment.paid {
            return Color.fromHex("D1FAE5")
        } else if payment.isPartiallyPaid {
            return Color.fromHex("FEF3C7")
        } else if isOverdue {
            return Color.fromHex("FEE2E2")
        } else {
            return Color.fromHex("E0E7FF")
        }
    }

    private var statusTextColor: Color {
        if payment.paid {
            return Color.fromHex("047857")
        } else if payment.isPartiallyPaid {
            return Color.fromHex("B45309")
        } else if isOverdue {
            return Color.fromHex("DC2626")
        } else {
            return Color.fromHex("4338CA")
        }
    }

    private var vendorTypeIcon: String {
        guard let type = payment.vendorType?.lowercased() else {
            return "building.2"
        }

        switch type {
        case let t where t.contains("venue"):
            return "mappin.circle"
        case let t where t.contains("jewel"), let t where t.contains("ring"):
            return "diamond"
        case let t where t.contains("photo"):
            return "camera"
        case let t where t.contains("video"):
            return "video"
        case let t where t.contains("cater"), let t where t.contains("food"):
            return "fork.knife"
        case let t where t.contains("cake"), let t where t.contains("dessert"):
            return "birthday.cake"
        case let t where t.contains("music"), let t where t.contains("dj"), let t where t.contains("band"):
            return "music.note"
        case let t where t.contains("flor"), let t where t.contains("flower"):
            return "leaf"
        case let t where t.contains("dress"), let t where t.contains("attire"), let t where t.contains("bridal"):
            return "tshirt"
        case let t where t.contains("hair"), let t where t.contains("makeup"), let t where t.contains("beauty"):
            return "sparkles"
        case let t where t.contains("plan"), let t where t.contains("coordinator"):
            return "calendar.badge.clock"
        case let t where t.contains("officiant"), let t where t.contains("ceremony"):
            return "person"
        case let t where t.contains("transport"), let t where t.contains("limo"):
            return "car"
        case let t where t.contains("rental"), let t where t.contains("decor"):
            return "chair.lounge"
        case let t where t.contains("invitation"), let t where t.contains("stationery"):
            return "envelope"
        case let t where t.contains("hotel"), let t where t.contains("accommodation"):
            return "building.2.crop.circle"
        default:
            return "building.2"
        }
    }

    // MARK: - Actions

    private func markAsPaidFull() {
        var updatedPayment = payment
        updatedPayment.paid = true
        updatedPayment.amountPaid = payment.paymentAmount
        updatedPayment.paymentRecordedAt = Date()
        updatedPayment.updatedAt = Date()
        onUpdate(updatedPayment)
    }

    private func togglePaidStatus() {
        var updatedPayment = payment
        updatedPayment.paid.toggle()
        if !updatedPayment.paid {
            updatedPayment.amountPaid = 0
            updatedPayment.paymentRecordedAt = nil
        }
        updatedPayment.updatedAt = Date()
        onUpdate(updatedPayment)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    IndividualPaymentsListViewV3(
        windowSize: .regular,
        filteredPayments: [],
        expenses: [],
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in nil },
        userTimezone: .current,
        onPaymentTap: { _ in },
        onAddPayment: {},
        isSelectionMode: .constant(false),
        selectedPaymentIds: .constant([]),
        onBulkDelete: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    IndividualPaymentsListViewV3(
        windowSize: .regular,
        filteredPayments: [],
        expenses: [],
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in nil },
        userTimezone: .current,
        onPaymentTap: { _ in },
        onAddPayment: {},
        isSelectionMode: .constant(false),
        selectedPaymentIds: .constant([]),
        onBulkDelete: { _ in }
    )
    .preferredColorScheme(.dark)
}
