//
//  StylePreferencesView.swift
//  My Wedding Planning App
//
//  Comprehensive style preferences and wedding aesthetic management
//

import SwiftUI

struct StylePreferencesView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @State private var stylePreferences: StylePreferences
    @State private var selectedSection: PreferencesSection = .overview
    @State private var showingStyleGuide = false
    @State private var showingColorAnalysis = false
    @State private var hasUnsavedChanges = false

    init() {
        _stylePreferences = State(initialValue: StylePreferences())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            HStack(spacing: 0) {
                // Left Navigation
                navigationSidebar

                Divider()

                // Main Content
                mainContentArea
            }
        }
        .onAppear {
            loadStylePreferences()
        }
        .sheet(isPresented: $showingStyleGuide) {
            StyleGuideView(stylePreferences: stylePreferences)
        }
        .sheet(isPresented: $showingColorAnalysis) {
            ColorAnalysisView(
                moodBoards: visualPlanningStore.moodBoards,
                colorPalettes: visualPlanningStore.colorPalettes)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Style Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Define your wedding aesthetic and style guidelines")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button("Style Guide") {
                    showingStyleGuide = true
                }
                .buttonStyle(.bordered)

                Button("Color Analysis") {
                    showingColorAnalysis = true
                }
                .buttonStyle(.bordered)

                if hasUnsavedChanges {
                    Button("Save Changes") {
                        saveStylePreferences()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }

    // MARK: - Navigation Sidebar

    private var navigationSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PreferencesSection.allCases, id: \.self) { section in
                Button(action: {
                    selectedSection = section
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: section.icon)
                            .font(.system(size: 16))
                            .foregroundColor(selectedSection == section ? .blue : .secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedSection == section ? .blue : .primary)

                            Text(section.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if section.completionPercentage(stylePreferences) > 0 {
                            CircularProgressView(
                                progress: section.completionPercentage(stylePreferences),
                                size: 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(selectedSection == section ? Color.blue.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)

                if section != PreferencesSection.allCases.last {
                    Divider()
                        .padding(.leading, 48)
                }
            }

            Spacer()

            // Overall progress
            VStack(alignment: .leading, spacing: 8) {
                Divider()

                HStack {
                    Text("Overall Progress")
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(overallProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                ProgressView(value: overallProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .padding(16)
        }
        .frame(width: 280)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Main Content Area

    private var mainContentArea: some View {
        Group {
            switch selectedSection {
            case .overview:
                overviewSection
            case .colors:
                colorsSection
            case .style:
                styleSection
            case .themes:
                themesSection
            case .inspiration:
                inspirationSection
            case .guidelines:
                guidelinesSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Quick Stats
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    StatsCard(
                        title: "Style Category",
                        value: stylePreferences.primaryStyle?.displayName ?? "Not Set",
                        icon: "star.square",
                        color: .orange)

                    StatsCard(
                        title: "Color Palettes",
                        value: "\(visualPlanningStore.colorPalettes.count)",
                        icon: "paintpalette",
                        color: .purple)

                    StatsCard(
                        title: "Mood Boards",
                        value: "\(visualPlanningStore.moodBoards.count)",
                        icon: "photo.on.rectangle.angled",
                        color: .blue)
                }

                // Current Style Overview
                if let primaryStyle = stylePreferences.primaryStyle {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Wedding Style")
                            .font(.headline)

                        StyleOverviewCard(
                            style: primaryStyle,
                            preferences: stylePreferences)
                    }
                }

                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)

                    if visualPlanningStore.moodBoards.isEmpty, visualPlanningStore.colorPalettes.isEmpty {
                        Text("No visual planning content yet. Start by creating a mood board or color palette.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentActivity, id: \.id) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        QuickActionCard(
                            title: "Define Style",
                            description: "Set your primary wedding style",
                            icon: "star.square",
                            action: { selectedSection = .style })

                        QuickActionCard(
                            title: "Choose Colors",
                            description: "Select your color scheme",
                            icon: "paintpalette",
                            action: { selectedSection = .colors })

                        QuickActionCard(
                            title: "Set Themes",
                            description: "Define visual themes",
                            icon: "sparkles",
                            action: { selectedSection = .themes })

                        QuickActionCard(
                            title: "Style Guide",
                            description: "Generate style guide",
                            icon: "doc.text",
                            action: { showingStyleGuide = true })
                    }
                }
            }
        }
    }

    // MARK: - Colors Section

    private var colorsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Primary Colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Colors")
                        .font(.headline)

                    if stylePreferences.primaryColors.isEmpty {
                        EmptyStateView(
                            icon: "paintpalette",
                            title: "No Primary Colors Set",
                            description: "Choose 2-4 primary colors that will define your wedding palette",
                            actionTitle: "Choose Colors",
                            action: choosePrimaryColors)
                    } else {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ForEach(Array(stylePreferences.primaryColors.enumerated()), id: \.offset) { _, color in
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black.opacity(0.1), lineWidth: 1))

                                        Text(color.hexString)
                                            .font(.system(.caption2, design: .monospaced))
                                    }
                                }

                                Button("+") {
                                    choosePrimaryColors()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .disabled(stylePreferences.primaryColors.count >= 4)
                            }

                            Button("Choose Different Colors") {
                                choosePrimaryColors()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Color Harmony
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Harmony")
                        .font(.headline)

                    if let harmony = stylePreferences.colorHarmony {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(harmony.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(harmony.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(ColorHarmonyType.allCases, id: \.self) { harmony in
                                Button(action: {
                                    stylePreferences.colorHarmony = harmony
                                    markUnsavedChanges()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(harmony.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)

                                            Text(harmony.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Seasonal Considerations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Seasonal Colors")
                        .font(.headline)

                    if let season = stylePreferences.season {
                        SeasonalColorSuggestions(season: season)
                    } else {
                        Text("Set your wedding season to get seasonal color suggestions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Style Section

    private var styleSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                primaryStyleSection
                styleInfluencesSection
                formalityLevelSection
            }
        }
    }

    private var primaryStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary Style")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(StyleCategory.allCases, id: \.self) { style in
                    StyleCategoryCard(
                        style: style,
                        isSelected: stylePreferences.primaryStyle == style) {
                        stylePreferences.primaryStyle = style
                        markUnsavedChanges()
                    }
                }
            }
        }
    }

    private var styleInfluencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style Influences")
                .font(.headline)

            Text("What additional styles influence your wedding vision?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(StyleCategory.allCases.filter { $0 != stylePreferences.primaryStyle }, id: \.self) { style in
                    StyleInfluenceToggle(
                        style: style,
                        isSelected: stylePreferences.styleInfluences.contains(style)) {
                        if stylePreferences.styleInfluences.contains(style) {
                            stylePreferences.styleInfluences.removeAll { $0 == style }
                        } else {
                            stylePreferences.styleInfluences.append(style)
                        }
                        markUnsavedChanges()
                    }
                }
            }
        }
    }

    private var formalityLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Formality Level")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(FormalityLevel.allCases.enumerated()), id: \.offset) { _, level in
                    formalityLevelButton(for: level)
                }
            }
        }
    }

    private func formalityLevelButton(for level: FormalityLevel) -> some View {
        Button(action: {
            stylePreferences.formalityLevel = level
            markUnsavedChanges()
        }) {
            HStack {
                Circle()
                    .fill(stylePreferences.formalityLevel == level ? Color.blue : Color.clear)
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()
            }
            .padding()
            .background(stylePreferences.formalityLevel == level ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Supporting computed properties and methods

    private var overallProgress: Double {
        let sections = PreferencesSection.allCases
        let totalProgress = sections.reduce(0.0) { $0 + $1.completionPercentage(stylePreferences) }
        return totalProgress / Double(sections.count)
    }

    private var recentActivity: [StyleActivity] {
        var activities: [StyleActivity] = []

        // Add recent mood boards
        for moodBoard in visualPlanningStore.moodBoards.prefix(3) {
            activities.append(StyleActivity(
                type: .moodBoardCreated,
                title: "Created mood board: \(moodBoard.boardName)",
                date: moodBoard.createdAt))
        }

        // Add recent color palettes
        for palette in visualPlanningStore.colorPalettes.prefix(2) {
            activities.append(StyleActivity(
                type: .colorPaletteCreated,
                title: "Created color palette: \(palette.name)",
                date: palette.createdAt))
        }

        return activities.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }

    private func loadStylePreferences() {
        if let existingPreferences = visualPlanningStore.stylePreferences {
            stylePreferences = existingPreferences
        }
    }

    private func saveStylePreferences() {
        visualPlanningStore.stylePreferences = stylePreferences
        hasUnsavedChanges = false
    }

    private func markUnsavedChanges() {
        hasUnsavedChanges = true
    }

    private func choosePrimaryColors() {
        // TODO: Implement color picker interface
    }

    // Placeholder sections - these would be fully implemented
    private var themesSection: some View {
        Text("Themes section coming soon")
            .font(.headline)
            .foregroundColor(.secondary)
    }

    private var inspirationSection: some View {
        Text("Inspiration section coming soon")
            .font(.headline)
            .foregroundColor(.secondary)
    }

    private var guidelinesSection: some View {
        Text("Guidelines section coming soon")
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

#Preview {
    StylePreferencesView()
        .environmentObject(VisualPlanningStoreV2())
        .frame(width: 1000, height: 700)
}
