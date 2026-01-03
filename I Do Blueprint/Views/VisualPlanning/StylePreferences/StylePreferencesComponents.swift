//
//  StylePreferencesComponents.swift
//  My Wedding Planning App
//
//  Supporting UI components for style preferences interface
//

import SwiftUI

// MARK: - Stats Card

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Style Overview Card

struct StyleOverviewCard: View {
    let style: StyleCategory
    let preferences: StylePreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: style.icon)
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(style.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Color palette preview
            if !preferences.primaryColors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Colors")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(preferences.primaryColors.prefix(4), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(SemanticColors.textPrimary.opacity(Opacity.subtle), lineWidth: 1))
                        }
                    }
                }
            }

            // Style influences
            if !preferences.styleInfluences.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Style Influences")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(preferences.styleInfluences, id: \.self) { influence in
                                Text(influence.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, Spacing.xxs)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: StyleActivity

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)

                Text(activity.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: activity.type.icon)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(SemanticColors.textSecondary.opacity(Opacity.verySubtle))
        .cornerRadius(12)
    }
}

// MARK: - Style Category Card

struct StyleCategoryCard: View {
    let style: StyleCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .blue)

                VStack(spacing: 4) {
                    Text(style.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(style.displayName)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                // Color palette preview
                HStack(spacing: 4) {
                    ForEach(style.suggestedColors.prefix(4), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? SemanticColors.textPrimary.opacity(Opacity.light) : SemanticColors.textPrimary.opacity(Opacity.subtle),
                                    lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Style Influence Toggle

struct StyleInfluenceToggle: View {
    let style: StyleCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(style.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Seasonal Color Suggestions

struct SeasonalColorSuggestions: View {
    let season: WeddingSeason

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Seasonal Colors for \(season.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }

            Text(season.displayName)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(season.colors, id: \.self) { color in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(SemanticColors.textPrimary.opacity(Opacity.subtle), lineWidth: 1))

                        Text(color.hexString)
                            .font(.system(.caption2, design: .monospaced))
                    }
                }
            }
        }
        .padding()
        .background(season.colors.first?.opacity(Opacity.subtle) ?? SemanticColors.textSecondary.opacity(Opacity.subtle))
        .cornerRadius(12)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Style Guide Views

struct StyleGuideView: View {
    let stylePreferences: StylePreferences

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Style overview
                    if let primaryStyle = stylePreferences.primaryStyle {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Wedding Style")
                                .font(.title2)
                                .fontWeight(.semibold)

                            StyleOverviewCard(style: primaryStyle, preferences: stylePreferences)
                        }
                    }

                    // Color guidelines
                    if !stylePreferences.primaryColors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color Guidelines")
                                .font(.title2)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Primary Colors")
                                    .font(.headline)

                                HStack(spacing: 12) {
                                    ForEach(stylePreferences.primaryColors, id: \.self) { color in
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 60, height: 60)

                                            Text(color.hexString)
                                                .font(.system(.caption, design: .monospaced))
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(SemanticColors.textSecondary.opacity(Opacity.verySubtle))
                            .cornerRadius(12)
                        }
                    }

                    // Guidelines
                    if let guidelines = stylePreferences.guidelines {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Style Guidelines")
                                .font(.title2)
                                .fontWeight(.semibold)

                            if !guidelines.doElements.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Do Include")
                                        .font(.headline)
                                        .foregroundColor(.green)

                                    ForEach(guidelines.doElements, id: \.self) { element in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text(element)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(12)
                            }

                            if !guidelines.avoidElements.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Avoid")
                                        .font(.headline)
                                        .foregroundColor(.red)

                                    ForEach(guidelines.avoidElements, id: \.self) { element in
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                            Text(element)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Style Guide")
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Color Analysis View

struct ColorAnalysisView: View {
    let moodBoards: [MoodBoard]
    let colorPalettes: [ColorPalette]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Color Analysis")
                        .font(.title2)
                        .fontWeight(.semibold)

                    // Extracted colors from mood boards
                    if !moodBoards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Colors from Mood Boards")
                                .font(.headline)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                                ForEach(extractedColors, id: \.self) { color in
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 40, height: 40)

                                        Text(color.hexString)
                                            .font(.system(.caption2, design: .monospaced))
                                    }
                                }
                            }
                        }
                    }

                    // Color palette analysis
                    if !colorPalettes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color Palette Analysis")
                                .font(.headline)

                            ForEach(colorPalettes) { palette in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(palette.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    HStack(spacing: 8) {
                                        ForEach(palette.colors.prefix(4), id: \.self) { hexColor in
                                            Circle()
                                                .fill(Color.fromHexString(hexColor) ?? .gray)
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                }
                                .padding()
                                .background(SemanticColors.textSecondary.opacity(Opacity.verySubtle))
                                .cornerRadius(8)
                            }
                        }
                    }

                    if moodBoards.isEmpty, colorPalettes.isEmpty {
                        EmptyStateView(
                            icon: "paintpalette",
                            title: "No Color Data",
                            description: "Create mood boards and color palettes to see color analysis",
                            actionTitle: "Create Mood Board",
                            action: {})
                    }
                }
                .padding()
            }
            .navigationTitle("Color Analysis")
        }
        .frame(width: 600, height: 500)
    }

    private var extractedColors: [Color] {
        // Extract dominant colors from mood board elements
        var colors: [Color] = []

        for moodBoard in moodBoards {
            for element in moodBoard.elements {
                if let color = element.elementData.color {
                    colors.append(color)
                }
            }
        }

        return Array(Set(colors)).prefix(12).map { $0 }
    }
}
