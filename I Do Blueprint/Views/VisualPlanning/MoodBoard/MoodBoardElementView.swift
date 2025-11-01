//
//  MoodBoardElementView.swift
//  My Wedding Planning App
//
//  Individual element view with manipulation controls
//

import SwiftUI

struct MoodBoardElementView: View {
    let element: VisualElement
    let isSelected: Bool
    let isEditable: Bool
    let scale: CGFloat
    let snapToGrid: Bool
    let gridSize: CGFloat
    let onUpdate: (VisualElement) -> Void

    @State private var currentPosition: CGPoint
    @State private var currentSize: CGSize
    @State private var currentRotation: Double
    @State private var isDragging = false
    @State private var isResizing = false

    init(
        element: VisualElement,
        isSelected: Bool = false,
        isEditable: Bool = true,
        scale: CGFloat = 1.0,
        snapToGrid: Bool = false,
        gridSize: CGFloat = 20,
        onUpdate: @escaping (VisualElement) -> Void) {
        self.element = element
        self.isSelected = isSelected
        self.isEditable = isEditable
        self.scale = scale
        self.snapToGrid = snapToGrid
        self.gridSize = gridSize
        self.onUpdate = onUpdate

        _currentPosition = State(initialValue: element.position)
        _currentSize = State(initialValue: element.size)
        _currentRotation = State(initialValue: element.rotation)
    }

    var body: some View {
        ZStack {
            // Element content
            elementContent
                .frame(width: currentSize.width, height: currentSize.height)
                .opacity(element.opacity)
                .rotationEffect(.degrees(currentRotation))
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isDragging)

            // Selection outline and controls
            if isSelected, isEditable {
                selectionOverlay
            }
        }
        .position(currentPosition)
        .gesture(
            isEditable && !element.isLocked ? elementGestures : nil)
        .onAppear {
            syncWithElement()
        }
        .onChange(of: element.position) { _, newPosition in
            currentPosition = newPosition
        }
        .onChange(of: element.size) { _, newSize in
            currentSize = newSize
        }
        .onChange(of: element.rotation) { _, newRotation in
            currentRotation = newRotation
        }
    }

    // MARK: - Element Content

    @ViewBuilder
    private var elementContent: some View {
        switch element.elementType {
        case .image:
            imageContent
        case .color:
            colorContent
        case .text:
            textContent
        case .inspiration:
            inspirationContent
        }
    }

    private var imageContent: some View {
        Group {
            if let imageUrl = element.elementData.imageUrl {
                if imageUrl.hasPrefix("data:image") {
                    // Base64 encoded image
                    if let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
                       // Remove "data:image/png;base64,"
                       let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } else {
                        placeholderImage
                    }
                } else {
                    // URL-based image
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } placeholder: {
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .background(AppColors.textSecondary.opacity(0.1))
        .cornerRadius(8)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(AppColors.textSecondary.opacity(0.3))
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(AppColors.textSecondary))
            .cornerRadius(8)
    }

    private var colorContent: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(element.elementData.color ?? .gray)
            .stroke(AppColors.textPrimary.opacity(0.2), lineWidth: 1)
    }

    private var textContent: some View {
        Text(element.elementData.text ?? "Text")
            .font(.system(
                size: element.elementData.fontSize ?? 16,
                design: .default))
            .multilineTextAlignment(.center)
            .padding(Spacing.sm)
            .background(AppColors.textPrimary.opacity(0.9))
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var inspirationContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.title)
                .foregroundColor(.yellow)

            if let text = element.elementData.text {
                Text(text)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2))
    }

    // MARK: - Selection Overlay

    private var selectionOverlay: some View {
        ZStack {
            // Selection outline
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue, lineWidth: 2)
                .fill(Color.clear)
                .frame(width: currentSize.width + 8, height: currentSize.height + 8)

            // Resize handles
            Group {
                // Corner handles
                resizeHandle(at: .topLeading)
                resizeHandle(at: .topTrailing)
                resizeHandle(at: .bottomLeading)
                resizeHandle(at: .bottomTrailing)

                // Edge handles
                resizeHandle(at: .top)
                resizeHandle(at: .bottom)
                resizeHandle(at: .leading)
                resizeHandle(at: .trailing)
            }

            // Rotation handle
            rotationHandle
                .offset(y: -(currentSize.height / 2 + 25))

            // Lock indicator
            if element.isLocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.red)
                    .background(Circle().fill(AppColors.textPrimary))
                    .offset(x: currentSize.width / 2, y: -currentSize.height / 2)
            }
        }
    }

    private func resizeHandle(at position: HandlePosition) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
            .offset(handleOffset(for: position))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleResize(value: value, position: position)
                    }
                    .onEnded { _ in
                        commitChanges()
                    })
    }

    private var rotationHandle: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 10, height: 10)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleRotation(value: value)
                    }
                    .onEnded { _ in
                        commitChanges()
                    })
    }

    // MARK: - Gestures

    private var elementGestures: some Gesture {
        SimultaneousGesture(
            // Drag gesture for moving
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newPosition = CGPoint(
                        x: element.position.x + value.translation.width,
                        y: element.position.y + value.translation.height)
                    currentPosition = snapToGrid ? snapToGridPosition(newPosition) : newPosition
                }
                .onEnded { _ in
                    isDragging = false
                    commitChanges()
                },

            // Rotation gesture
            RotationGesture()
                .onChanged { value in
                    currentRotation = element.rotation + value.degrees
                }
                .onEnded { _ in
                    commitChanges()
                })
    }

    // MARK: - Handle Calculations

    enum HandlePosition {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
        case top, bottom, leading, trailing
    }

    private func handleOffset(for position: HandlePosition) -> CGSize {
        let halfWidth = currentSize.width / 2
        let halfHeight = currentSize.height / 2

        switch position {
        case .topLeading:
            return CGSize(width: -halfWidth - 4, height: -halfHeight - 4)
        case .topTrailing:
            return CGSize(width: halfWidth + 4, height: -halfHeight - 4)
        case .bottomLeading:
            return CGSize(width: -halfWidth - 4, height: halfHeight + 4)
        case .bottomTrailing:
            return CGSize(width: halfWidth + 4, height: halfHeight + 4)
        case .top:
            return CGSize(width: 0, height: -halfHeight - 4)
        case .bottom:
            return CGSize(width: 0, height: halfHeight + 4)
        case .leading:
            return CGSize(width: -halfWidth - 4, height: 0)
        case .trailing:
            return CGSize(width: halfWidth + 4, height: 0)
        }
    }

    // MARK: - Manipulation Handlers

    private func handleResize(value: DragGesture.Value, position: HandlePosition) {
        let translation = value.translation
        var newSize = currentSize

        switch position {
        case .topLeading:
            newSize.width = max(20, currentSize.width - translation.width)
            newSize.height = max(20, currentSize.height - translation.height)
        case .topTrailing:
            newSize.width = max(20, currentSize.width + translation.width)
            newSize.height = max(20, currentSize.height - translation.height)
        case .bottomLeading:
            newSize.width = max(20, currentSize.width - translation.width)
            newSize.height = max(20, currentSize.height + translation.height)
        case .bottomTrailing:
            newSize.width = max(20, currentSize.width + translation.width)
            newSize.height = max(20, currentSize.height + translation.height)
        case .top:
            newSize.height = max(20, currentSize.height - translation.height)
        case .bottom:
            newSize.height = max(20, currentSize.height + translation.height)
        case .leading:
            newSize.width = max(20, currentSize.width - translation.width)
        case .trailing:
            newSize.width = max(20, currentSize.width + translation.width)
        }

        currentSize = newSize
    }

    private func handleRotation(value: DragGesture.Value) {
        let center = CGPoint(x: currentPosition.x, y: currentPosition.y)
        let point = CGPoint(
            x: center.x + value.translation.width,
            y: center.y + value.translation.height)

        let angle = atan2(point.y - center.y, point.x - center.x) * 180 / .pi
        currentRotation = angle
    }

    // MARK: - Utility Functions

    private func snapToGridPosition(_ position: CGPoint) -> CGPoint {
        CGPoint(
            x: round(position.x / gridSize) * gridSize,
            y: round(position.y / gridSize) * gridSize)
    }

    private func syncWithElement() {
        currentPosition = element.position
        currentSize = element.size
        currentRotation = element.rotation
    }

    private func commitChanges() {
        var updatedElement = element
        updatedElement.position = currentPosition
        updatedElement.size = currentSize
        updatedElement.rotation = currentRotation
        updatedElement.updatedAt = Date()

        onUpdate(updatedElement)
    }
}

#Preview {
    let sampleElement = VisualElement(
        moodBoardId: UUID(),
        elementType: .color,
        elementData: VisualElement.ElementData(color: .blue),
        position: CGPoint(x: 200, y: 200),
        size: CGSize(width: 100, height: 100))

    MoodBoardElementView(
        element: sampleElement,
        isSelected: true,
        onUpdate: { _ in })
        .frame(width: 400, height: 400)
}
