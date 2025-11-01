//
//  MoodBoardGeneratorView.swift
//  My Wedding Planning App
//
//  Step-by-step mood board creation interface
//

import SwiftUI
import UniformTypeIdentifiers

struct MoodBoardGeneratorView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @Environment(\.dismiss) private var dismiss

    @StateObject private var colorExtractionService = ColorExtractionService()
    @State private var currentStep: GeneratorStep = .basicInfo
    @State private var generatorState = MoodBoardGeneratorState()
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0
    @State private var errorMessage: String?

    let mode: GeneratorMode
    let existingMoodBoard: MoodBoard?

    init(mode: GeneratorMode = .create, existingMoodBoard: MoodBoard? = nil) {
        self.mode = mode
        self.existingMoodBoard = existingMoodBoard
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Progress Indicator
                progressIndicator

                // Error Alert
                if let errorMessage {
                    errorAlert(errorMessage)
                }

                // Generation Progress
                if isGenerating {
                    generationProgressView
                }

                // Step Content
                Divider()

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Navigation Controls
                navigationControls
            }
        }
        .frame(width: 900, height: 700)
        .onAppear {
            initializeState()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text(mode == .create ? "Create Mood Board" : "Edit Mood Board")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
            }

            Text("Create a beautiful mood board for your wedding planning")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Step \(currentStep.rawValue + 1) of \(GeneratorStep.allCases.count)")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(stepProgress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: stepProgress)
                .progressViewStyle(.linear)

            // Step indicators
            HStack(spacing: 0) {
                ForEach(GeneratorStep.allCases, id: \.self) { step in
                    stepIndicator(for: step)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }

    private func stepIndicator(for step: GeneratorStep) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(stepIndicatorColor(for: step))
                .frame(width: 24, height: 24)
                .overlay(
                    Group {
                        if step.rawValue < currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(AppColors.textPrimary)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(step == currentStep ? .white : .secondary)
                        }
                    })

            Text(step.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(step == currentStep ? .primary : .secondary)
                .lineLimit(1)
        }
    }

    private func stepIndicatorColor(for step: GeneratorStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            .green
        } else if step == currentStep {
            .blue
        } else {
            .gray.opacity(0.3)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .basicInfo:
            BasicInfoStepView(state: $generatorState)
        case .addImages:
            AddImagesStepView(
                state: $generatorState,
                colorExtractionService: colorExtractionService)
        case .colorsAndStyle:
            ColorsAndStyleStepView(
                state: $generatorState,
                colorExtractionService: colorExtractionService)
        case .preview:
            PreviewStepView(
                state: $generatorState,
                onGenerate: generateMoodBoard)
        }
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack {
            // Previous Button
            Button("Previous") {
                previousStep()
            }
            .disabled(currentStep == .basicInfo || isGenerating)

            Spacer()

            // Step Requirements
            stepRequirementsView

            Spacer()

            // Next/Generate Button
            if currentStep == .preview {
                Button(action: generateMoodBoard) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(mode == .create ? "Create Mood Board" : "Update Mood Board")
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.sm)
                    .background(canProceedToNext ? Color.blue : AppColors.textSecondary)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(8)
                }
                .disabled(!canProceedToNext || isGenerating)
            } else {
                Button("Next") {
                    nextStep()
                }
                .disabled(!canProceedToNext || isGenerating)
            }
        }
        .padding()
    }

    // MARK: - Helper Views

    private var stepRequirementsView: some View {
        VStack(spacing: 4) {
            ForEach(currentStepRequirements, id: \.requirement) { req in
                HStack(spacing: 6) {
                    Image(systemName: req.isMet ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(req.isMet ? .green : .gray)
                        .font(.caption)

                    Text(req.requirement)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func errorAlert(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
            Spacer()
            Button("Dismiss") {
                errorMessage = nil
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
        .background(Color.orange.opacity(0.1))
    }

    private var generationProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Generating your mood board...")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(generationProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: generationProgress)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }

    // MARK: - Computed Properties

    private var stepProgress: Double {
        Double(currentStep.rawValue + 1) / Double(GeneratorStep.allCases.count)
    }

    private var canProceedToNext: Bool {
        switch currentStep {
        case .basicInfo:
            !generatorState.boardName.isEmpty && generatorState.styleCategory != nil
        case .addImages:
            !generatorState.selectedImages.isEmpty
        case .colorsAndStyle:
            true // Optional step
        case .preview:
            !generatorState.boardName.isEmpty &&
                generatorState.styleCategory != nil &&
                !generatorState.selectedImages.isEmpty
        }
    }

    private var currentStepRequirements: [StepRequirement] {
        switch currentStep {
        case .basicInfo:
            [
                StepRequirement(
                    requirement: "Board name",
                    isMet: !generatorState.boardName.isEmpty),
                StepRequirement(
                    requirement: "Style category",
                    isMet: generatorState.styleCategory != nil)
            ]
        case .addImages:
            [
                StepRequirement(
                    requirement: "At least one image",
                    isMet: !generatorState.selectedImages.isEmpty)
            ]
        case .colorsAndStyle:
            [
                StepRequirement(
                    requirement: "Optional: Extract colors",
                    isMet: generatorState.colorPalette != nil),
                StepRequirement(
                    requirement: "Optional: Style suggestions",
                    isMet: !generatorState.styleSuggestions.isEmpty)
            ]
        case .preview:
            [
                StepRequirement(
                    requirement: "Ready to generate",
                    isMet: canProceedToNext)
            ]
        }
    }

    // MARK: - Navigation Methods

    private func nextStep() {
        guard canProceedToNext else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            if let nextStep = GeneratorStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }

    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let prevStep = GeneratorStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prevStep
            }
        }
    }

    // MARK: - State Management

    private func initializeState() {
        if mode == .edit, let existingBoard = existingMoodBoard {
            generatorState = MoodBoardGeneratorState(from: existingBoard)
            currentStep = .preview // Skip to preview for editing
        }
    }

    // MARK: - Mood Board Generation

    private func generateMoodBoard() {
        guard canProceedToNext else { return }

        isGenerating = true
        generationProgress = 0
        errorMessage = nil

        Task {
            do {
                await updateProgress(0.1)

                let moodBoard = createMoodBoardFromState()

                await updateProgress(0.5)

                if mode == .create {
                    await visualPlanningStore.createMoodBoard(moodBoard)
                } else if let existingBoard = existingMoodBoard {
                    // Create new MoodBoard with existing ID since id is immutable
                    let updatedBoard = MoodBoard(
                        id: existingBoard.id,
                        tenantId: moodBoard.tenantId,
                        boardName: moodBoard.boardName,
                        boardDescription: moodBoard.boardDescription,
                        styleCategory: moodBoard.styleCategory,
                        colorPaletteId: moodBoard.colorPaletteId,
                        canvasSize: moodBoard.canvasSize,
                        backgroundColor: moodBoard.backgroundColor,
                        backgroundImage: moodBoard.backgroundImage,
                        elements: moodBoard.elements,
                        isTemplate: moodBoard.isTemplate,
                        isPublic: moodBoard.isPublic,
                        tags: moodBoard.tags,
                        inspirationUrls: moodBoard.inspirationUrls,
                        notes: moodBoard.notes)
                    await visualPlanningStore.updateMoodBoard(updatedBoard)
                }

                await updateProgress(1.0)

                // Wait a moment to show completion
                try await Task.sleep(nanoseconds: 500_000_000)

                await MainActor.run {
                    isGenerating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    @MainActor
    private func updateProgress(_ progress: Double) {
        generationProgress = progress
    }

    private func createMoodBoardFromState() -> MoodBoard {
        let moodBoardId = UUID()

        // Update all elements to have the correct mood board ID
        let elementsWithCorrectId = generatorState.selectedImages.map { element in
            var updatedElement = element
            updatedElement.moodBoardId = moodBoardId
            return updatedElement
        }

        guard let tenantId = SessionManager.shared.getTenantId() else {
            return MoodBoard(
                id: moodBoardId,
                tenantId: UUID().uuidString,
                boardName: generatorState.boardName,
                boardDescription: generatorState.boardDescription,
                styleCategory: generatorState.styleCategory ?? .modern,
                colorPaletteId: generatorState.colorPalette?.id,
                canvasSize: CGSize(width: 800, height: 600),
                backgroundColor: generatorState.colorPalette?.primaryColor.swiftUIColor ?? .white,
                elements: [],
                tags: [])
        }

        return MoodBoard(
            id: moodBoardId,
            tenantId: tenantId.uuidString,
            boardName: generatorState.boardName,
            boardDescription: generatorState.boardDescription,
            styleCategory: generatorState.styleCategory ?? .modern,
            colorPaletteId: generatorState.colorPalette?.id,
            canvasSize: CGSize(width: 800, height: 600),
            backgroundColor: generatorState.colorPalette?.primaryColor.swiftUIColor ?? .white,
            elements: elementsWithCorrectId,
            tags: generatorState.tags)
    }
}

// MARK: - Supporting Types

enum GeneratorMode {
    case create
    case edit
}

enum GeneratorStep: Int, CaseIterable {
    case basicInfo = 0
    case addImages = 1
    case colorsAndStyle = 2
    case preview = 3

    var title: String {
        switch self {
        case .basicInfo: "Basic Info"
        case .addImages: "Add Images"
        case .colorsAndStyle: "Colors & Style"
        case .preview: "Preview"
        }
    }

    var description: String {
        switch self {
        case .basicInfo: "Set your mood board name and style"
        case .addImages: "Upload or import images"
        case .colorsAndStyle: "Extract colors and get style suggestions"
        case .preview: "Review and create your mood board"
        }
    }
}

struct StepRequirement {
    let requirement: String
    let isMet: Bool
}

@Observable
class MoodBoardGeneratorState {
    var boardName: String = ""
    var boardDescription: String = ""
    var styleCategory: StyleCategory?
    var selectedImages: [VisualElement] = []
    var colorPalette: ExtractedColorPalette?
    var styleSuggestions: [String] = []
    var tags: [String] = []

    init() {}

    init(from moodBoard: MoodBoard) {
        boardName = moodBoard.boardName
        boardDescription = moodBoard.boardDescription ?? ""
        styleCategory = moodBoard.styleCategory
        selectedImages = moodBoard.elements
        tags = moodBoard.tags
    }
}

struct ExtractedColorPalette: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let primaryColor: ExtractedColor
    let secondaryColor: ExtractedColor
    let accentColor: ExtractedColor
    let neutralColor: ExtractedColor
    let extractionResult: ColorExtractionResult

    static func == (lhs: ExtractedColorPalette, rhs: ExtractedColorPalette) -> Bool {
        lhs.id == rhs.id
    }
}

// Preview
#Preview {
    MoodBoardGeneratorView()
        .environmentObject(VisualPlanningStoreV2())
}
