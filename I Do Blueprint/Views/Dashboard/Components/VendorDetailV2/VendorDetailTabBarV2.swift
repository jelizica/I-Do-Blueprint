//
//  VendorDetailTabBarV2.swift
//  I Do Blueprint
//
//  Enhanced tab bar for vendor detail modal
//

import SwiftUI

struct VendorDetailTabBarV2: View {
    @Binding var selectedTab: Int

    private let tabs = [
        VendorTab(title: "Overview", icon: "info.circle.fill"),
        VendorTab(title: "Financial", icon: "dollarsign.circle.fill"),
        VendorTab(title: "Documents", icon: "doc.fill"),
        VendorTab(title: "Notes", icon: "note.text")
    ]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                VendorTabButtonV2(
                    title: tab.title,
                    icon: tab.icon,
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Supporting Types

private struct VendorTab {
    let title: String
    let icon: String
}

struct VendorTabButtonV2: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(Typography.bodyRegular)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : SemanticColors.textSecondary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(GlassTabButtonStyle(isSelected: isSelected))
        .accessibleActionButton(label: title, hint: "Shows \(title.lowercased()) tab")
    }
}
