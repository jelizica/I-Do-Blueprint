//
//  BillCalculatorItemRows.swift
//  I Do Blueprint
//
//  Row components for different bill calculator item types
//

import SwiftUI

// MARK: - Per-Person Item Row

struct PerPersonItemRow: View {
    @Binding var item: BillLineItem
    let guestCount: Int
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            dragHandle

            HStack(spacing: Spacing.md) {
                nameField
                    .frame(maxWidth: .infinity, alignment: .leading)

                priceField
                    .frame(width: 120)

                Text("x")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textTertiary)

                Text("\(guestCount) guests")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 80)

                Text(formatCurrency(item.perPersonTotal(guestCount: guestCount)))
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .frame(width: 100, alignment: .trailing)
            }

            deleteButton
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovered ? SemanticColors.primaryAction : SemanticColors.borderPrimary, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(Typography.caption)
            .foregroundColor(SemanticColors.textTertiary)
            .frame(width: Spacing.xl)
    }

    private var nameField: some View {
        TextField("Item name...", text: $item.name)
            .textFieldStyle(.plain)
            .font(Typography.bodyRegular.weight(.medium))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(SemanticColors.controlBackground)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(SemanticColors.borderPrimary, lineWidth: 1)
            )
    }

    private var priceField: some View {
        HStack(spacing: 0) {
            Text("$")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textTertiary)
                .padding(.leading, Spacing.sm)

            TextField("0.00", value: $item.amount, format: .number.precision(.fractionLength(2)))
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular.weight(.semibold))
                .multilineTextAlignment(.leading)
                .padding(.trailing, Spacing.sm)
                .padding(.vertical, Spacing.xs)
        }
        .background(SemanticColors.controlBackground)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
        )
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Service Fee Item Row

struct ServiceFeeItemRow: View {
    @Binding var item: BillLineItem
    let subtotal: Double
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            dragHandle

            HStack(spacing: Spacing.md) {
                nameField
                    .frame(maxWidth: .infinity, alignment: .leading)

                percentageField
                    .frame(width: 100)

                Text("of \(formatCurrency(subtotal))")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 120)

                Text(formatCurrency(item.serviceFeeTotal(subtotal: subtotal)))
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .frame(width: 100, alignment: .trailing)
            }

            deleteButton
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovered ? SemanticColors.primaryAction : SemanticColors.borderPrimary, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(Typography.caption)
            .foregroundColor(SemanticColors.textTertiary)
            .frame(width: Spacing.xl)
    }

    private var nameField: some View {
        TextField("Fee name...", text: $item.name)
            .textFieldStyle(.plain)
            .font(Typography.bodyRegular.weight(.medium))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(SemanticColors.controlBackground)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(SemanticColors.borderPrimary, lineWidth: 1)
            )
    }

    private var percentageField: some View {
        HStack(spacing: 0) {
            TextField("0", value: $item.amount, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .padding(.leading, Spacing.sm)
                .padding(.vertical, Spacing.xs)

            Text("%")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textTertiary)
                .padding(.trailing, Spacing.sm)
        }
        .background(SemanticColors.controlBackground)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
        )
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Flat Fee Item Row

struct FlatFeeItemRow: View {
    @Binding var item: BillLineItem
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            dragHandle

            HStack(spacing: Spacing.md) {
                nameField
                    .frame(maxWidth: .infinity, alignment: .leading)

                priceField
                    .frame(width: 140)

                Text(formatCurrency(item.flatFeeTotal))
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .frame(width: 100, alignment: .trailing)
            }

            deleteButton
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovered ? SemanticColors.primaryAction : SemanticColors.borderPrimary, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(Typography.caption)
            .foregroundColor(SemanticColors.textTertiary)
            .frame(width: Spacing.xl)
    }

    private var nameField: some View {
        TextField("Item name...", text: $item.name)
            .textFieldStyle(.plain)
            .font(Typography.bodyRegular.weight(.medium))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(SemanticColors.controlBackground)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(SemanticColors.borderPrimary, lineWidth: 1)
            )
    }

    private var priceField: some View {
        HStack(spacing: 0) {
            Text("$")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textTertiary)
                .padding(.leading, Spacing.sm)

            TextField("0.00", value: $item.amount, format: .number.precision(.fractionLength(2)))
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular.weight(.semibold))
                .multilineTextAlignment(.leading)
                .padding(.trailing, Spacing.sm)
                .padding(.vertical, Spacing.xs)
        }
        .background(SemanticColors.controlBackground)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
        )
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Variable Item Row (Per-Item with custom quantity)

/// Row component for variable item count mode where each item has its own quantity
struct VariableItemRow: View {
    @Binding var item: BillLineItem
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            dragHandle

            HStack(spacing: Spacing.md) {
                nameField
                    .frame(maxWidth: .infinity, alignment: .leading)

                priceField
                    .frame(width: 120)

                Text("x")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textTertiary)

                quantityField
                    .frame(width: 80)

                Text(formatCurrency(item.variableItemTotal))
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .frame(width: 100, alignment: .trailing)
            }

            deleteButton
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovered ? SemanticColors.primaryAction : SemanticColors.borderPrimary, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(Typography.caption)
            .foregroundColor(SemanticColors.textTertiary)
            .frame(width: Spacing.xl)
    }

    private var nameField: some View {
        TextField("Item name...", text: $item.name)
            .textFieldStyle(.plain)
            .font(Typography.bodyRegular.weight(.medium))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(SemanticColors.controlBackground)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(SemanticColors.borderPrimary, lineWidth: 1)
            )
    }

    private var priceField: some View {
        HStack(spacing: 0) {
            Text("$")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textTertiary)
                .padding(.leading, Spacing.sm)

            TextField("0.00", value: $item.amount, format: .number.precision(.fractionLength(2)))
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular.weight(.semibold))
                .multilineTextAlignment(.leading)
                .padding(.trailing, Spacing.sm)
                .padding(.vertical, Spacing.xs)
        }
        .background(SemanticColors.controlBackground)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
        )
    }

    private var quantityField: some View {
        HStack(spacing: Spacing.xxs) {
            Button(action: {
                if item.quantity > 1 {
                    item.quantity -= 1
                }
            }) {
                Image(systemName: "minus")
                    .font(Typography.caption2.weight(.bold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: Spacing.lg, height: Spacing.lg)
            }
            .buttonStyle(.plain)
            .disabled(item.quantity <= 1)
            .opacity(item.quantity <= 1 ? 0.4 : 1)

            TextField("1", value: $item.quantity, format: .number)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(width: 36)

            Button(action: {
                item.quantity += 1
            }) {
                Image(systemName: "plus")
                    .font(Typography.caption2.weight(.bold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: Spacing.lg, height: Spacing.lg)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xs)
        .background(SemanticColors.controlBackground)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
        )
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
