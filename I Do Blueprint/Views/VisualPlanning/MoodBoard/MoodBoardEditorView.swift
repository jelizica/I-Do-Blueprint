//
//  MoodBoardEditorView.swift
//  My Wedding Planning App
//
//  Advanced mood board editor with refinement tools
//

import SwiftUI
import UniformTypeIdentifiers

struct MoodBoardEditorView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @Environment(\.dismiss) private var dismiss

    let moodBoard: MoodBoard
    @State private var editableMoodBoard: MoodBoard
    @State private var selectedTool: EditorTool = .select
    @State private var selectedElementId: UUID?
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGPoint = .zero
    @State private var showingFilters = false
    @State private var showingLayers = false
    @State private var showingColorAdjustments = false
    @State private var showingExport = false
    @State private var showingTemplates = false
    @State private var historyManager = MoodBoardHistoryManager()

    init(moodBoard: MoodBoard) {
        self.moodBoard = moodBoard
        _editableMoodBoard = State(initialValue: moodBoard)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with tools
            MoodBoardHeaderSection(
                editableMoodBoard: $editableMoodBoard,
                canvasScale: $canvasScale,
                showingTemplates: $showingTemplates,
                showingExport: $showingExport,
                historyManager: historyManager,
                onUndo: undo,
                onRedo: redo,
                onFit: fitCanvasToView,
                onSave: saveMoodBoard,
                onClose: { dismiss() })

            Divider()

            HStack(spacing: 0) {
                // Left toolbar
                MoodBoardLeftToolbar(
                    selectedTool: $selectedTool,
                    showingFilters: $showingFilters,
                    onAddImage: addImage,
                    onAddColorSwatch: addColorSwatch,
                    onAddText: addText,
                    onAddInspiration: addInspiration,
                    onAutoArrange: autoArrange)

                Divider()

                // Main canvas area
                MoodBoardCanvasSection(
                    editableMoodBoard: $editableMoodBoard,
                    selectedElementId: $selectedElementId,
                    selectedTool: selectedTool,
                    canvasScale: canvasScale,
                    canvasOffset: canvasOffset,
                    onElementChanged: { element in
                        updateElement(element)
                    },
                    onCanvasChanged: { newMoodBoard in
                        editableMoodBoard = newMoodBoard
                        historyManager.addSnapshot(newMoodBoard)
                    },
                    onPanGesture: { translation in
                        canvasOffset = CGPoint(
                            x: canvasOffset.x + translation.width,
                            y: canvasOffset.y + translation.height)
                    },
                    onZoomGesture: { value in
                        canvasScale = max(0.25, min(4.0, value))
                    })

                Divider()

                // Right properties panel
                MoodBoardRightPropertiesPanel(
                    showingLayers: $showingLayers,
                    showingFilters: $showingFilters,
                    showingColorAdjustments: $showingColorAdjustments,
                    selectedElement: selectedElement,
                    canvasPropertiesContent: AnyView(
                        MoodBoardCanvasPropertiesSection(
                            editableMoodBoard: $editableMoodBoard,
                            historyManager: historyManager)),
                    elementPropertiesContent: selectedElement != nil ? AnyView(elementPropertiesSection(selectedElement!)) : nil,
                    filtersContent: AnyView(MoodBoardFiltersSection()),
                    colorAdjustmentsContent: AnyView(MoodBoardColorAdjustmentsSection()))
            }
        }
        .frame(width: 1200, height: 700)
        .onAppear {
            historyManager.addSnapshot(editableMoodBoard)
            centerCanvas()
        }
        .sheet(isPresented: $showingExport) {
            ExportInterfaceView(
                exportType: .moodBoard,
                item: .moodBoard(editableMoodBoard))
        }
        .sheet(isPresented: $showingTemplates) {
            // Note: TemplateLibraryView not found
            // TemplateLibraryView { template in
            //     applyTemplate(template)
            // }
            Text("Template library coming soon")
                .padding()
        }
    }






    // MARK: - Element Properties Section

    private func elementPropertiesSection(_ element: VisualElement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Element")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Delete") {
                    deleteSelectedElement()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }

            // Position and size
            VStack(alignment: .leading, spacing: 8) {
                Text("Position & Size")
                    .font(.caption)
                    .fontWeight(.medium)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("X")
                            .font(.caption2)
                        TextField(
                            "X",
                            value: Binding(
                                get: { element.position.x },
                                set: { if let newValue = $0 { updateElementPosition(x: CGFloat(newValue)) } }),
                            format: .number)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y")
                            .font(.caption2)
                        TextField(
                            "Y",
                            value: Binding(
                                get: { element.position.y },
                                set: { if let newValue = $0 { updateElementPosition(y: CGFloat(newValue)) } }),
                            format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Width")
                            .font(.caption2)
                        TextField(
                            "Width",
                            value: Binding(
                                get: { element.size.width },
                                set: { if let newValue = $0 { updateElementSize(width: CGFloat(newValue)) } }),
                            format: .number)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height")
                            .font(.caption2)
                        TextField(
                            "Height",
                            value: Binding(
                                get: { element.size.height },
                                set: { if let newValue = $0 { updateElementSize(height: CGFloat(newValue)) } }),
                            format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            // Rotation and opacity
            VStack(alignment: .leading, spacing: 8) {
                Text("Transform")
                    .font(.caption)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rotation: \(Int(element.rotation))°")
                        .font(.caption2)
                    Slider(value: Binding(
                        get: { element.rotation },
                        set: { updateElementRotation($0) }), in: 0 ... 360)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Opacity: \(Int(element.opacity * 100))%")
                        .font(.caption2)
                    Slider(value: Binding(
                        get: { element.opacity },
                        set: { updateElementOpacity($0) }), in: 0 ... 1)
                }
            }

            // Element-specific properties
            switch element.elementType {
            case .text:
                textElementProperties(element)
            case .color:
                colorElementProperties(element)
            case .image:
                imageElementProperties(element)
            case .inspiration:
                inspirationElementProperties(element)
            }
        }
    }

    // MARK: - Helper Computed Properties

    private var selectedElement: VisualElement? {
        guard let selectedElementId else { return nil }
        return editableMoodBoard.elements.first { $0.id == selectedElementId }
    }

    // MARK: - Helper Methods

    private func centerCanvas() {
        canvasOffset = .zero
        canvasScale = 1.0
    }

    private func fitCanvasToView() {
        canvasScale = 0.8
        canvasOffset = .zero
    }

    private func saveMoodBoard() {
        Task {
            var updatedMoodBoard = editableMoodBoard
            updatedMoodBoard.updatedAt = Date()
            await visualPlanningStore.updateMoodBoard(updatedMoodBoard)
            dismiss()
        }
    }

    private func undo() {
        if let previousState = historyManager.undo() {
            editableMoodBoard = previousState
        }
    }

    private func redo() {
        if let nextState = historyManager.redo() {
            editableMoodBoard = nextState
        }
    }

    private func updateElement(_ element: VisualElement) {
        if let index = editableMoodBoard.elements.firstIndex(where: { $0.id == element.id }) {
            editableMoodBoard.elements[index] = element
            historyManager.addSnapshot(editableMoodBoard)
        }
    }

    private func updateElementPosition(x: CGFloat? = nil, y: CGFloat? = nil) {
        guard let selectedElementId,
              let index = editableMoodBoard.elements.firstIndex(where: { $0.id == selectedElementId }) else { return }

        let currentPosition = editableMoodBoard.elements[index].position
        editableMoodBoard.elements[index].position = CGPoint(
            x: x ?? currentPosition.x,
            y: y ?? currentPosition.y)
        historyManager.addSnapshot(editableMoodBoard)
    }

    private func updateElementSize(width: CGFloat? = nil, height: CGFloat? = nil) {
        guard let selectedElementId,
              let index = editableMoodBoard.elements.firstIndex(where: { $0.id == selectedElementId }) else { return }

        let currentSize = editableMoodBoard.elements[index].size
        editableMoodBoard.elements[index].size = CGSize(
            width: width ?? currentSize.width,
            height: height ?? currentSize.height)
        historyManager.addSnapshot(editableMoodBoard)
    }

    private func updateElementRotation(_ rotation: Double) {
        guard let selectedElementId,
              let index = editableMoodBoard.elements.firstIndex(where: { $0.id == selectedElementId }) else { return }

        editableMoodBoard.elements[index].rotation = rotation
        historyManager.addSnapshot(editableMoodBoard)
    }

    private func updateElementOpacity(_ opacity: Double) {
        guard let selectedElementId,
              let index = editableMoodBoard.elements.firstIndex(where: { $0.id == selectedElementId }) else { return }

        editableMoodBoard.elements[index].opacity = opacity
        historyManager.addSnapshot(editableMoodBoard)
    }

    private func deleteSelectedElement() {
        guard let selectedElementId else { return }

        editableMoodBoard.elements.removeAll { $0.id == selectedElementId }
        self.selectedElementId = nil
        historyManager.addSnapshot(editableMoodBoard)
    }

    // Quick action methods
    private func addImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "Select an image to add to your mood board"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            // Get image dimensions
            guard let image = NSImage(contentsOf: url) else { return }
            let imageSize = image.size

            // Create a temporary local URL reference (in real app, upload to storage)
            let localPath = url.path

            let newElement = VisualElement(
                moodBoardId: editableMoodBoard.id,
                elementType: .image,
                elementData: VisualElement.ElementData(
                    imageUrl: localPath,
                    originalFilename: url.lastPathComponent,
                    fileSize: try? FileManager.default.attributesOfItem(atPath: localPath)[.size] as? Int64,
                    dimensions: imageSize
                ),
                position: CGPoint(x: 100, y: 100),
                size: imageSize,
                zIndex: editableMoodBoard.elements.count + 1
            )

            editableMoodBoard.elements.append(newElement)
            historyManager.addSnapshot(editableMoodBoard)
        }
    }

    private func addColorSwatch() {
        let newElement = VisualElement(
            moodBoardId: editableMoodBoard.id,
            elementType: .color,
            elementData: VisualElement.ElementData(color: .blue),
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 100, height: 100),
            zIndex: editableMoodBoard.elements.count + 1)
        editableMoodBoard.elements.append(newElement)
        historyManager.addSnapshot(editableMoodBoard)
    }

    private func addText() {
        let newElement = VisualElement(
            moodBoardId: editableMoodBoard.id,
            elementType: .text,
            elementData: VisualElement.ElementData(
                text: "New Text"),
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 150, height: 50),
            zIndex: editableMoodBoard.elements.count + 1)
        editableMoodBoard.elements.append(newElement)
        historyManager.addSnapshot(editableMoodBoard)
    }

    private func addInspiration() {
        let newElement = VisualElement(
            moodBoardId: editableMoodBoard.id,
            elementType: .inspiration,
            elementData: VisualElement.ElementData(text: "Inspiration note"),
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 120, height: 80),
            zIndex: editableMoodBoard.elements.count + 1)
        editableMoodBoard.elements.append(newElement)
        historyManager.addSnapshot(editableMoodBoard)
    }

    private func autoArrange() {
        // Implement automatic arrangement algorithm
        let margin: CGFloat = 20
        let spacing: CGFloat = 10
        let columns = Int(sqrt(Double(editableMoodBoard.elements.count)))
        _ = Int(ceil(Double(editableMoodBoard.elements.count) / Double(columns)))

        for (index, _) in editableMoodBoard.elements.enumerated() {
            let column = index % columns
            let row = index / columns

            let x = margin + CGFloat(column) * (150 + spacing)
            let y = margin + CGFloat(row) * (150 + spacing)

            editableMoodBoard.elements[index].position = CGPoint(x: x, y: y)
            editableMoodBoard.elements[index].size = CGSize(width: 150, height: 150)
        }

        historyManager.addSnapshot(editableMoodBoard)
    }

    private func applyTemplate(_ template: MoodBoardTemplate) {
        // Apply template settings to the current mood board
        editableMoodBoard.backgroundColor = template.templateMoodBoard.backgroundColor
        editableMoodBoard.canvasSize = template.templateMoodBoard.canvasSize
        editableMoodBoard.styleCategory = template.templateMoodBoard.styleCategory

        // Copy all elements from the template, generating new IDs
        let templateElements = template.templateMoodBoard.elements.map { templateElement in
            VisualElement(
                id: UUID(),
                moodBoardId: editableMoodBoard.id,
                elementType: templateElement.elementType,
                elementData: templateElement.elementData,
                position: templateElement.position,
                size: templateElement.size,
                rotation: templateElement.rotation,
                opacity: templateElement.opacity,
                zIndex: templateElement.zIndex,
                isLocked: templateElement.isLocked,
                notes: templateElement.notes
            )
        }

        // Append template elements to existing elements (or replace based on preference)
        editableMoodBoard.elements.append(contentsOf: templateElements)

        // Add to history for undo capability
        historyManager.addSnapshot(editableMoodBoard)
    }

    // Element-specific property sections (stubs for now)
    private func textElementProperties(_: VisualElement) -> some View {
        Text("Text properties")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func colorElementProperties(_: VisualElement) -> some View {
        Text("Color properties")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func imageElementProperties(_: VisualElement) -> some View {
        Text("Image properties")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func inspirationElementProperties(_: VisualElement) -> some View {
        Text("Inspiration properties")
            .font(.caption)
            .foregroundColor(.secondary)
    }

}

// MARK: - Supporting Types

enum EditorTool: CaseIterable {
    case select, pan, text, color, image, grid

    var title: String {
        switch self {
        case .select: "Select"
        case .pan: "Pan"
        case .text: "Text"
        case .color: "Color"
        case .image: "Image"
        case .grid: "Grid"
        }
    }

    var icon: String {
        switch self {
        case .select: "arrow.up.left"
        case .pan: "hand.draw"
        case .text: "textformat"
        case .color: "paintpalette"
        case .image: "photo"
        case .grid: "grid"
        }
    }
}

#Preview {
    let sampleMoodBoard = MoodBoard(
        tenantId: "sample",
        boardName: "Romantic Garden Wedding",
        boardDescription: "Soft and elegant mood board",
        styleCategory: .romantic,
        canvasSize: CGSize(width: 800, height: 600),
        backgroundColor: .white)

    return MoodBoardEditorView(moodBoard: sampleMoodBoard)
        .environmentObject(VisualPlanningStoreV2())
}
