//
//  VisualPlanningTabBar.swift
//  I Do Blueprint
//
//  Tab navigation bar for visual planning sections
//

import SwiftUI

struct VisualPlanningTabBar: View {
    @Binding var selectedTab: VisualPlanningTab
    let getTabCount: (VisualPlanningTab) -> Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VisualPlanningTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        count: getTabCount(tab)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Tab Button Component

struct TabButton: View {
    let tab: VisualPlanningTab
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                iconView
                
                textContent
                
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(minWidth: 180)
            .background(backgroundView)
            .overlay(borderView)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    // MARK: - Subviews
    
    private var iconView: some View {
        Image(systemName: tab.iconName)
            .font(.body)
            .foregroundColor(isSelected ? tab.color : .secondary)
    }
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(tab.title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            if let count {
                Text("\(count) \(count == 1 ? "item" : "items")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? tab.color.opacity(0.12) : Color(NSColor.controlBackgroundColor))
            .shadow(
                color: .black.opacity(isHovering && !isSelected ? 0.08 : 0.04),
                radius: isHovering ? 6 : 3,
                x: 0,
                y: isHovering ? 3 : 2
            )
    }
    
    private var borderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? tab.color.opacity(0.3) : Color.clear, lineWidth: 2)
    }
}

// MARK: - Preview

#Preview {
    VisualPlanningTabBar(
        selectedTab: .constant(.moodBoards),
        getTabCount: { tab in
            switch tab {
            case .moodBoards: 3
            case .colorPalettes: 5
            case .seatingChart: 2
            case .stylePreferences: nil
            }
        }
    )
    .frame(width: 800)
}
