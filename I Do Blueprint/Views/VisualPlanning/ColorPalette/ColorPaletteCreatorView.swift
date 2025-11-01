//
//  ColorPaletteCreatorView.swift
//  My Wedding Planning App
//
//  Advanced color palette creator with interactive color wheel and harmony tools
//

import SwiftUI
import UniformTypeIdentifiers

struct ColorPaletteCreatorView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @Environment(\.dismiss) private var dismiss

    @State private var paletteName = ""
    @State private var selectedColor = Color.blue
    @State private var currentHarmonyType: ColorHarmonyType = .complementary
    @State private var selectedPaletteColors: [PaletteColor] = []
    @State private var currentStep: CreatorStep = .baseColor
    @State private var showingColorPicker = false
    @State private var selectedColorIndex: Int = 0
    @State private var previewMode: PalettePreviewMode = .swatches

    // Image extraction states
    @State private var showingImagePicker = false
    @State private var selectedImage: NSImage?
    @State private var extractionAlgorithm: ColorExtractionAlgorithm = .vibrant
    @State private var isExtracting = false
    @State private var extractedColors: [ExtractedColor] = []
    @StateObject private var colorExtractionService = ColorExtractionService()
    
    // Mood board import states
    @State private var showingMoodBoardImport = false

    private let logger = AppLogger.ui

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ColorPaletteHeaderSection(
                paletteName: $paletteName,
                onDismiss: {
                    dismiss()
                })

            Divider()

            HStack(spacing: 0) {
                // Left Panel - Controls
                VStack(alignment: .leading, spacing: 0) {
                    ColorPaletteStepNavigationSection(
                        currentStep: $currentStep,
                        getStepIcon: getStepIcon)
                        .padding(.bottom, Spacing.lg)

                    // Content section with flexible height
                    Group {
                        switch currentStep {
                        case .baseColor:
                            ColorPaletteBaseColorSection(
                                selectedColor: $selectedColor,
                                showingColorPicker: $showingColorPicker,
                                showingImagePicker: $showingImagePicker,
                                selectedImage: $selectedImage,
                                extractionAlgorithm: $extractionAlgorithm,
                                isExtracting: $isExtracting,
                                extractedColors: $extractedColors,
                                visualPlanningStore: visualPlanningStore,
                                getRecentColors: getRecentColors,
                                handleImageSelection: handleImageSelection,
                                extractColorsFromImage: extractColorsFromImage,
                                applyExtractedColors: applyExtractedColors,
                                onNext: {
                                    generateInitialHarmony()
                                    currentStep = .harmony
                                })
                        case .harmony:
                            ColorPaletteHarmonySection(
                                currentHarmonyType: $currentHarmonyType,
                                selectedPaletteColors: $selectedPaletteColors,
                                generateHarmonyColors: generateHarmonyColors,
                                onBack: {
                                    currentStep = .baseColor
                                },
                                onNext: {
                                    currentStep = .refinement
                                })
                        case .refinement:
                            ColorPaletteRefinementSection(
                                selectedPaletteColors: $selectedPaletteColors,
                                addCustomColor: addCustomColor,
                                onBack: {
                                    currentStep = .harmony
                                },
                                onNext: {
                                    currentStep = .preview
                                })
                        case .preview:
                            ColorPalettePreviewSection(
                                selectedPaletteColors: $selectedPaletteColors,
                                paletteName: $paletteName,
                                currentHarmonyType: currentHarmonyType,
                                getContrastRating: getContrastRating,
                                getContrastColor: getContrastColor,
                                onBack: {
                                    currentStep = .refinement
                                },
                                onSave: savePalette)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    // Action buttons at bottom
                    ColorPaletteActionButtonsSection(
                        canLoadFromMoodBoard: !visualPlanningStore.moodBoards.isEmpty,
                        onReset: resetPalette,
                        onLoadFromMoodBoard: {
                            showingMoodBoardImport = true
                        })
                        .padding(.top, Spacing.lg)
                }
                .frame(width: 320)
                .padding()

                Divider()

                // Right Panel - Visual Preview
                VStack(spacing: 16) {
                    ColorPalettePreviewControlsSection(previewMode: $previewMode)
                    ColorPalettePalettePreviewSection(
                        previewMode: $previewMode,
                        selectedPaletteColors: $selectedPaletteColors)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .frame(width: 900, height: 700)
        .onAppear {
            initializeDefaultPalette()
        }
        .sheet(isPresented: $showingMoodBoardImport) {
            MoodBoardColorImportSheet(
                moodBoards: visualPlanningStore.moodBoards,
                onImport: { colors in
                    importColorsFromMoodBoard(colors)
                    showingMoodBoardImport = false
                },
                onDismiss: {
                    showingMoodBoardImport = false
                })
        }
    }

    // MARK: - Helper Methods

    // Image extraction helpers
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Ensure we have access to the file
            guard url.startAccessingSecurityScopedResource() else {
                logger.error("Failed to access security-scoped file")
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            if let image = NSImage(contentsOf: url) {
                selectedImage = image
                // Automatically extract colors when image is selected
                Task {
                    await extractColorsFromImage(image)
                }
            }

        case .failure(let error):
            logger.error("Error selecting image", error: error)
        }
    }

    private func extractColorsFromImage(_ image: NSImage) async {
        isExtracting = true
        defer { isExtracting = false }

        do {
            let options = ColorExtractionOptions(
                maxColors: 10,
                includeAccessibility: true,
                qualityThreshold: 0.1)

            let result = try await colorExtractionService.extractColors(
                from: image,
                algorithm: extractionAlgorithm,
                options: options)

            await MainActor.run {
                extractedColors = result.colors
            }
        } catch {
            logger.error("Error extracting colors", error: error)
            await MainActor.run {
                extractedColors = []
            }
        }
    }

    private func applyExtractedColors() {
        guard !extractedColors.isEmpty else { return }

        // Clear existing palette
        selectedPaletteColors = []

        // Sort extracted colors by confidence and population
        let sortedColors = extractedColors.sorted {
            ($0.confidence * $0.population) > ($1.confidence * $1.population)
        }

        // Map colors to roles based on their characteristics
        for (index, extractedColor) in sortedColors.prefix(6).enumerated() {
            let role: ColorRole = switch index {
            case 0: .primary // Most confident/populated color
            case 1: .secondary // Second most confident
            case 2: .accent // Third most confident
            case 3: .neutral // Fourth most confident
            default: .accent // Additional colors as accents
            }

            selectedPaletteColors.append(PaletteColor(
                color: extractedColor.swiftUIColor,
                role: role))
        }

        // Update the selected color to the primary color
        if let primaryColor = selectedPaletteColors.first?.color {
            selectedColor = primaryColor
        }

        // Move to preview step to show the extracted palette
        currentStep = .preview
    }

    private func initializeDefaultPalette() {
        if paletteName.isEmpty {
            paletteName = "Wedding Palette \(visualPlanningStore.colorPalettes.count + 1)"
        }
        generateInitialHarmony()
    }

    private func generateInitialHarmony() {
        selectedPaletteColors = []

        // Add base color as primary
        selectedPaletteColors.append(PaletteColor(
            color: selectedColor,
            role: .primary))

        generateHarmonyColors()
    }

    private func generateHarmonyColors() {
        // Keep only the primary color and regenerate harmony
        let primaryColor = selectedPaletteColors.first?.color ?? selectedColor
        selectedPaletteColors = [PaletteColor(color: primaryColor, role: .primary)]

        let harmonyColors = ColorHarmonyGenerator.generateHarmony(
            baseColor: primaryColor,
            type: currentHarmonyType)

        for (index, color) in harmonyColors.enumerated() {
            let role: ColorRole = switch index {
            case 0: .secondary
            case 1: .accent
            case 2: .neutral
            default: .accent
            }

            selectedPaletteColors.append(PaletteColor(color: color, role: role))
        }
    }

    private func addCustomColor() {
        selectedPaletteColors.append(PaletteColor(
            color: .gray,
            role: .accent))
    }

    private func getRecentColors() -> [Color] {
        var colors: [Color] = []

        for moodBoard in visualPlanningStore.moodBoards.prefix(3) {
            colors.append(moodBoard.backgroundColor)

            for element in moodBoard.elements.prefix(2) {
                if element.elementType == .color,
                   let elementColor = element.elementData.color {
                    colors.append(elementColor)
                }
            }
        }

        return Array(Set(colors)).prefix(12).map { $0 }
    }

    private func getContrastRating() -> String {
        guard selectedPaletteColors.count >= 2 else { return "N/A" }

        let contrasts = generateContrastPairs().map { pair in
            AccessibilityAnalyzer.calculateContrastRatio(
                foreground: pair.1,
                background: pair.0)
        }

        let averageContrast = contrasts.reduce(0, +) / Double(contrasts.count)

        switch averageContrast {
        case 7...: return "Excellent"
        case 4.5 ..< 7: return "Good"
        case 3 ..< 4.5: return "Fair"
        default: return "Poor"
        }
    }

    private func getContrastColor() -> Color {
        let rating = getContrastRating()
        switch rating {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        default: return .red
        }
    }

    private func generateContrastPairs() -> [(Color, Color)] {
        var pairs: [(Color, Color)] = []

        for i in 0 ..< selectedPaletteColors.count {
            for j in 0 ..< selectedPaletteColors.count {
                if i != j {
                    pairs.append((
                        selectedPaletteColors[i].color,
                        selectedPaletteColors[j].color))
                }
            }
        }

        return pairs
    }

    private func resetPalette() {
        selectedPaletteColors.removeAll()
        currentStep = .baseColor
        selectedColor = .blue
    }

    private func savePalette() {
        guard !paletteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Cannot save palette without a name")
            return
        }

        guard !selectedPaletteColors.isEmpty else {
            logger.warning("Cannot save palette without colors")
            return
        }

        // Convert selected colors to hex strings
        let colorHexStrings = selectedPaletteColors.map { paletteColor in
            let components = paletteColor.color.cgColor?.components ?? [0, 0, 0, 1]
            let r = Int(components[0] * 255)
            let g = Int(components[1] * 255)
            let b = Int(components[2] * 255)
            return String(format: "#%02X%02X%02X", r, g, b)
        }

        let newPalette = ColorPalette(
            name: paletteName.trimmingCharacters(in: .whitespacesAndNewlines),
            colors: colorHexStrings,
            description: "Custom \(currentHarmonyType.displayName) palette",
            isDefault: false)

                Task {
            await visualPlanningStore.createColorPalette(newPalette)
            dismiss()
        }
    }

    private func getStepIcon(_ step: CreatorStep) -> String {
        switch step {
        case .baseColor: "circle.fill"
        case .harmony: "dial.high"
        case .refinement: "slider.horizontal.3"
        case .preview: "eye"
        }
    }
    
    private func importColorsFromMoodBoard(_ colors: [Color]) {
        // Add imported colors to palette
        for color in colors {
            if !selectedPaletteColors.contains(where: { $0.color.hexString == color.hexString }) {
                selectedPaletteColors.append(PaletteColor(color: color, role: .accent))
            }
        }
        
        logger.info("Imported \(colors.count) colors from mood board")
        
        // Move to preview step to show imported colors
        if !selectedPaletteColors.isEmpty {
            currentStep = .preview
        }
    }
}

// MARK: - Supporting Types

enum CreatorStep: Int, CaseIterable {
    case baseColor = 0
    case harmony = 1
    case refinement = 2
    case preview = 3

    var title: String {
        switch self {
        case .baseColor: "Base Color"
        case .harmony: "Harmony"
        case .refinement: "Refinement"
        case .preview: "Preview"
        }
    }
}

enum PalettePreviewMode: CaseIterable {
    case swatches, gradients, mockup, accessibility

    var title: String {
        switch self {
        case .swatches: "Swatches"
        case .gradients: "Gradients"
        case .mockup: "Mockup"
        case .accessibility: "Accessibility"
        }
    }
}

enum ColorRole: CaseIterable {
    case primary, secondary, accent, neutral

    var title: String {
        switch self {
        case .primary: "Primary"
        case .secondary: "Secondary"
        case .accent: "Accent"
        case .neutral: "Neutral"
        }
    }
}

struct PaletteColor: Identifiable {
    let id = UUID()
    var color: Color
    var role: ColorRole
}

#Preview {
    ColorPaletteCreatorView()
        .environmentObject(VisualPlanningStoreV2())
        .frame(width: 900, height: 700)
}
