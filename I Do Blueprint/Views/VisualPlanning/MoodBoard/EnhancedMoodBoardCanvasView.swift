//
//  EnhancedMoodBoardCanvasView.swift
//  My Wedding Planning App
//
//  Enhanced mood board canvas with advanced editing capabilities
//

import SwiftUI
import UniformTypeIdentifiers

struct EnhancedMoodBoardCanvasView: View {
    @Binding var moodBoard: MoodBoard
    @Binding var selectedElementId: UUID?
    let selectedTool: EditorTool
    let canvasScale: CGFloat
    let canvasOffset: CGPoint
    let onElementChanged: (VisualElement) -> Void
    let onCanvasChanged: (MoodBoard) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var showingElementMenu = false
    @State private var menuPosition: CGPoint = .zero
    @State private var copiedElement: VisualElement?

    var body: some View {
        Canvas { context, _ in
            // Draw canvas background if needed
            context.fill(
                Path(CGRect(origin: .zero, size: moodBoard.canvasSize)),
                with: .color(moodBoard.backgroundColor))
        }
        .overlay(
            // Elements layer
            ForEach(moodBoard.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                EnhancedMoodBoardElementView(
                    element: element,
                    isSelected: selectedElementId == element.id,
                    selectedTool: selectedTool,
                    canvasScale: canvasScale,
                    onElementChanged: { updatedElement in
                        onElementChanged(updatedElement)
                    },
                    onSelectionChanged: { elementId in
                        selectedElementId = elementId
                    },
                    onContextMenu: { position in
                        showContextMenu(at: position, for: element)
                    },
                    onDuplicate: {
                        selectedElementId = element.id
                        duplicateElement()
                    },
                    onDelete: {
                        selectedElementId = element.id
                        deleteElement()
                    },
                    onBringToFront: {
                        selectedElementId = element.id
                        bringToFront()
                    },
                    onSendToBack: {
                        selectedElementId = element.id
                        sendToBack()
                    })
            })
        .contextMenu {
            canvasContextMenu
        }
        .onTapGesture { location in
            if selectedTool == .select {
                // Deselect if tapping on empty space
                selectedElementId = nil
            } else {
                // Handle tool-specific actions
                handleCanvasTap(at: location)
            }
        }
        .popover(isPresented: $showingElementMenu, arrowEdge: .top) {
            ElementContextMenu(
                element: selectedElement,
                onCopy: copySelectedElement,
                onDuplicate: duplicateElement,
                onDelete: deleteElement,
                onBringToFront: bringToFront,
                onSendToBack: sendToBack)
        }
    }

    private var selectedElement: VisualElement? {
        guard let selectedElementId else { return nil }
        return moodBoard.elements.first { $0.id == selectedElementId }
    }

    private var canvasContextMenu: some View {
        VStack {
            Button("Paste", action: paste)
            Button("Select All", action: selectAll)
            Divider()
            Button("Add Image", action: addImage)
            Button("Add Text", action: addText)
            Button("Add Color", action: addColor)
        }
    }

    private func handleCanvasTap(at location: CGPoint) {
        switch selectedTool {
        case .text:
            addTextAtLocation(location)
        case .color:
            addColorAtLocation(location)
        case .image:
            addImageAtLocation(location)
        default:
            break
        }
    }

    private func showContextMenu(at position: CGPoint, for element: VisualElement) {
        selectedElementId = element.id
        menuPosition = position
        showingElementMenu = true
    }

    // MARK: - Element Actions

    private func duplicateElement() {
        guard let selectedElement else { return }

        let duplicatedElement = VisualElement(
            id: UUID(),
            moodBoardId: selectedElement.moodBoardId,
            elementType: selectedElement.elementType,
            elementData: selectedElement.elementData,
            position: CGPoint(
                x: selectedElement.position.x + 20,
                y: selectedElement.position.y + 20),
            size: selectedElement.size,
            rotation: selectedElement.rotation,
            opacity: selectedElement.opacity,
            zIndex: (moodBoard.elements.map(\.zIndex).max() ?? 0) + 1)

        moodBoard.elements.append(duplicatedElement)
        selectedElementId = duplicatedElement.id
        onCanvasChanged(moodBoard)
    }

    private func deleteElement() {
        guard let selectedElementId else { return }

        moodBoard.elements.removeAll { $0.id == selectedElementId }
        self.selectedElementId = nil
        onCanvasChanged(moodBoard)
    }

    private func bringToFront() {
        guard let selectedElementId,
              let index = moodBoard.elements.firstIndex(where: { $0.id == selectedElementId }) else { return }

        let maxZIndex = moodBoard.elements.map(\.zIndex).max() ?? 0
        moodBoard.elements[index].zIndex = maxZIndex + 1
        onCanvasChanged(moodBoard)
    }

    private func sendToBack() {
        guard let selectedElementId,
              let index = moodBoard.elements.firstIndex(where: { $0.id == selectedElementId }) else { return }

        let minZIndex = moodBoard.elements.map(\.zIndex).min() ?? 0
        moodBoard.elements[index].zIndex = minZIndex - 1
        onCanvasChanged(moodBoard)
    }

    // MARK: - Canvas Actions

    private func copySelectedElement() {
        guard let selectedElement else { return }
        copiedElement = selectedElement
    }

    private func paste() {
        guard let copiedElement else { return }

        // Create a new element based on the copied one
        let pastedElement = VisualElement(
            id: UUID(),
            moodBoardId: copiedElement.moodBoardId,
            elementType: copiedElement.elementType,
            elementData: copiedElement.elementData,
            position: CGPoint(
                x: copiedElement.position.x + 20,
                y: copiedElement.position.y + 20),
            size: copiedElement.size,
            rotation: copiedElement.rotation,
            opacity: copiedElement.opacity,
            zIndex: (moodBoard.elements.map(\.zIndex).max() ?? 0) + 1,
            isLocked: false,
            notes: copiedElement.notes
        )

        moodBoard.elements.append(pastedElement)
        selectedElementId = pastedElement.id
        onCanvasChanged(moodBoard)
    }

    private func selectAll() {
        // In this implementation, we'll select the last element as a simple approach
        // A more complete implementation would support multi-selection
        if let lastElement = moodBoard.elements.last {
            selectedElementId = lastElement.id
        }
    }

    private func addImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "Select an image to add to your mood board"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            self.addImageAtLocation(CGPoint(x: 100, y: 100), url: url)
        }
    }

    private func addText() {
        addTextAtLocation(CGPoint(x: 100, y: 100))
    }

    private func addColor() {
        addColorAtLocation(CGPoint(x: 100, y: 100))
    }

    private func addTextAtLocation(_ location: CGPoint) {
        let newElement = VisualElement(
            moodBoardId: moodBoard.id,
            elementType: .text,
            elementData: VisualElement.ElementData(
                text: "New Text"),
            position: location,
            size: CGSize(width: 150, height: 50),
            zIndex: (moodBoard.elements.map(\.zIndex).max() ?? 0) + 1)

        moodBoard.elements.append(newElement)
        selectedElementId = newElement.id
        onCanvasChanged(moodBoard)
    }

    private func addColorAtLocation(_ location: CGPoint) {
        let newElement = VisualElement(
            moodBoardId: moodBoard.id,
            elementType: .color,
            elementData: VisualElement.ElementData(color: .blue),
            position: location,
            size: CGSize(width: 100, height: 100),
            zIndex: (moodBoard.elements.map(\.zIndex).max() ?? 0) + 1)

        moodBoard.elements.append(newElement)
        selectedElementId = newElement.id
        onCanvasChanged(moodBoard)
    }

    private func addImageAtLocation(_ location: CGPoint, url: URL? = nil) {
        if let url = url {
            // Image URL was provided, add it directly
            guard let image = NSImage(contentsOf: url) else { return }
            let imageSize = image.size

            // Create a temporary local URL reference (in real app, upload to storage)
            let localPath = url.path

            let newElement = VisualElement(
                moodBoardId: moodBoard.id,
                elementType: .image,
                elementData: VisualElement.ElementData(
                    imageUrl: localPath,
                    originalFilename: url.lastPathComponent,
                    fileSize: try? FileManager.default.attributesOfItem(atPath: localPath)[.size] as? Int64,
                    dimensions: imageSize
                ),
                position: location,
                size: imageSize,
                zIndex: (moodBoard.elements.map(\.zIndex).max() ?? 0) + 1
            )

            moodBoard.elements.append(newElement)
            selectedElementId = newElement.id
            onCanvasChanged(moodBoard)
        } else {
            // Show image picker
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.image]
            panel.message = "Select an image to add to your mood board"

            panel.begin { response in
                guard response == .OK, let selectedUrl = panel.url else { return }
                self.addImageAtLocation(location, url: selectedUrl)
            }
        }
    }
}

// MARK: - Enhanced Element View

struct EnhancedMoodBoardElementView: View {
    let element: VisualElement
    let isSelected: Bool
    let selectedTool: EditorTool
    let canvasScale: CGFloat
    let onElementChanged: (VisualElement) -> Void
    let onSelectionChanged: (UUID?) -> Void
    let onContextMenu: (CGPoint) -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onBringToFront: () -> Void
    let onSendToBack: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var initialSize: CGSize = .zero
    @State private var resizeHandle: ResizeHandle = .bottomRight

    var body: some View {
        ZStack {
            // Main element content
            elementContent
                .frame(width: element.size.width, height: element.size.height)
                .rotationEffect(.degrees(element.rotation))
                .opacity(element.opacity)
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: isSelected ? 4 : 0)

            // Selection overlay
            if isSelected {
                selectionOverlay
            }
        }
        .position(element.position)
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if selectedTool == .select, !isResizing {
                        isDragging = true
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if selectedTool == .select, !isResizing {
                        var updatedElement = element
                        updatedElement.position = CGPoint(
                            x: element.position.x + value.translation.width / canvasScale,
                            y: element.position.y + value.translation.height / canvasScale)
                        onElementChanged(updatedElement)
                        dragOffset = .zero
                        isDragging = false
                    }
                })
        .onTapGesture {
            if selectedTool == .select {
                onSelectionChanged(element.id)
            }
        }
        .contextMenu {
            Button("Duplicate", action: onDuplicate)
            Button("Delete", role: .destructive, action: onDelete)
            Divider()
            Button("Bring to Front", action: onBringToFront)
            Button("Send to Back", action: onSendToBack)
        }
    }

    @ViewBuilder
    private var elementContent: some View {
        switch element.elementType {
        case .image:
            if let imageUrl = element.elementData.imageUrl,
               let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.textSecondary.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.textSecondary))
            }

        case .color:
            RoundedRectangle(cornerRadius: 8)
                .fill(element.elementData.color ?? .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))

        case .text:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.textPrimary.opacity(0.8))

                Text(element.elementData.text ?? "Text")
                    .font(.system(size: max(10, element.size.height * 0.3)))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.xs)
            }

        case .inspiration:
            VStack(spacing: 4) {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text(element.elementData.text ?? "Inspiration")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.sm)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var selectionOverlay: some View {
        ZStack {
            // Selection border
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: element.size.width + 4, height: element.size.height + 4)

            // Resize handles
            if selectedTool == .select {
                Group {
                    resizeHandleView(.topLeft)
                        .position(x: -2, y: -2)

                    resizeHandleView(.topRight)
                        .position(x: element.size.width + 2, y: -2)

                    resizeHandleView(.bottomLeft)
                        .position(x: -2, y: element.size.height + 2)

                    resizeHandleView(.bottomRight)
                        .position(x: element.size.width + 2, y: element.size.height + 2)

                    // Side handles
                    resizeHandleView(.top)
                        .position(x: element.size.width / 2, y: -2)

                    resizeHandleView(.bottom)
                        .position(x: element.size.width / 2, y: element.size.height + 2)

                    resizeHandleView(.left)
                        .position(x: -2, y: element.size.height / 2)

                    resizeHandleView(.right)
                        .position(x: element.size.width + 2, y: element.size.height / 2)
                }
            }
        }
        .position(element.position)
    }

    private func resizeHandleView(_ handle: ResizeHandle) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isResizing {
                            isResizing = true
                            initialSize = element.size
                            resizeHandle = handle
                        }
                        handleResize(value, for: handle)
                    }
                    .onEnded { _ in
                        isResizing = false
                    })
    }

    private func handleResize(_ value: DragGesture.Value, for handle: ResizeHandle) {
        var newSize = initialSize

        switch handle {
        case .bottomRight:
            newSize.width = max(20, initialSize.width + value.translation.width / canvasScale)
            newSize.height = max(20, initialSize.height + value.translation.height / canvasScale)

        case .topLeft:
            newSize.width = max(20, initialSize.width - value.translation.width / canvasScale)
            newSize.height = max(20, initialSize.height - value.translation.height / canvasScale)

        case .topRight:
            newSize.width = max(20, initialSize.width + value.translation.width / canvasScale)
            newSize.height = max(20, initialSize.height - value.translation.height / canvasScale)

        case .bottomLeft:
            newSize.width = max(20, initialSize.width - value.translation.width / canvasScale)
            newSize.height = max(20, initialSize.height + value.translation.height / canvasScale)

        case .top:
            newSize.height = max(20, initialSize.height - value.translation.height / canvasScale)

        case .bottom:
            newSize.height = max(20, initialSize.height + value.translation.height / canvasScale)

        case .left:
            newSize.width = max(20, initialSize.width - value.translation.width / canvasScale)

        case .right:
            newSize.width = max(20, initialSize.width + value.translation.width / canvasScale)
        }

        var updatedElement = element
        updatedElement.size = newSize
        onElementChanged(updatedElement)
    }
}

// MARK: - Supporting Types

enum ResizeHandle {
    case topLeft, topRight, bottomLeft, bottomRight
    case top, bottom, left, right
}

struct ElementContextMenu: View {
    let element: VisualElement?
    let onCopy: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onBringToFront: () -> Void
    let onSendToBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Copy", action: onCopy)
            Button("Duplicate", action: onDuplicate)
            Button("Delete", action: onDelete)
            Divider()
            Button("Bring to Front", action: onBringToFront)
            Button("Send to Back", action: onSendToBack)
        }
        .padding()
    }
}

#Preview {
    let sampleMoodBoard = MoodBoard(
        tenantId: "sample",
        boardName: "Test Board",
        boardDescription: "",
        styleCategory: .modern,
        canvasSize: CGSize(width: 800, height: 600),
        backgroundColor: .white)

    return EnhancedMoodBoardCanvasView(
        moodBoard: .constant(sampleMoodBoard),
        selectedElementId: .constant(nil),
        selectedTool: .select,
        canvasScale: 1.0,
        canvasOffset: .zero,
        onElementChanged: { _ in },
        onCanvasChanged: { _ in })
        .frame(width: 800, height: 600)
}
