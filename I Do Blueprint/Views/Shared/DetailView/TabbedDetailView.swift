import SwiftUI

/// A reusable tabbed detail view component that provides a clean tab interface for organizing detailed content
struct TabbedDetailView<Content: View>: View {
    let tabs: [DetailTab]
    @Binding var selectedTab: Int
    @ViewBuilder let content: (Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        DetailTabButton(
                            tab: tab,
                            isSelected: selectedTab == index,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = index
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
            .background(SemanticColors.backgroundSecondary)

            Divider()

            // Tab content
            TabView(selection: $selectedTab) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, _ in
                    content(index)
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
        }
    }
}

/// Represents a single tab in the tabbed detail view
struct DetailTab {
    let title: String
    let icon: String
    let badge: Int?

    init(title: String, icon: String, badge: Int? = nil) {
        self.title = title
        self.icon = icon
        self.badge = badge
    }
}

/// Individual tab button component
private struct DetailTabButton: View {
    let tab: DetailTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                Text(tab.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                if let badge = tab.badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(SemanticColors.textPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(SemanticColors.primaryAction)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .foregroundColor(isSelected ? SemanticColors.primaryAction : SemanticColors.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? SemanticColors.primaryAction.opacity(Opacity.subtle) : Color.clear)
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
        .accessibilityLabel(tab.title)
        .accessibilityHint("Switch to \(tab.title) tab")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab = 0

        var body: some View {
            TabbedDetailView(
                tabs: [
                    DetailTab(title: "Overview", icon: "info.circle"),
                    DetailTab(title: "Payments", icon: "dollarsign.circle", badge: 3),
                    DetailTab(title: "Documents", icon: "doc.text", badge: 5),
                    DetailTab(title: "Communications", icon: "bubble.left.and.bubble.right")
                ],
                selectedTab: $selectedTab
            ) { index in
                ScrollView {
                    VStack {
                        Text("Tab \(index) Content")
                            .font(.title)
                            .padding(Spacing.huge)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 600)
        }
    }

    return PreviewWrapper()
}
