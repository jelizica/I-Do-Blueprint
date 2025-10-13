//
//  VisualPlanningMainView.swift
//  My Wedding Planning App
//
//  Main visual planning navigation view
//

import SwiftUI

struct VisualPlanningMainView: View {
    @StateObject private var visualPlanningStore = VisualPlanningStoreV2()
    @State private var selectedTab: VisualPlanningTab = .moodBoards

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with gradient
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Visual Planning")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Create mood boards, color palettes, and plan your visual style")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // Stats Cards
                    HStack(spacing: 12) {
                        InteractiveStatCard(
                            title: "Mood Boards",
                            value: "\(visualPlanningStore.moodBoards.count)",
                            color: .blue,
                            icon: "photo.on.rectangle.angled") {
                            selectedTab = .moodBoards
                        }

                        InteractiveStatCard(
                            title: "Color Palettes",
                            value: "\(visualPlanningStore.colorPalettes.count)",
                            color: .purple,
                            icon: "paintpalette") {
                            selectedTab = .colorPalettes
                        }

                        InteractiveStatCard(
                            title: "Seating Charts",
                            value: "\(visualPlanningStore.seatingCharts.count)",
                            color: .green,
                            icon: "tablecells") {
                            selectedTab = .seatingChart
                        }

                        InteractiveStatCard(
                            title: "Style Guide",
                            value: "Active",
                            color: .orange,
                            icon: "star.square") {
                            selectedTab = .stylePreferences
                        }
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))

                // Tab Navigation
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(VisualPlanningTab.allCases, id: \.self) { tab in
                            TabButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                count: getTabCount(for: tab)) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Main Content
                Group {
                    switch selectedTab {
                    case .moodBoards:
                        MoodBoardListView()
                    case .colorPalettes:
                        ColorPaletteListView()
                    case .stylePreferences:
                        StylePreferencesView()
                    case .seatingChart:
                        SeatingChartView()
                    }
                }
                .environmentObject(visualPlanningStore)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .navigationTitle("")
        }
        .sheet(isPresented: $visualPlanningStore.showingMoodBoardCreator) {
            MoodBoardGeneratorView()
                .environmentObject(visualPlanningStore)
                .transition(.opacity.combined(with: .scale))
        }
        .sheet(isPresented: $visualPlanningStore.showingColorPaletteCreator) {
            ColorPaletteCreatorView()
                .environmentObject(visualPlanningStore)
                .transition(.opacity.combined(with: .scale))
        }
        .task {
            await visualPlanningStore.loadMoodBoards()
            await visualPlanningStore.loadColorPalettes()
            await visualPlanningStore.loadSeatingCharts()
        }
    }

    private func getTabCount(for tab: VisualPlanningTab) -> Int? {
        switch tab {
        case .moodBoards:
            visualPlanningStore.moodBoards.count
        case .colorPalettes:
            visualPlanningStore.colorPalettes.count
        case .seatingChart:
            visualPlanningStore.seatingCharts.count
        case .stylePreferences:
            nil
        }
    }
}

enum VisualPlanningTab: CaseIterable, Hashable {
    case moodBoards
    case colorPalettes
    case stylePreferences
    case seatingChart

    var title: String {
        switch self {
        case .moodBoards: "Mood Boards"
        case .colorPalettes: "Color Palettes"
        case .stylePreferences: "Style Guide"
        case .seatingChart: "Seating Chart"
        }
    }

    var subtitle: String {
        switch self {
        case .moodBoards: "Visual inspiration boards"
        case .colorPalettes: "Wedding color schemes"
        case .stylePreferences: "Define your style"
        case .seatingChart: "Plan seating arrangements"
        }
    }

    var iconName: String {
        switch self {
        case .moodBoards: "photo.on.rectangle.angled"
        case .colorPalettes: "paintpalette"
        case .stylePreferences: "star.square"
        case .seatingChart: "tablecells"
        }
    }

    var color: Color {
        switch self {
        case .moodBoards: .blue
        case .colorPalettes: .purple
        case .stylePreferences: .orange
        case .seatingChart: .green
        }
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
                Image(systemName: tab.iconName)
                    .font(.body)
                    .foregroundColor(isSelected ? tab.color : .secondary)

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

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 180)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: .black.opacity(isHovering && !isSelected ? 0.08 : 0.04),
                        radius: isHovering ? 6 : 3,
                        x: 0,
                        y: isHovering ? 3 : 2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? tab.color.opacity(0.3) : Color.clear, lineWidth: 2))
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Interactive Stat Card Component

struct InteractiveStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    Spacer()
                }

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: .black.opacity(isHovering ? 0.12 : 0.06),
                        radius: isHovering ? 8 : 3,
                        x: 0,
                        y: isHovering ? 4 : 2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isHovering ? 0.4 : 0.3), lineWidth: 1))
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Visual Planning Card Component (Reusable)

struct VisualPlanningCard<Content: View>: View {
    let content: Content
    let action: (() -> Void)?
    @State private var isHovering = false

    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var cardContent: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: .black.opacity(isHovering ? 0.12 : 0.06),
                        radius: isHovering ? 8 : 4,
                        x: 0,
                        y: isHovering ? 4 : 2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1))
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}

// MARK: - Skeleton Loader Component

struct SkeletonLoader: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .modifier(ShimmerModifier())
    }
}

struct SkeletonCardLoader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .modifier(ShimmerModifier())

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 16)
                .modifier(ShimmerModifier())

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 12)
                .modifier(ShimmerModifier())

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 12)
                .modifier(ShimmerModifier())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1))
    }
}

#Preview {
    VisualPlanningMainView()
        .frame(width: 1200, height: 800)
}
