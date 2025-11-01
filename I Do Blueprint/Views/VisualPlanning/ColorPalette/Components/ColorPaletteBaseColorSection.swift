//
//  ColorPaletteBaseColorSection.swift
//  My Wedding Planning App
//
//  Base color selection section for Color Palette Creator
//

import SwiftUI
import UniformTypeIdentifiers

struct ColorPaletteBaseColorSection: View {
    @Binding var selectedColor: Color
    @Binding var showingColorPicker: Bool
    @Binding var showingImagePicker: Bool
    @Binding var selectedImage: NSImage?
    @Binding var extractionAlgorithm: ColorExtractionAlgorithm
    @Binding var isExtracting: Bool
    @Binding var extractedColors: [ExtractedColor]

    let visualPlanningStore: VisualPlanningStoreV2
    let getRecentColors: () -> [Color]
    let handleImageSelection: (Result<[URL], Error>) -> Void
    let extractColorsFromImage: (NSImage) async -> Void
    let applyExtractedColors: () -> Void
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose Base Color")
                    .font(.headline)

                Text("Select a primary color that will serve as the foundation for your palette")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Color wheel or picker
                VStack(spacing: 16) {
                    ColorWheelView(selectedColor: $selectedColor)
                        .frame(height: 320)

                    Button("Use Color Picker") {
                        showingColorPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, Spacing.sm)

                // Recent colors from mood boards
                if !visualPlanningStore.moodBoards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Colors from your mood boards:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(getRecentColors(), id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3))
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }

                // Image extraction section
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.vertical, Spacing.xs)

                    Text("Extract from Image")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(selectedImage == nil ? "Choose Image" : "Change Image")
                        }
                    }
                    .buttonStyle(.bordered)

                    if let image = selectedImage {
                        VStack(spacing: 10) {
                            // Compact image preview
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(6)
                                .clipped()

                            // Compact algorithm selector
                            Menu {
                                ForEach(ColorExtractionAlgorithm.allCases, id: \.self) { algorithm in
                                    Button(algorithm.displayName) {
                                        extractionAlgorithm = algorithm
                                        Task {
                                            await extractColorsFromImage(image)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Algorithm: \(extractionAlgorithm.displayName)")
                                        .font(.caption)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            // Extract button
                            Button(action: {
                                Task {
                                    await extractColorsFromImage(image)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if isExtracting {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                    }
                                    Text(isExtracting ? "Extracting..." : "Extract Colors")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(isExtracting)

                            // Display extracted colors in compact format
                            if !extractedColors.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tap a color to use it:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    // Horizontal scrolling for colors
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(extractedColors.prefix(10).indices, id: \.self) { index in
                                                let extractedColor = extractedColors[index]
                                                VStack(spacing: 3) {
                                                    Circle()
                                                        .fill(extractedColor.swiftUIColor)
                                                        .frame(width: 36, height: 36)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(
                                                                    selectedColor.hexString == extractedColor
                                                                        .hexString ? Color.blue : AppColors.textPrimary
                                                                        .opacity(0.1),
                                                                    lineWidth: selectedColor.hexString == extractedColor
                                                                        .hexString ? 2 : 1))
                                                        .onTapGesture {
                                                            selectedColor = extractedColor.swiftUIColor
                                                        }

                                                    Text(extractedColor.hexString)
                                                        .font(.system(size: 8, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, Spacing.xs)
                                    }

                                    Button("Apply All to Palette") {
                                        applyExtractedColors()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(Spacing.sm)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(6)
                            }
                        }
                    }
                }

                Button("Next: Generate Harmony") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, Spacing.xs)
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(selectedColor: $selectedColor)
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false) { result in
            handleImageSelection(result)
        }
    }
}
