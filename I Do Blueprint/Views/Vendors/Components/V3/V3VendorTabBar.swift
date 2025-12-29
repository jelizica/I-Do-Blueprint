//
//  V3VendorTabBar.swift
//  I Do Blueprint
//
//  Custom tab bar for V3 vendor detail view
//

import SwiftUI

struct V3VendorTabBar: View {
    @Binding var selectedTab: VendorDetailTab
    var documentCount: Int = 0

    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                ForEach(VendorDetailTab.allCases) { tab in
                    V3TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        badge: tab == .documents && documentCount > 0 ? documentCount : nil
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.md)
        .background(AppColors.cardBackground)
    }
}

// MARK: - Tab Button

private struct V3TabButton: View {
    let tab: VendorDetailTab
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                Text(tab.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(AppColors.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppColors.primary.opacity(0.1) : (isHovering ? AppColors.cardBackground : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? AppColors.primary.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityHint(tab.accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("Tab Bar") {
    struct PreviewWrapper: View {
        @State private var selectedTab: VendorDetailTab = .overview

        var body: some View {
            VStack(spacing: 0) {
                V3VendorTabBar(
                    selectedTab: $selectedTab,
                    documentCount: 3
                )

                Divider()

                Text("Selected: \(selectedTab.title)")
                    .padding()

                Spacer()
            }
            .frame(height: 200)
        }
    }

    return PreviewWrapper()
}
