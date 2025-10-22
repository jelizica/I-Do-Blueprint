import SwiftUI

/// A reusable quick actions toolbar for detail views
struct QuickActionsToolbar: View {
    private let logger = AppLogger.ui
    let actions: [QuickAction]

    var body: some View {
        HStack(spacing: Spacing.md) {
            ForEach(actions) { action in
                DetailQuickActionButton(action: action)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

/// Represents a single quick action
struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    init(icon: String, title: String, color: Color = AppColors.primary, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
}

/// Individual quick action button
private struct DetailQuickActionButton: View {
    let action: QuickAction
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            HapticFeedback.buttonTap()
            action.action()
        }) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: action.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(action.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(action.color.opacity(isHovering ? 0.2 : 0.1))
                    )
                    .scaleEffect(isHovering ? 1.1 : 1.0)

                Text(action.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(minWidth: 70)
        }
        .buttonStyle(.plain)
        .animation(AnimationPresets.hover, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .help(action.title)
        .accessibilityLabel(action.title)
        .accessibilityHint("Activate to \(action.title.lowercased())")
    }
}

#Preview {
    QuickActionsToolbar(actions: [
        QuickAction(icon: "phone.fill", title: "Call", color: .green) {
            // TODO: Implement action - print("Call action")
        },
        QuickAction(icon: "envelope.fill", title: "Email", color: .blue) {
            // TODO: Implement action - print("Email action")
        },
        QuickAction(icon: "calendar", title: "Schedule", color: .orange) {
            // TODO: Implement action - print("Schedule action")
        },
        QuickAction(icon: "square.and.arrow.up", title: "Share", color: .purple) {
            // TODO: Implement action - print("Share action")
        }
    ])
    .padding()
}
