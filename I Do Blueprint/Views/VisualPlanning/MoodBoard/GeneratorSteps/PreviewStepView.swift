//
//  PreviewStepView.swift
//  My Wedding Planning App
//
//  Preview and generation step for mood board generator
//

import SwiftUI

struct PreviewStepView: View {
    private let logger = AppLogger.ui
    @Binding var state: MoodBoardGeneratorState
    let onGenerate: () -> Void

    @State private var previewMoodBoard: MoodBoard

    init(state: Binding<MoodBoardGeneratorState>, onGenerate: @escaping () -> Void) {
        _state = state
        self.onGenerate = onGenerate
        _previewMoodBoard = State(initialValue: PreviewStepView.createPreviewMoodBoard(from: state.wrappedValue))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "eye")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Preview & Generate")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Review your mood board and make final adjustments")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                Divider()

                HStack(spacing: 0) {
                    // Left Panel - Details (scrollable)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            detailsSection
                            summarySection
                            generateSection
                        }
                        .padding()
                    }
                    .frame(width: 300)

                    Divider()

                    // Right Panel - Canvas Preview
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Canvas Preview")
                                .font(.headline)

                            Spacer()

                            canvasControls
                        }

                        // Canvas with aspect ratio constraint
                        canvasPreview
                            .frame(maxHeight: geometry.size.height - 200)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .onAppear {
            updatePreviewMoodBoard()
        }
        .onChange(of: state.boardName) { _, _ in updatePreviewMoodBoard() }
        .onChange(of: state.styleCategory) { _, _ in updatePreviewMoodBoard() }
        .onChange(of: state.selectedImages) { _, _ in updatePreviewMoodBoard() }
        .onChange(of: state.colorPalette) { _, _ in updatePreviewMoodBoard() }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Board Details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "textformat")
                        .foregroundColor(.secondary)
                    Text("Name:")
                        .fontWeight(.medium)
                    Text(state.boardName.isEmpty ? "Untitled Board" : state.boardName)
                        .foregroundColor(state.boardName.isEmpty ? .secondary : .primary)
                }

                HStack {
                    Image(systemName: "star.square")
                        .foregroundColor(.secondary)
                    Text("Style:")
                        .fontWeight(.medium)
                    Text(state.styleCategory?.displayName ?? "No style selected")
                        .foregroundColor(state.styleCategory == nil ? .secondary : .primary)
                }

                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.secondary)
                    Text("Images:")
                        .fontWeight(.medium)
                    Text("\(state.selectedImages.count) image\(state.selectedImages.count == 1 ? "" : "s")")
                        .foregroundColor(state.selectedImages.isEmpty ? .secondary : .primary)
                }

                HStack {
                    Image(systemName: "paintpalette")
                        .foregroundColor(.secondary)
                    Text("Color Palette:")
                        .fontWeight(.medium)
                    Text(state.colorPalette?.name ?? "No palette extracted")
                        .foregroundColor(state.colorPalette == nil ? .secondary : .primary)
                }

                if !state.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                            Text("Tags")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 60), spacing: 4)
                        ], spacing: 4) {
                            ForEach(state.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                if let colorPalette = state.colorPalette {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Palette")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 6) {
                            ColorSwatch(color: colorPalette.primaryColor.swiftUIColor, size: 24)
                            ColorSwatch(color: colorPalette.secondaryColor.swiftUIColor, size: 24)
                            ColorSwatch(color: colorPalette.accentColor.swiftUIColor, size: 24)
                            ColorSwatch(color: colorPalette.neutralColor.swiftUIColor, size: 24)
                        }

                        Text("Quality: \(Int(colorPalette.extractionResult.qualityScore * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !state.styleSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Style Suggestions (\(state.styleSuggestions.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ForEach(state.styleSuggestions.prefix(3), id: \.self) { suggestion in
                            Text("• \(suggestion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        if state.styleSuggestions.count > 3 {
                            Text("and \(state.styleSuggestions.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Generate Section

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ready to Generate")
                .font(.headline)

            VStack(spacing: 12) {
                // Validation checklist
                ValidationChecklist(state: state)

                // Generate button
                Button(action: onGenerate) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Mood Board")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(canGenerate ? Color.blue : AppColors.textSecondary)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(10)
                }
                .disabled(!canGenerate)

                Text("This will create your mood board and add it to your collection")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Canvas Preview

    private var canvasPreview: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(previewMoodBoard.backgroundColor)
            .overlay(
                MoodBoardCanvasView(
                    moodBoard: .constant(previewMoodBoard),
                    isEditable: false)
                    .cornerRadius(12))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var canvasControls: some View {
        HStack(spacing: 8) {
            Button("Arrange Elements") {
                arrangeElementsAutomatically()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Shuffle Colors") {
                if let palette = state.colorPalette {
                    shuffleColors(palette)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(state.colorPalette == nil)
        }
    }

    // MARK: - Computed Properties

    private var canGenerate: Bool {
        !state.boardName.isEmpty &&
            state.styleCategory != nil &&
            !state.selectedImages.isEmpty
    }

    // MARK: - Helper Methods

    private func updatePreviewMoodBoard() {
        previewMoodBoard = Self.createPreviewMoodBoard(from: state)
    }

    private static func createPreviewMoodBoard(from state: MoodBoardGeneratorState) -> MoodBoard {
        MoodBoard(
            tenantId: "preview",
            boardName: state.boardName.isEmpty ? "Preview Board" : state.boardName,
            boardDescription: state.boardDescription,
            styleCategory: state.styleCategory ?? .modern,
            colorPaletteId: state.colorPalette?.id,
            canvasSize: CGSize(width: 800, height: 600),
            backgroundColor: state.colorPalette?.primaryColor.swiftUIColor ?? .white,
            elements: state.selectedImages)
    }

    private func arrangeElementsAutomatically() {
        let canvasSize = previewMoodBoard.canvasSize
        let margin: CGFloat = 40
        let spacing: CGFloat = 20

        let availableWidth = canvasSize.width - (margin * 2)
        let availableHeight = canvasSize.height - (margin * 2)

        let columns = max(1, Int(sqrt(Double(state.selectedImages.count))))
        let rows = Int(ceil(Double(state.selectedImages.count) / Double(columns)))

        let cellWidth = (availableWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
        let cellHeight = (availableHeight - (spacing * CGFloat(rows - 1))) / CGFloat(rows)

        for (index, _) in state.selectedImages.enumerated() {
            let column = index % columns
            let row = index / columns

            let x = margin + (CGFloat(column) * (cellWidth + spacing))
            let y = margin + (CGFloat(row) * (cellHeight + spacing))

            state.selectedImages[index].position = CGPoint(x: x + cellWidth / 2, y: y + cellHeight / 2)
            state.selectedImages[index].size = CGSize(
                width: min(cellWidth * 0.8, 150),
                height: min(cellHeight * 0.8, 150))
        }

        updatePreviewMoodBoard()
    }

    private func shuffleColors(_ palette: ExtractedColorPalette) {
        // Randomly assign colors from the palette to elements
        let colors = [
            palette.primaryColor.swiftUIColor,
            palette.secondaryColor.swiftUIColor,
            palette.accentColor.swiftUIColor,
            palette.neutralColor.swiftUIColor
        ]

        for index in state.selectedImages.indices {
            if state.selectedImages[index].elementType == .color {
                state.selectedImages[index].elementData.color = colors.randomElement()
            }
        }

        updatePreviewMoodBoard()
    }
}

// MARK: - Supporting Views

struct ColorSwatch: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
    }
}

struct ValidationChecklist: View {
    let state: MoodBoardGeneratorState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ChecklistItem(
                text: "Board name",
                isValid: !state.boardName.isEmpty)

            ChecklistItem(
                text: "Wedding style",
                isValid: state.styleCategory != nil)

            ChecklistItem(
                text: "Images added",
                isValid: !state.selectedImages.isEmpty)

            ChecklistItem(
                text: "Color palette (optional)",
                isValid: state.colorPalette != nil,
                isOptional: true)
        }
    }
}

struct ChecklistItem: View {
    let text: String
    let isValid: Bool
    let isOptional: Bool

    init(text: String, isValid: Bool, isOptional: Bool = false) {
        self.text = text
        self.isValid = isValid
        self.isOptional = isOptional
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : (isOptional ? .orange : .gray))
                .font(.caption)

            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .primary : .secondary)

            if isOptional {
                Text("(optional)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    @State var sampleState: MoodBoardGeneratorState = {
        var state = MoodBoardGeneratorState()
        state.boardName = "Romantic Garden Wedding"
        state.styleCategory = .romantic
        return state
    }()

    return PreviewStepView(state: $sampleState) {
        // TODO: Implement action - print("Generate mood board")
    }
    .frame(width: 900, height: 700)
}
