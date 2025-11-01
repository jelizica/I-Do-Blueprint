//
//  ColorsAndStyleStepView.swift
//  My Wedding Planning App
//
//  Colors and style step for mood board generator
//

import SwiftUI

struct ColorsAndStyleStepView: View {
    @Binding var state: MoodBoardGeneratorState
    @ObservedObject var colorExtractionService: ColorExtractionService

    @State private var selectedImageForExtraction: VisualElement?
    @State private var extractionResults: [ColorExtractionAlgorithm: ColorExtractionResult] = [:]
    @State private var isExtracting = false
    @State private var selectedAlgorithm: ColorExtractionAlgorithm = .vibrant

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)

                    Text("Colors & Style")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Extract colors from your images and get style suggestions")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 20) {
                    // Current Color Palette
                    if let palette = state.colorPalette {
                        currentPaletteSection(palette)
                    }

                    // Color Extraction Section
                    colorExtractionSection

                    // Style Suggestions
                    styleSuggestionsSection
                }
                .padding(.horizontal, Spacing.huge)
            }
            .padding(.vertical, Spacing.xl)
        }
    }

    // MARK: - Current Palette Section

    private func currentPaletteSection(_ palette: ExtractedColorPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Current Color Palette", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                Button("Remove") {
                    state.colorPalette = nil
                }
                .foregroundColor(.red)
            }

            VStack(spacing: 12) {
                Text(palette.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    ColorSwatchView(
                        color: palette.primaryColor,
                        label: "Primary",
                        size: 60)
                    ColorSwatchView(
                        color: palette.secondaryColor,
                        label: "Secondary",
                        size: 60)
                    ColorSwatchView(
                        color: palette.accentColor,
                        label: "Accent",
                        size: 60)
                    ColorSwatchView(
                        color: palette.neutralColor,
                        label: "Neutral",
                        size: 60)
                }

                // Quality score
                HStack {
                    Text("Quality Score:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ProgressView(value: palette.extractionResult.qualityScore)
                        .frame(width: 100)

                    Text("\(Int(palette.extractionResult.qualityScore * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Color Extraction Section

    private var colorExtractionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Extract Colors from Images", systemImage: "eyedropper")
                .font(.headline)

            if state.selectedImages.isEmpty {
                Text("No images available for color extraction. Please add images in the previous step.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 16) {
                    // Image selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select an image to extract colors from:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(state.selectedImages) { element in
                                    ImageSelectionCard(
                                        element: element,
                                        isSelected: selectedImageForExtraction?.id == element.id) {
                                        selectedImageForExtraction = element
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.xs)
                        }
                    }

                    // Algorithm selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extraction Algorithm:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Picker("Algorithm", selection: $selectedAlgorithm) {
                            ForEach(ColorExtractionAlgorithm.allCases, id: \.self) { algorithm in
                                VStack(alignment: .leading) {
                                    Text(algorithm.displayName)
                                        .fontWeight(.medium)
                                    Text(algorithm.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(algorithm)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    // Extract button
                    HStack {
                        Button(action: extractColors) {
                            HStack {
                                if isExtracting {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isExtracting ? "Extracting..." : "Extract Colors")
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedImageForExtraction != nil ? Color.purple : AppColors.textSecondary)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(8)
                        }
                        .disabled(selectedImageForExtraction == nil || isExtracting)

                        if selectedImageForExtraction != nil {
                            Button("Compare All Algorithms") {
                                compareAlgorithms()
                            }
                            .disabled(isExtracting)
                        }
                    }

                    // Extraction results
                    if !extractionResults.isEmpty {
                        extractionResultsView
                    }
                }
            }
        }
    }

    // MARK: - Style Suggestions Section

    private var styleSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Style Suggestions", systemImage: "lightbulb")
                .font(.headline)

            if let styleCategory = state.styleCategory {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Based on your \(styleCategory.displayName) style:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    let suggestions = generateStyleSuggestions(for: styleCategory)
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 200), spacing: 12)
                    ], spacing: 12) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            StyleSuggestionCard(suggestion: suggestion) {
                                if !state.styleSuggestions.contains(suggestion) {
                                    state.styleSuggestions.append(suggestion)
                                }
                            }
                        }
                    }

                    if !state.styleSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Suggestions:")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            ForEach(state.styleSuggestions, id: \.self) { suggestion in
                                HStack {
                                    Text("• \(suggestion)")
                                        .font(.body)

                                    Spacer()

                                    Button("Remove") {
                                        state.styleSuggestions.removeAll { $0 == suggestion }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Please select a style category in the first step to get personalized suggestions.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Extraction Results View

    private var extractionResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extraction Results")
                .font(.subheadline)
                .fontWeight(.medium)

            ForEach(Array(extractionResults.keys), id: \.self) { algorithm in
                if let result = extractionResults[algorithm] {
                    ExtractionResultCard(
                        algorithm: algorithm,
                        result: result,
                        isSelected: state.colorPalette?.extractionResult.algorithm == algorithm) {
                        selectPalette(from: result)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Color Extraction Logic

    private func extractColors() {
        guard let selectedElement = selectedImageForExtraction,
              let imageUrl = selectedElement.elementData.imageUrl,
              let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
              let nsImage = NSImage(data: data) else { return }

        isExtracting = true

        Task {
            do {
                let result = try await colorExtractionService.extractColors(
                    from: nsImage,
                    algorithm: selectedAlgorithm,
                    options: ColorExtractionOptions(maxColors: 6))

                await MainActor.run {
                    extractionResults[selectedAlgorithm] = result
                    isExtracting = false

                    // Auto-select if it's the first extraction
                    if state.colorPalette == nil {
                        selectPalette(from: result)
                    }
                }
            } catch {
                await MainActor.run {
                    isExtracting = false
                    // Handle error
                }
            }
        }
    }

    private func compareAlgorithms() {
        guard let selectedElement = selectedImageForExtraction,
              let imageUrl = selectedElement.elementData.imageUrl,
              let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
              let nsImage = NSImage(data: data) else { return }

        isExtracting = true

        Task {
            do {
                let results = try await colorExtractionService.compareAlgorithms(
                    for: nsImage,
                    algorithms: ColorExtractionAlgorithm.allCases,
                    options: ColorExtractionOptions(maxColors: 6))

                await MainActor.run {
                    extractionResults = results
                    isExtracting = false

                    // Auto-select best result if no palette exists
                    if state.colorPalette == nil,
                       let bestResult = results.values.max(by: { $0.qualityScore < $1.qualityScore }) {
                        selectPalette(from: bestResult)
                    }
                }
            } catch {
                await MainActor.run {
                    isExtracting = false
                    // Handle error
                }
            }
        }
    }

    private func selectPalette(from result: ColorExtractionResult) {
        guard result.colors.count >= 4 else { return }

        state.colorPalette = ExtractedColorPalette(
            name: "Extracted using \(result.algorithm.displayName)",
            primaryColor: result.colors[0],
            secondaryColor: result.colors[1],
            accentColor: result.colors[2],
            neutralColor: result.colors[3],
            extractionResult: result)
    }

    private func generateStyleSuggestions(for style: StyleCategory) -> [String] {
        switch style {
        case .romantic:
            [
                "Use soft, flowing fabrics like chiffon and tulle",
                "Incorporate candlelight and warm lighting",
                "Add delicate floral arrangements with roses and peonies",
                "Choose vintage or antique decorative elements"
            ]
        case .modern:
            [
                "Embrace clean, geometric lines in decor",
                "Use bold, contrasting colors sparingly",
                "Incorporate sleek metallic accents",
                "Choose minimalist centerpieces"
            ]
        case .rustic:
            [
                "Use natural wood and burlap textures",
                "Incorporate mason jars and lanterns",
                "Add wildflower arrangements",
                "Choose earth-tone color palettes"
            ]
        case .garden:
            [
                "Use abundant greenery and natural elements",
                "Incorporate seasonal flowers and plants",
                "Add string lights or fairy lights",
                "Choose organic, flowing arrangements"
            ]
        default:
            [
                "Consider your venue's existing aesthetic",
                "Balance bold elements with subtle details",
                "Incorporate personal meaningful touches",
                "Ensure cohesion across all visual elements"
            ]
        }
    }
}

// MARK: - Supporting Views

struct ImageSelectionCard: View {
    let element: VisualElement
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Image preview
            if let imageUrl = element.elementData.imageUrl,
               let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3))
            }

            Text(element.elementData.originalFilename ?? "Image")
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct ColorSwatchView: View {
    let color: ExtractedColor
    let label: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color.swiftUIColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))

            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(color.hexString)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExtractionResultCard: View {
    let algorithm: ColorExtractionAlgorithm
    let result: ColorExtractionResult
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(algorithm.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        Text("Quality: \(Int(result.qualityScore * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(result.processingTimeMs))ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(isSelected ? "Selected" : "Use This") {
                    onSelect()
                }
                .disabled(isSelected)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            HStack(spacing: 6) {
                ForEach(Array(result.colors.prefix(6).enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : AppColors.textSecondary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
    }
}

struct StyleSuggestionCard: View {
    let suggestion: String
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            Button("Add to Board") {
                onAdd()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    @State var sampleState = MoodBoardGeneratorState()
    @StateObject var colorService = ColorExtractionService()

    return ColorsAndStyleStepView(
        state: $sampleState,
        colorExtractionService: colorService)
        .frame(width: 800, height: 600)
}
