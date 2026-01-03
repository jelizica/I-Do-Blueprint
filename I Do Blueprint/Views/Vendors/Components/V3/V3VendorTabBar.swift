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
    
    /// Width threshold below which we show icon-only mode
    /// This prevents text wrapping to multiple lines
    private let iconOnlyThreshold: CGFloat = 500

    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                
                HStack(spacing: Spacing.sm) {
                    ForEach(VendorDetailTab.allCases) { tab in
                        V3TabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            badge: tab == .documents && documentCount > 0 ? documentCount : nil,
                            showIconOnly: geometry.size.width < iconOnlyThreshold
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
            .background(SemanticColors.backgroundSecondary)
        }
        .frame(height: 60) // Fixed height for tab bar
    }
}

// MARK: - Tab Button

private struct V3TabButton: View {
    let tab: VendorDetailTab
    let isSelected: Bool
    let badge: Int?
    let showIconOnly: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                    .font(.system(size: showIconOnly ? 18 : 14, weight: isSelected ? .semibold : .regular))

                if !showIconOnly {
                    Text(tab.title)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                }

                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(SemanticColors.primaryAction)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, showIconOnly ? Spacing.md : Spacing.md)
            .padding(.vertical, Spacing.sm)
            .foregroundColor(isSelected ? SemanticColors.primaryAction : SemanticColors.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? SemanticColors.primaryAction.opacity(Opacity.subtle) : (isHovering ? SemanticColors.backgroundSecondary : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? SemanticColors.primaryAction.opacity(Opacity.light) : Color.clear,
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
