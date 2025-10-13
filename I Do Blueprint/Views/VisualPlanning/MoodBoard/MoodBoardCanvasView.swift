//
//  MoodBoardCanvasView.swift
//  My Wedding Planning App
//
//  Interactive canvas for mood board editing
//

import SwiftUI
import UniformTypeIdentifiers

struct MoodBoardCanvasView: View {
    @Binding var moodBoard: MoodBoard
    @State private var selectedElementId: UUID?
    @State private var canvasOffset = CGSize.zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var isDragging = false
    @State private var dragOffset = CGSize.zero
    @State private var showGrid = true
    @State private var snapToGrid = true
    @State private var gridSize: CGFloat = 20

    let isEditable: Bool
    let onElementAdd: ((VisualElement) -> Void)?
    let onElementUpdate: ((UUID, VisualElement) -> Void)?
    let onElementDelete: ((UUID) -> Void)?
    let onElementSelect: ((UUID, Bool) -> Void)?

    init(
        moodBoard: Binding<MoodBoard>,
        isEditable: Bool = true,
        onElementAdd: ((VisualElement) -> Void)? = nil,
        onElementUpdate: ((UUID, VisualElement) -> Void)? = nil,
        onElementDelete: ((UUID) -> Void)? = nil,
        onElementSelect: ((UUID, Bool) -> Void)? = nil) {
        _moodBoard = moodBoard
        self.isEditable = isEditable
        self.onElementAdd = onElementAdd
        self.onElementUpdate = onElementUpdate
        self.onElementDelete = onElementDelete
        self.onElementSelect = onElementSelect
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Rectangle()
                    .fill(moodBoard.backgroundColor)
                    .frame(
                        width: moodBoard.canvasSize.width * canvasScale,
                        height: moodBoard.canvasSize.height * canvasScale)
                    .overlay(
                        // Grid overlay
                        GridOverlay(
                            gridSize: gridSize * canvasScale,
                            showGrid: showGrid,
                            canvasSize: moodBoard.canvasSize,
                            scale: canvasScale))
                    .onTapGesture {
                        if isEditable {
                            selectedElementId = nil
                            onElementSelect?(UUID(), false)
                        }
                    }

                // Elements
                ForEach(sortedElements) { element in
                    MoodBoardElementView(
                        element: element,
                        isSelected: selectedElementId == element.id,
                        isEditable: isEditable,
                        scale: canvasScale,
                        snapToGrid: snapToGrid,
                        gridSize: gridSize) { updatedElement in
                        updateElement(updatedElement)
                    }
                    .onTapGesture {
                        if isEditable {
                            selectedElementId = element.id
                            onElementSelect?(element.id, true)
                        }
                    }
                    .contextMenu {
                        if isEditable {
                            elementContextMenu(for: element)
                        }
                    }
                }
            }
            .frame(
                width: moodBoard.canvasSize.width * canvasScale,
                height: moodBoard.canvasSize.height * canvasScale)
            .offset(canvasOffset)
            .scaleEffect(canvasScale)
            .clipped()
            .gesture(
                SimultaneousGesture(
                    // Pan gesture for canvas
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                canvasOffset = value.translation
                            }
                        }
                        .onEnded { _ in
                            // Snap back if dragged too far
                            withAnimation(.spring()) {
                                canvasOffset = limitCanvasOffset(canvasOffset, in: geometry.size)
                            }
                        },

                    // Magnification gesture for zoom
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = max(0.1, min(3.0, value))
                            canvasScale = newScale
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                canvasScale = max(0.5, min(2.0, canvasScale))
                            }
                        }))
            .onDrop(of: [.image, .text], isTargeted: nil) { providers, location in
                handleDrop(providers: providers, location: location, in: geometry)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if isEditable {
                    canvasToolbar
                }
            }
        }
    }

    // MARK: - Canvas Toolbar

    private var canvasToolbar: some View {
        HStack {
            // Grid controls
            Button(action: { showGrid.toggle() }) {
                Image(systemName: showGrid ? "grid" : "grid")
                    .foregroundColor(showGrid ? .blue : .secondary)
            }
            .help("Toggle Grid")

            Button(action: { snapToGrid.toggle() }) {
                Image(systemName: "magnet")
                    .foregroundColor(snapToGrid ? .blue : .secondary)
            }
            .help("Snap to Grid")

            Divider()

            // Zoom controls
            Button(action: { zoomOut() }) {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")

            Text("\(Int(canvasScale * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40)

            Button(action: { zoomIn() }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")

            Button(action: { resetZoom() }) {
                Image(systemName: "1.magnifyingglass")
            }
            .help("Reset Zoom")

            Divider()

            // Selection tools
            if let selectedId = selectedElementId,
               let selectedElement = moodBoard.elements.first(where: { $0.id == selectedId }) {
                Button(action: { duplicateElement(selectedElement) }) {
                    Image(systemName: "doc.on.doc")
                }
                .help("Duplicate Element")

                Button(action: { deleteElement(selectedId) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .help("Delete Element")

                Button(action: { bringToFront(selectedId) }) {
                    Image(systemName: "arrow.up.to.line")
                }
                .help("Bring to Front")

                Button(action: { sendToBack(selectedId) }) {
                    Image(systemName: "arrow.down.to.line")
                }
                .help("Send to Back")
            }
        }
    }

    // MARK: - Helper Properties

    private var sortedElements: [VisualElement] {
        moodBoard.elements.sorted { $0.zIndex < $1.zIndex }
    }

    // MARK: - Element Management

    private func updateElement(_ element: VisualElement) {
        if let index = moodBoard.elements.firstIndex(where: { $0.id == element.id }) {
            var updatedElement = element
            updatedElement.updatedAt = Date()
            moodBoard.elements[index] = updatedElement
            onElementUpdate?(element.id, updatedElement)
        }
    }

    private func duplicateElement(_ element: VisualElement) {
        // Create new element with new ID since id is immutable
        let duplicate = VisualElement(
            id: UUID(),
            moodBoardId: element.moodBoardId,
            elementType: element.elementType,
            elementData: element.elementData,
            position: CGPoint(x: element.position.x + 20, y: element.position.y + 20),
            size: element.size,
            rotation: element.rotation,
            opacity: element.opacity,
            zIndex: (moodBoard.elements.map(\.zIndex).max() ?? 0) + 1)

        moodBoard.elements.append(duplicate)
        onElementAdd?(duplicate)
        selectedElementId = duplicate.id
    }

    private func deleteElement(_ elementId: UUID) {
        moodBoard.elements.removeAll { $0.id == elementId }
        onElementDelete?(elementId)
        if selectedElementId == elementId {
            selectedElementId = nil
        }
    }

    private func bringToFront(_ elementId: UUID) {
        guard let index = moodBoard.elements.firstIndex(where: { $0.id == elementId }) else { return }
        let maxZIndex = moodBoard.elements.map(\.zIndex).max() ?? 0
        moodBoard.elements[index].zIndex = maxZIndex + 1
        moodBoard.elements[index].updatedAt = Date()
    }

    private func sendToBack(_ elementId: UUID) {
        guard let index = moodBoard.elements.firstIndex(where: { $0.id == elementId }) else { return }
        let minZIndex = moodBoard.elements.map(\.zIndex).min() ?? 0
        moodBoard.elements[index].zIndex = minZIndex - 1
        moodBoard.elements[index].updatedAt = Date()
    }

    // MARK: - Canvas Controls

    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            canvasScale = min(3.0, canvasScale * 1.2)
        }
    }

    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            canvasScale = max(0.1, canvasScale / 1.2)
        }
    }

    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.3)) {
            canvasScale = 1.0
            canvasOffset = .zero
        }
    }

    private func limitCanvasOffset(_ offset: CGSize, in containerSize: CGSize) -> CGSize {
        let canvasDisplaySize = CGSize(
            width: moodBoard.canvasSize.width * canvasScale,
            height: moodBoard.canvasSize.height * canvasScale)

        let maxX = max(0, (canvasDisplaySize.width - containerSize.width) / 2)
        let maxY = max(0, (canvasDisplaySize.height - containerSize.height) / 2)

        return CGSize(
            width: max(-maxX, min(maxX, offset.width)),
            height: max(-maxY, min(maxY, offset.height)))
    }

    // MARK: - Context Menu

    private func elementContextMenu(for element: VisualElement) -> some View {
        Group {
            Button("Duplicate") {
                duplicateElement(element)
            }

            Button("Bring to Front") {
                bringToFront(element.id)
            }

            Button("Send to Back") {
                sendToBack(element.id)
            }

            Divider()

            Button("Lock/Unlock") {
                if let index = moodBoard.elements.firstIndex(where: { $0.id == element.id }) {
                    moodBoard.elements[index].isLocked.toggle()
                    moodBoard.elements[index].updatedAt = Date()
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                deleteElement(element.id)
            }
        }
    }

    // MARK: - Drag & Drop Handling

    private func handleDrop(providers: [NSItemProvider], location: CGPoint, in _: GeometryProxy) -> Bool {
        guard isEditable else { return false }

        // Convert location to canvas coordinates
        let canvasLocation = CGPoint(
            x: (location.x - canvasOffset.width) / canvasScale,
            y: (location.y - canvasOffset.height) / canvasScale)

        // Handle image drops
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                provider.loadItem(forTypeIdentifier: "public.image", options: nil) { item, _ in
                    DispatchQueue.main.async {
                        if let data = item as? Data,
                           let nsImage = NSImage(data: data) {
                            createImageElement(from: nsImage, at: canvasLocation)
                        } else if let url = item as? URL {
                            if let nsImage = NSImage(contentsOf: url) {
                                createImageElement(from: nsImage, at: canvasLocation)
                            }
                        }
                    }
                }
                return true
            }
        }

        return false
    }

    private func createImageElement(from nsImage: NSImage, at location: CGPoint) {
        // Convert NSImage to data URL for storage
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

        let base64String = pngData.base64EncodedString()
        let dataURL = "data:image/png;base64,\(base64String)"

        let element = VisualElement(
            moodBoardId: moodBoard.id,
            elementType: .image,
            elementData: VisualElement.ElementData(
                imageUrl: dataURL,
                originalFilename: "Dropped Image",
                fileSize: Int64(pngData.count),
                dimensions: nsImage.size,
                alt: "Dropped image"),
            position: snapToGrid ? snapToGridPosition(location) : location,
            size: CGSize(
                width: min(200, nsImage.size.width),
                height: min(200, nsImage.size.height)),
            zIndex: (moodBoard.elements.map(\.zIndex).max() ?? 0) + 1)

        moodBoard.elements.append(element)
        onElementAdd?(element)
        selectedElementId = element.id
    }

    private func snapToGridPosition(_ position: CGPoint) -> CGPoint {
        CGPoint(
            x: round(position.x / gridSize) * gridSize,
            y: round(position.y / gridSize) * gridSize)
    }
}

// MARK: - Grid Overlay

struct GridOverlay: View {
    let gridSize: CGFloat
    let showGrid: Bool
    let canvasSize: CGSize
    let scale: CGFloat

    var body: some View {
        if showGrid {
            Canvas { context, _ in
                let adjustedGridSize = gridSize

                // Vertical lines
                var x: CGFloat = 0
                while x <= canvasSize.width * scale {
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: canvasSize.height * scale))
                        },
                        with: .color(.gray.opacity(0.3)),
                        lineWidth: 0.5)
                    x += adjustedGridSize
                }

                // Horizontal lines
                var y: CGFloat = 0
                while y <= canvasSize.height * scale {
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: canvasSize.width * scale, y: y))
                        },
                        with: .color(.gray.opacity(0.3)),
                        lineWidth: 0.5)
                    y += adjustedGridSize
                }
            }
        }
    }
}

#Preview {
    @State var sampleMoodBoard = MoodBoard(
        tenantId: "preview",
        boardName: "Sample Board",
        styleCategory: .romantic,
        canvasSize: CGSize(width: 800, height: 600),
        backgroundColor: .white)

    return MoodBoardCanvasView(moodBoard: $sampleMoodBoard)
        .frame(width: 1000, height: 700)
}
