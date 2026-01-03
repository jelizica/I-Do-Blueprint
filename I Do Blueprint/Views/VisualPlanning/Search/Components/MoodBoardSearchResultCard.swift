//
//  MoodBoardSearchResultCard.swift
//  I Do Blueprint
//
//  Search result card for mood boards
//

import SwiftUI

struct MoodBoardSearchResultCard: View {
    private let logger = AppLogger.ui
    let moodBoard: MoodBoard
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Preview/Thumbnail
                moodBoardPreview
                    .frame(height: 180)
                    .clipped()

                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(moodBoard.boardName)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    // Description
                    if let description = moodBoard.boardDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // Metadata row
                    HStack(spacing: 12) {
                        // Style category
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text(moodBoard.styleCategory.rawValue.capitalized)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)

                        Spacer()

                        // Element count
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2")
                                .font(.caption2)
                            Text("\(moodBoard.elements.count)")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)

                        // Template badge
                        if moodBoard.isTemplate {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.caption2)
                                Text("Template")
                                    .font(.caption2)
                            }
                            .foregroundColor(.purple)
                        }
                    }

                    // Tags
                    if !moodBoard.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(moodBoard.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, Spacing.xxs)
                                        .background(SemanticColors.textSecondary.opacity(Opacity.subtle))
                                        .cornerRadius(4)
                                }

                                if moodBoard.tags.count > 3 {
                                    Text("+\(moodBoard.tags.count - 3)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Date
                    Text(moodBoard.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.md)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: SemanticColors.textPrimary.opacity(isHovered ? Opacity.subtle : Opacity.verySubtle), radius: isHovered ? 8 : 4, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Preview

    private var moodBoardPreview: some View {
        ZStack {
            // Background
            moodBoard.backgroundColor

            // Background image if available
            if let backgroundImage = moodBoard.backgroundImage {
                AsyncImage(url: URL(string: backgroundImage)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderPreview
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderPreview
                    }
                }
            } else if !moodBoard.elements.isEmpty {
                // Show element preview
                elementsPreview
            } else {
                // Empty state
                placeholderPreview
            }

            // Overlay gradient for better text visibility
            LinearGradient(
                colors: [SemanticColors.textPrimary.opacity(Opacity.light), Color.clear],
                startPoint: .bottom,
                endPoint: .center
            )
        }
    }

    private var elementsPreview: some View {
        GeometryReader { geometry in
            ZStack {
                // Show up to 4 elements as a preview
                ForEach(Array(moodBoard.elements.prefix(4).enumerated()), id: \.element.id) { index, element in
                    elementThumbnail(element, index: index, in: geometry.size)
                }

                // Element count overlay
                if moodBoard.elements.count > 4 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("+\(moodBoard.elements.count - 4)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(SemanticColors.textPrimary)
                                .padding(Spacing.sm)
                                .background(SemanticColors.textPrimary.opacity(Opacity.medium))
                                .cornerRadius(8)
                                .padding(Spacing.sm)
                        }
                    }
                }
            }
        }
    }

    private func elementThumbnail(_ element: VisualElement, index: Int, in size: CGSize) -> some View {
        let positions: [CGPoint] = [
            CGPoint(x: size.width * 0.25, y: size.height * 0.25),
            CGPoint(x: size.width * 0.75, y: size.height * 0.25),
            CGPoint(x: size.width * 0.25, y: size.height * 0.75),
            CGPoint(x: size.width * 0.75, y: size.height * 0.75)
        ]

        let position = positions[min(index, positions.count - 1)]

        let content: AnyView

        switch element.elementType {
        case .image:
            if let imageUrl = element.elementData.imageUrl, let url = URL(string: imageUrl) {
                content = AnyView(
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            elementPlaceholder
                        }
                    }
                )
            } else {
                content = AnyView(elementPlaceholder)
            }
        case .text:
            content = AnyView(
                Text(element.elementData.text ?? "Text")
                    .font(.caption)
                    .lineLimit(2)
                    .frame(width: 60, height: 60)
                    .background(SemanticColors.textPrimary.opacity(Opacity.strong))
                    .cornerRadius(8)
            )
        case .color:
            content = AnyView(
                RoundedRectangle(cornerRadius: 8)
                    .fill(element.elementData.color ?? .gray)
                    .frame(width: 60, height: 60)
            )
        case .inspiration:
            content = AnyView(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "lightbulb")
                            .foregroundColor(.blue)
                    )
            )
        }

        return content.position(position)
    }

    private var elementPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(SemanticColors.textSecondary.opacity(Opacity.light))
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(SemanticColors.textSecondary)
            )
    }

    private var placeholderPreview: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Preview")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.textSecondary.opacity(Opacity.subtle))
    }
}

#Preview {
    let sampleMoodBoard = MoodBoard(
        tenantId: "sample-tenant",
        boardName: "Rustic Garden Wedding",
        boardDescription: "A beautiful outdoor wedding with natural elements and earthy tones",
        styleCategory: .rustic,
        isTemplate: true,
        tags: ["outdoor", "garden", "natural", "earthy"]
    )

    MoodBoardSearchResultCard(moodBoard: sampleMoodBoard) {
        // TODO: Implement action - print("Selected mood board")
    }
    .frame(width: 280, height: 340)
    .padding()
}
