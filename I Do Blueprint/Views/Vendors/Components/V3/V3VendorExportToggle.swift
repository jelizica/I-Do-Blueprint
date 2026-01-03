//
//  V3VendorExportToggle.swift
//  I Do Blueprint
//
//  Export settings toggle for V3 vendor detail view
//

import SwiftUI

struct V3VendorExportToggle: View {
    let vendor: Vendor
    let onToggle: (Bool) async -> Void

    @State private var isToggling = false
    @State private var localValue: Bool

    init(vendor: Vendor, onToggle: @escaping (Bool) async -> Void) {
        self.vendor = vendor
        self.onToggle = onToggle
        _localValue = State(initialValue: vendor.includeInExport)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Export Settings",
                icon: "square.and.arrow.up.circle.fill",
                color: SemanticColors.primaryAction
            )

            HStack(spacing: Spacing.lg) {
                // Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(localValue ? SemanticColors.statusSuccess : SemanticColors.textSecondary.opacity(Opacity.light))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill((localValue ? SemanticColors.statusSuccess : SemanticColors.textSecondary).opacity(Opacity.light))
                    )

                // Text
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Include in Contact List Export")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(localValue
                        ? "This vendor will be included when you export contact lists"
                        : "This vendor will not be included in exported contact lists")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                // Toggle
                if isToggling {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Toggle("", isOn: $localValue)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: localValue) { _, newValue in
                            Task {
                                isToggling = true
                                await onToggle(newValue)
                                isToggling = false
                            }
                        }
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(SemanticColors.backgroundSecondary)
                    .shadow(color: SemanticColors.shadowLight, radius: 3, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .strokeBorder(
                        localValue ? SemanticColors.statusSuccess.opacity(Opacity.light) : SemanticColors.borderPrimary,
                        lineWidth: localValue ? 2 : 1
                    )
            )

            // Helper text
            HStack(spacing: Spacing.xs) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(SemanticColors.primaryAction)

                Text("Use the Export button in the vendor list to create CSV, PDF, or Google Sheets contact lists")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(.horizontal, Spacing.sm)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Include in contact list export: \(localValue ? "enabled" : "disabled")")
        .accessibilityHint("Toggle to include or exclude this vendor from exports")
    }
}

// MARK: - Preview

#Preview("Export Toggle - Enabled") {
    V3VendorExportToggle(
        vendor: .makeTest(includeInExport: true),
        onToggle: { _ in }
    )
    .padding()
    .background(SemanticColors.backgroundPrimary)
}

#Preview("Export Toggle - Disabled") {
    V3VendorExportToggle(
        vendor: .makeTest(includeInExport: false),
        onToggle: { _ in }
    )
    .padding()
    .background(SemanticColors.backgroundPrimary)
}
