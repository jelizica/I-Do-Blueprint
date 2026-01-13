//
//  LinkBillsItemRowView.swift
//  I Do Blueprint
//
//  Individual bill calculator row component for the Link Bills to Expense Modal
//  Features: Checkbox, bill details, item counts, guest count, tax info
//

import SwiftUI

// MARK: - Link Bills Item Row View

struct LinkBillsItemRowView: View {
    // MARK: - Properties

    let billCalculator: BillCalculator
    let isSelected: Bool
    let isLinked: Bool
    let onToggle: () -> Void

    // MARK: - State

    @State private var isHovered: Bool = false

    // MARK: - Computed Properties

    /// Count of per-person items
    private var perPersonCount: Int {
        billCalculator.items.filter { $0.type == .perPerson }.count
    }

    /// Count of service fee items
    private var serviceFeeCount: Int {
        billCalculator.items.filter { $0.type == .serviceFee }.count
    }

    /// Count of flat fee items
    private var flatFeeCount: Int {
        billCalculator.items.filter { $0.type == .flatFee }.count
    }

    /// Tax rate display string
    private var taxRateDisplay: String? {
        guard let rate = billCalculator.taxRate, rate > 0 else { return nil }
        return String(format: "%.1f%% tax", rate)
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Checkbox
            checkboxView

            // Main content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Top row: Name/vendor and amount/guests
                HStack(alignment: .top) {
                    // Left: Name and vendor/event
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Spacing.sm) {
                            Text(billCalculator.name)
                                .font(Typography.bodyRegular)
                                .fontWeight(.bold)
                                .foregroundColor(isLinked ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                                .lineLimit(1)

                            // Linked badge if already linked
                            if isLinked {
                                linkedBadge
                            }
                        }

                        // Vendor and event info
                        HStack(spacing: Spacing.xs) {
                            if let vendorName = billCalculator.vendorName {
                                Text(vendorName)
                                    .font(Typography.caption)
                                    .foregroundColor(SemanticColors.textSecondary)
                                    .lineLimit(1)
                            }

                            if billCalculator.vendorName != nil && billCalculator.eventName != nil {
                                Text("•")
                                    .font(Typography.caption)
                                    .foregroundColor(SemanticColors.textTertiary)
                            }

                            if let eventName = billCalculator.eventName {
                                Text(eventName)
                                    .font(Typography.caption)
                                    .foregroundColor(SemanticColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    // Right: Amount and guest count
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        Text(formatCurrency(billCalculator.grandTotal))
                            .font(Typography.heading)
                            .fontWeight(.bold)
                            .foregroundColor(isLinked ? SemanticColors.textTertiary : SemanticColors.textPrimary)

                        // Guest count badge
                        guestCountBadge
                    }
                }

                // Bottom row: Item type counts and tax
                HStack(spacing: Spacing.md) {
                    // Per-person items
                    if perPersonCount > 0 {
                        itemCountTag(
                            count: perPersonCount,
                            label: "per-person",
                            color: SoftLavender.shade500
                        )
                    }

                    // Service fees
                    if serviceFeeCount > 0 {
                        itemCountTag(
                            count: serviceFeeCount,
                            label: serviceFeeCount == 1 ? "service fee" : "service fees",
                            color: AppColors.info
                        )
                    }

                    // Flat fees
                    if flatFeeCount > 0 {
                        itemCountTag(
                            count: flatFeeCount,
                            label: flatFeeCount == 1 ? "flat fee" : "flat fees",
                            color: SageGreen.shade500
                        )
                    }

                    Spacer()

                    // Tax rate
                    if let taxDisplay = taxRateDisplay {
                        Text(taxDisplay)
                            .font(.system(size: 11))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }
                .padding(.top, Spacing.xxs)
            }
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .opacity(isLinked ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isLinked {
                onToggle()
            }
        }
        .onHover { hovering in
            if !isLinked {
                isHovered = hovering
            }
        }
    }

    // MARK: - Checkbox View

    private var checkboxView: some View {
        ZStack {
            if isLinked {
                // Already linked - show checkmark in success color
                RoundedRectangle(cornerRadius: 4)
                    .fill(SemanticColors.statusSuccess)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else if isSelected {
                // Selected checkbox
                RoundedRectangle(cornerRadius: 4)
                    .fill(SemanticColors.primaryAction)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                // Unselected checkbox
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isHovered ? SemanticColors.primaryAction : SemanticColors.borderLight, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SemanticColors.controlBackground)
                    )
            }
        }
        .frame(width: 20, height: 20)
        .padding(.top, 2)
    }

    // MARK: - Linked Badge

    private var linkedBadge: some View {
        Text("LINKED")
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(SemanticColors.statusSuccess)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 2)
            .background(SemanticColors.statusSuccess.opacity(Opacity.light))
            .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Guest Count Badge

    private var guestCountBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 10))
            Text("\(billCalculator.guestCount) guests")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(SoftLavender.shade700)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 2)
        .background(SoftLavender.shade100)
        .cornerRadius(CornerRadius.pill)
    }

    // MARK: - Item Count Tag

    private func itemCountTag(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(count) \(label)")
                .font(.system(size: 11))
        }
        .foregroundColor(SemanticColors.textTertiary)
    }

    // MARK: - Computed Styles

    private var backgroundColor: Color {
        if isSelected {
            return SemanticColors.primaryAction.opacity(Opacity.verySubtle)
        } else if isHovered && !isLinked {
            return SemanticColors.hover
        } else {
            return SemanticColors.backgroundTertiary
        }
    }

    private var borderColor: Color {
        if isSelected {
            return SemanticColors.primaryAction
        } else if isHovered && !isLinked {
            return SemanticColors.borderPrimaryLight
        } else if isLinked {
            return SemanticColors.statusSuccess.opacity(Opacity.light)
        } else {
            return SemanticColors.borderLight
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview("Link Bills Item Row") {
    VStack(spacing: Spacing.md) {
        // Normal state - unselected
        LinkBillsItemRowView(
            billCalculator: BillCalculator(
                id: UUID(),
                coupleId: UUID(),
                name: "Reception Dinner Menu",
                vendorId: nil,
                eventId: nil,
                taxInfoId: nil,
                guestCount: 150,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date(),
                vendorName: "Gourmet Catering Co.",
                eventName: "Wedding Reception",
                taxRate: 8.5,
                taxRegion: "CA",
                items: [
                    .makeTest(type: .perPerson, name: "Main Course", amount: 45.00),
                    .makeTest(type: .perPerson, name: "Appetizer", amount: 15.00),
                    .makeTest(type: .perPerson, name: "Dessert", amount: 12.00),
                    .makeTest(type: .serviceFee, name: "Service", amount: 500.00),
                    .makeTest(type: .serviceFee, name: "Setup", amount: 250.00),
                    .makeTest(type: .flatFee, name: "Rental", amount: 300.00)
                ]
            ),
            isSelected: false,
            isLinked: false,
            onToggle: {}
        )

        // Selected state
        LinkBillsItemRowView(
            billCalculator: BillCalculator(
                id: UUID(),
                coupleId: UUID(),
                name: "Cocktail Hour Appetizers",
                vendorId: nil,
                eventId: nil,
                taxInfoId: nil,
                guestCount: 150,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date(),
                vendorName: "Gourmet Catering Co.",
                eventName: "Cocktail Hour",
                taxRate: 8.5,
                taxRegion: "CA",
                items: [
                    .makeTest(type: .perPerson, name: "Appetizer 1", amount: 8.00),
                    .makeTest(type: .perPerson, name: "Appetizer 2", amount: 7.00),
                    .makeTest(type: .serviceFee, name: "Service", amount: 200.00)
                ]
            ),
            isSelected: true,
            isLinked: false,
            onToggle: {}
        )

        // Already linked state
        LinkBillsItemRowView(
            billCalculator: BillCalculator(
                id: UUID(),
                coupleId: UUID(),
                name: "Late Night Snacks",
                vendorId: nil,
                eventId: nil,
                taxInfoId: nil,
                guestCount: 100,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date(),
                vendorName: "Food Truck Express",
                eventName: "Wedding Reception",
                taxRate: 8.5,
                taxRegion: "CA",
                items: [
                    .makeTest(type: .perPerson, name: "Tacos", amount: 10.00),
                    .makeTest(type: .perPerson, name: "Sliders", amount: 8.00),
                    .makeTest(type: .flatFee, name: "Truck Fee", amount: 500.00)
                ]
            ),
            isSelected: false,
            isLinked: true,
            onToggle: {}
        )
    }
    .padding(Spacing.lg)
    .background(SemanticColors.backgroundSecondary)
    .frame(width: 520)
}
