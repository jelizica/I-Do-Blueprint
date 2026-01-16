//
//  IndividualPaymentsListViewV2.swift
//  I Do Blueprint
//
//  Premium individual payments list view with glass-panel design
//  Matches the HTML reference design with month groupings, status badges,
//  vendor type icons, and theme-aware styling
//

import SwiftUI

struct IndividualPaymentsListViewV2: View {
    let windowSize: WindowSize
    let filteredPayments: [PaymentSchedule]
    let expenses: [Expense]
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    let onPaymentTap: (PaymentSchedule) -> Void
    var onPartialPayment: ((PaymentSchedule) -> Void)? = nil  // Handler for partial payment modal

    // Selection mode support
    @Binding var isSelectionMode: Bool
    @Binding var selectedPaymentIds: Set<Int64>
    let onBulkDelete: ([Int64]) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if filteredPayments.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(groupedPayments, id: \.key) { group in
                        monthSection(title: group.key, payments: group.value)
                    }

                    // Bottom padding for scroll
                    Spacer()
                        .frame(height: Spacing.xxl)
                }
                .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
                .padding(.top, Spacing.md)
            }
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

    // MARK: - Month Section

    private func monthSection(title: String, payments: [PaymentSchedule]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Month header with select all option in selection mode
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(SemanticColors.textSecondary)

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
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SemanticColors.primaryAction)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, Spacing.xs)
            .padding(.top, Spacing.sm)

            // Payment cards
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
                                    .font(.system(size: 22))
                                    .foregroundColor(selectedPaymentIds.contains(payment.id) ? SemanticColors.primaryAction : SemanticColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }

                        PaymentCardV2(
                            payment: payment,
                            expense: getExpenseForPayment(payment),
                            windowSize: windowSize,
                            colorScheme: colorScheme,
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

// MARK: - Payment Card V2

private struct PaymentCardV2: View {
    let payment: PaymentSchedule
    let expense: Expense?
    let windowSize: WindowSize
    let colorScheme: ColorScheme
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    var isSelectionMode: Bool = false
    var onPartialPayment: ((PaymentSchedule) -> Void)? = nil
    let onTap: () -> Void

    @State private var isHovered = false

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Due soon indicator (yellow bar on left)
                if isDueSoon && !payment.paid {
                    dueSoonIndicator
                }

                // Vendor icon
                vendorIconView

                // Payment details
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(vendorName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color.fromHex("1F2937"))
                        .lineLimit(1)

                    HStack(spacing: Spacing.xs) {
                        Text(paymentDescription)
                            .font(.system(size: 13))
                            .foregroundColor(SemanticColors.textSecondary)

                        Circle()
                            .fill(SemanticColors.textTertiary)
                            .frame(width: 3, height: 3)

                        Text("Due \(formattedDate)")
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }

                Spacer()

                // Amount and status
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text(formattedAmount)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(isDarkMode ? .white : Color.fromHex("1F2937"))

                        statusBadge
                    }

                    // Status circle / checkbox
                    statusCircle

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }
            .padding(Spacing.md)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(cardBorderColor, lineWidth: 1)
            )
            .overlay(
                // Hover border effect
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        isHovered ? SemanticColors.primaryAction.opacity(0.1) : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .scaleEffect(isHovered ? 1.005 : 1.0)
            .offset(y: isHovered ? -2 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            if !payment.paid {
                // Mark as Paid (full amount) - primary action
                Button(action: markAsPaidFull) {
                    Label("Mark as Paid (Full Amount)", systemImage: "checkmark.circle.fill")
                }

                // Partial Payment option - opens modal for specific amount
                if let partialHandler = onPartialPayment {
                    Button(action: { partialHandler(payment) }) {
                        Label("Make Partial Payment...", systemImage: "dollarsign.circle")
                    }
                }

                Divider()
            } else {
                // Mark as unpaid
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

    // MARK: - Card Components

    private var dueSoonIndicator: some View {
        Rectangle()
            .fill(Color.fromHex("FBBF24")) // Yellow
            .frame(width: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .padding(.vertical, -Spacing.md)
            .padding(.leading, -Spacing.md)
    }

    private var vendorIconView: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 48, height: 48)

            Image(systemName: vendorTypeIcon)
                .font(.system(size: 20))
                .foregroundColor(iconForegroundColor)
        }
        .overlay(
            Circle()
                .stroke(iconBorderColor, lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(statusBackgroundColor)
            .foregroundColor(statusTextColor)
            .clipShape(Capsule())
    }

    private var statusCircle: some View {
        Button(action: {
            if payment.paid {
                togglePaidStatus() // Mark as unpaid
            } else {
                markAsPaidFull() // Mark as paid with full amount
            }
        }) {
            ZStack {
                Circle()
                    .fill(payment.paid ? AppColors.success : Color.clear)
                    .frame(width: 32, height: 32)

                Circle()
                    .stroke(
                        payment.paid ? AppColors.success : SemanticColors.textTertiary,
                        lineWidth: 2
                    )
                    .frame(width: 32, height: 32)

                if payment.paid {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .shadow(
            color: payment.paid ? AppColors.success.opacity(0.3) : Color.clear,
            radius: 4,
            x: 0,
            y: 2
        )
    }

    // MARK: - Styling

    private var cardBackground: some View {
        Group {
            if isDarkMode {
                Color.fromHex("374151").opacity(0.4)
            } else {
                Color.white.opacity(0.6)
            }
        }
        .background(.ultraThinMaterial)
    }

    private var cardBorderColor: Color {
        isDarkMode
            ? Color.white.opacity(0.05)
            : Color.white.opacity(0.6)
    }

    private var iconBackgroundColor: Color {
        let vendorTypeColor = vendorTypeColorScheme
        return isDarkMode
            ? vendorTypeColor.opacity(0.2)
            : vendorTypeColor.opacity(0.5)
    }

    private var iconForegroundColor: Color {
        let vendorTypeColor = vendorTypeColorScheme
        return isDarkMode
            ? vendorTypeColor.opacity(0.9)
            : vendorTypeColor
    }

    private var iconBorderColor: Color {
        vendorTypeColorScheme.opacity(0.2)
    }

    private var statusBackgroundColor: Color {
        if payment.paid {
            return isDarkMode
                ? AppColors.success.opacity(0.3)
                : AppColors.success.opacity(0.15)
        } else if isOverdue {
            return isDarkMode
                ? AppColors.error.opacity(0.3)
                : AppColors.error.opacity(0.15)
        } else if isDueSoon {
            return isDarkMode
                ? Color.fromHex("FBBF24").opacity(0.3)
                : Color.fromHex("FBBF24").opacity(0.15)
        } else {
            return isDarkMode
                ? SemanticColors.textSecondary.opacity(0.2)
                : SemanticColors.textSecondary.opacity(0.1)
        }
    }

    private var statusTextColor: Color {
        if payment.paid {
            return isDarkMode
                ? Color.fromHex("86EFAC") // Light green
                : Color.fromHex("15803D") // Dark green
        } else if isOverdue {
            return isDarkMode
                ? Color.fromHex("FCA5A5") // Light red
                : Color.fromHex("DC2626") // Dark red
        } else if isDueSoon {
            return isDarkMode
                ? Color.fromHex("FDE047") // Light yellow
                : Color.fromHex("A16207") // Dark yellow/amber
        } else {
            return SemanticColors.textSecondary
        }
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

    private var statusText: String {
        if payment.paid {
            return "Paid"
        } else if isOverdue {
            return "Overdue"
        } else if isDueSoon {
            return "Due Soon"
        } else {
            return "Upcoming"
        }
    }

    private var isOverdue: Bool {
        !payment.paid && payment.paymentDate < Date()
    }

    private var isDueSoon: Bool {
        guard !payment.paid && !isOverdue else { return false }
        let calendar = Calendar.current
        let daysUntilDue = calendar.dateComponents([.day], from: Date(), to: payment.paymentDate).day ?? 0
        return daysUntilDue <= 7
    }

    private var vendorTypeIcon: String {
        guard let type = payment.vendorType?.lowercased() else {
            return "building.2.fill"
        }

        switch type {
        case let t where t.contains("venue"):
            return "mappin.circle.fill"
        case let t where t.contains("photo"):
            return "camera.fill"
        case let t where t.contains("video"):
            return "video.fill"
        case let t where t.contains("cater"), let t where t.contains("food"):
            return "fork.knife"
        case let t where t.contains("cake"), let t where t.contains("dessert"):
            return "birthday.cake.fill"
        case let t where t.contains("music"), let t where t.contains("dj"), let t where t.contains("band"):
            return "music.note"
        case let t where t.contains("flor"), let t where t.contains("flower"):
            return "leaf.fill"
        case let t where t.contains("dress"), let t where t.contains("attire"), let t where t.contains("bridal"):
            return "tshirt.fill"
        case let t where t.contains("hair"), let t where t.contains("makeup"), let t where t.contains("beauty"):
            return "sparkles"
        case let t where t.contains("plan"), let t where t.contains("coordinator"):
            return "calendar.badge.clock"
        case let t where t.contains("officiant"), let t where t.contains("ceremony"):
            return "person.fill"
        case let t where t.contains("transport"), let t where t.contains("limo"):
            return "car.fill"
        case let t where t.contains("rental"), let t where t.contains("decor"):
            return "chair.lounge.fill"
        case let t where t.contains("invitation"), let t where t.contains("stationery"):
            return "envelope.fill"
        case let t where t.contains("jewel"), let t where t.contains("ring"):
            return "diamond.fill"
        case let t where t.contains("alter"):
            return "scissors"
        case let t where t.contains("airline"), let t where t.contains("travel"):
            return "airplane"
        default:
            return "building.2.fill"
        }
    }

    private var vendorTypeColorScheme: Color {
        guard let type = payment.vendorType?.lowercased() else {
            return SageGreen.shade500
        }

        switch type {
        case let t where t.contains("jewel"), let t where t.contains("ring"):
            return SageGreen.shade500
        case let t where t.contains("photo"):
            return BlushPink.shade500
        case let t where t.contains("video"):
            return SoftLavender.shade500
        case let t where t.contains("flor"), let t where t.contains("flower"):
            return SoftLavender.shade400
        case let t where t.contains("venue"):
            return Terracotta.shade500
        case let t where t.contains("cater"), let t where t.contains("food"):
            return Terracotta.shade400
        case let t where t.contains("cake"), let t where t.contains("dessert"):
            return BlushPink.shade400
        case let t where t.contains("plan"), let t where t.contains("coordinator"):
            return SageGreen.shade600
        case let t where t.contains("hair"), let t where t.contains("makeup"), let t where t.contains("beauty"):
            return BlushPink.shade600
        case let t where t.contains("dress"), let t where t.contains("attire"), let t where t.contains("bridal"):
            return SoftLavender.shade600
        case let t where t.contains("music"), let t where t.contains("dj"):
            return SoftLavender.shade500
        case let t where t.contains("invitation"), let t where t.contains("stationery"):
            return WarmGray.shade500
        default:
            return SageGreen.shade500
        }
    }

    // MARK: - Actions

    /// Mark as paid with full amount (sets amountPaid = paymentAmount)
    private func markAsPaidFull() {
        var updatedPayment = payment
        updatedPayment.paid = true
        updatedPayment.amountPaid = payment.paymentAmount
        updatedPayment.paymentRecordedAt = Date()
        updatedPayment.updatedAt = Date()
        onUpdate(updatedPayment)
    }

    /// Toggle paid status (for marking as unpaid)
    private func togglePaidStatus() {
        var updatedPayment = payment
        updatedPayment.paid.toggle()
        if !updatedPayment.paid {
            // Reset payment tracking when marking as unpaid
            updatedPayment.amountPaid = 0
            updatedPayment.paymentRecordedAt = nil
        }
        updatedPayment.updatedAt = Date()
        onUpdate(updatedPayment)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    IndividualPaymentsListViewV2(
        windowSize: .regular,
        filteredPayments: [],
        expenses: [],
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in nil },
        userTimezone: .current,
        onPaymentTap: { _ in },
        isSelectionMode: .constant(false),
        selectedPaymentIds: .constant([]),
        onBulkDelete: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    IndividualPaymentsListViewV2(
        windowSize: .regular,
        filteredPayments: [],
        expenses: [],
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in nil },
        userTimezone: .current,
        onPaymentTap: { _ in },
        isSelectionMode: .constant(false),
        selectedPaymentIds: .constant([]),
        onBulkDelete: { _ in }
    )
    .preferredColorScheme(.dark)
}
