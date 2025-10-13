import SwiftUI

/// Modern pill-shaped navigation bar inspired by contemporary UI design
struct NavigationBarV2: View {
    @Binding var selectedTab: Int
    let items: [NavigationItem]

    @State private var hoveredTab: Int? = nil

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                NavigationPill(
                    item: item,
                    isSelected: selectedTab == index,
                    isHovered: hoveredTab == index,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                )
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveredTab = isHovered ? index : nil
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 50)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Navigation Pill Item

struct NavigationPill: View {
    let item: NavigationItem
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Icon circle
                Circle()
                    .fill(isSelected ? accentGradient : inactiveGradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSelected ? .black : .secondary)
                    )
                    .shadow(color: isSelected ? accentColor.opacity(0.4) : .clear, radius: 8, x: 0, y: 2)

                // Label (only show when selected)
                if isSelected {
                    Text(item.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, isSelected ? 16 : 0)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(NSColor.controlBackgroundColor) : Color.clear)
                    .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 8, x: 0, y: 2)
            )
            .scaleEffect(isHovered && !isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var accentColor: Color {
        // Use custom accent color based on item
        switch item.label {
        case "Dashboard": return .green
        case "Guests": return .blue
        case "Vendors": return .purple
        case "Budget": return .orange
        case "Tasks": return .pink
        case "Visual Planning": return .mint
        case "Timeline": return .indigo
        case "Notes": return .yellow
        case "Documents": return .cyan
        case "Settings": return .gray
        default: return .green
        }
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor, accentColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var inactiveGradient: LinearGradient {
        LinearGradient(
            colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Navigation Item Model

struct NavigationItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()

        NavigationBarV2(
            selectedTab: .constant(0),
            items: [
                NavigationItem(icon: "house.fill", label: "Dashboard"),
                NavigationItem(icon: "person.3.fill", label: "Guests"),
                NavigationItem(icon: "building.2.fill", label: "Vendors"),
                NavigationItem(icon: "dollarsign.circle.fill", label: "Budget"),
                NavigationItem(icon: "checklist", label: "Tasks"),
            ]
        )
        .padding()

        Spacer()
    }
    .frame(width: 1000, height: 600)
}
