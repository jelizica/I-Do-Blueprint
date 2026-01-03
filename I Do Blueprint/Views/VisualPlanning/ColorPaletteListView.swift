//
//  ColorPaletteListView.swift
//  My Wedding Planning App
//
//  List view for color palettes
//

import SwiftUI

struct ColorPaletteListView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @State private var searchText = ""
    @State private var selectedStyleFilter: StyleCategory?
    @State private var selectedHarmonyFilter: ColorHarmonyType?
    @State private var sortOption: ColorPaletteSortOption = .dateCreated
    @State private var selectedPalette: ColorPalette?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Color Palettes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("\(filteredPalettes.count) color palette\(filteredPalettes.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Style Filter
                    Menu {
                        Button("All Styles") {
                            selectedStyleFilter = nil
                        }
                        Divider()
                        ForEach(StyleCategory.allCases, id: \.self) { style in
                            Button(style.displayName) {
                                selectedStyleFilter = style
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paintbrush")
                            Text(selectedStyleFilter?.displayName ?? "All Styles")
                        }
                        .foregroundColor(.secondary)
                    }

                    // Harmony Filter
                    Menu {
                        Button("All Harmonies") {
                            selectedHarmonyFilter = nil
                        }
                        Divider()
                        ForEach(ColorHarmonyType.allCases, id: \.self) { harmony in
                            Button(harmony.displayName) {
                                selectedHarmonyFilter = harmony
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "circle.hexagongrid")
                            Text(selectedHarmonyFilter?.displayName ?? "All Harmonies")
                        }
                        .foregroundColor(.secondary)
                    }

                    // Sort Menu
                    Menu {
                        ForEach(ColorPaletteSortOption.allCases, id: \.self) { option in
                            Button(option.displayName) {
                                sortOption = option
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.displayName)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Create Button
                    Button(action: {
                        visualPlanningStore.showingColorPaletteCreator = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Palette")
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.purple)
                        .foregroundColor(SemanticColors.textPrimary)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search color palettes...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)

            Divider()

            // Content
            if filteredPalettes.isEmpty {
                UnifiedEmptyStateView(config: .colorPalettes(onAdd: {
                    visualPlanningStore.showingColorPaletteCreator = true
                }))
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        ForEach(filteredPalettes) { palette in
                            ColorPaletteCardView(palette: palette)
                                .onTapGesture {
                                    selectedPalette = palette
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedPalette) { palette in
            ColorPaletteDetailView(palette: palette)
                .environmentObject(visualPlanningStore)
        }
    }

    private var filteredPalettes: [ColorPalette] {
        var palettes = visualPlanningStore.colorPalettes

        // Apply style filter (ColorPalette no longer has styleCategory property)
        // Filter removed as ColorPalette model was simplified

        // Apply harmony filter (ColorPalette no longer has colorHarmonyType property)
        // Filter removed as ColorPalette model was simplified

        // Apply search filter
        if !searchText.isEmpty {
            palettes = palettes.filter { palette in
                palette.name.localizedCaseInsensitiveContains(searchText) ||
                    palette.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply sorting
        switch sortOption {
        case .dateCreated:
            return palettes.sorted { $0.createdAt > $1.createdAt }
        case .dateModified:
            return palettes.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return palettes.sorted { $0.name < $1.name }
        case .style:
            // ColorPalette no longer has styleCategory
            return palettes.sorted { $0.name < $1.name }
        case .harmony:
            // ColorPalette no longer has colorHarmonyType
            return palettes.sorted { $0.name < $1.name }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 20)
        ]
    }
}

enum ColorPaletteSortOption: CaseIterable {
    case dateCreated
    case dateModified
    case name
    case style
    case harmony

    var displayName: String {
        switch self {
        case .dateCreated: "Date Created"
        case .dateModified: "Date Modified"
        case .name: "Name"
        case .style: "Style"
        case .harmony: "Harmony Type"
        }
    }
}

struct ColorPaletteCardView: View {
    let palette: ColorPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color Preview
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(palette.colors.prefix(4), id: \.self) { hexColor in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.fromHexString(hexColor) ?? .gray)
                            .frame(height: 60)
                    }
                }

                if palette.colors.count > 4 {
                    HStack(spacing: 4) {
                        ForEach(Array(palette.colors.dropFirst(4).prefix(4)), id: \.self) { hexColor in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.fromHexString(hexColor) ?? .gray)
                                .frame(height: 20)
                        }
                        if palette.colors.count > 8 {
                            Text("+\(palette.colors.count - 8)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(palette.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if palette.isDefault {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }

                HStack {
                    // ColorPalette no longer has styleCategory
                    if let description = palette.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // ColorPalette no longer has colorHarmonyType
                    // Show color count instead
                    Text("\(palette.colors.count) colors")
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }

                // ColorPalette no longer has notes or visibility properties

                HStack {
                    Spacer()

                    Text(palette.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // ColorPalette no longer has tags property
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct EmptyColorPaletteView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "paintpalette")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Color Palettes Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first color palette to establish your wedding color scheme")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.huge)
            }

            Button(action: {
                visualPlanningStore.showingColorPaletteCreator = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Your First Color Palette")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.purple)
                .foregroundColor(SemanticColors.textPrimary)
                .cornerRadius(10)
            }

            Spacer()
        }
    }
}

#Preview {
    ColorPaletteListView()
        .environmentObject(VisualPlanningStoreV2())
        .frame(width: 800, height: 600)
}
