//
//  MoodBoardExport.swift
//  I Do Blueprint
//
//  Mood board export view components
//

import SwiftUI

// MARK: - Export Mood Board View

struct ExportMoodBoardView: View {
    let moodBoard: MoodBoard
    let template: ExportTemplate
    let branding: BrandingSettings
    let showMetadata: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(moodBoard.boardName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(branding.primaryColor)

                if let description = moodBoard.boardDescription, !description.isEmpty {
                    Text(description)
                        .font(.title3)
                        .foregroundColor(branding.textColor.opacity(0.8))
                }

                Text("Style: \(moodBoard.styleCategory.displayName)")
                    .font(.subheadline)
                    .foregroundColor(branding.textColor.opacity(0.7))
            }

            // Mood board canvas
            ZStack {
                Rectangle()
                    .fill(moodBoard.backgroundColor)
                    .aspectRatio(moodBoard.canvasSize.width / moodBoard.canvasSize.height, contentMode: .fit)
                    .frame(maxHeight: 400)

                ForEach(moodBoard.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                    ExportElementView(element: element)
                        .position(element.position)
                }
            }

            // Metadata section
            if showMetadata, !moodBoard.elements.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Elements")
                        .font(.headline)
                        .foregroundColor(branding.primaryColor)

                    ForEach(Array(moodBoard.elements.enumerated()), id: \.offset) { index, element in
                        ElementMetadataRow(element: element, index: index + 1, branding: branding)
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.huge)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

// MARK: - Export Element View

struct ExportElementView: View {
    let element: VisualElement

    @ViewBuilder
    var body: some View {
        switch element.elementType {
        case .image:
            // Note: Image loading from URL would require AsyncImage or pre-loaded data
            // For now, show placeholder
            Rectangle()
                .fill(SemanticColors.textSecondary.opacity(Opacity.light))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(SemanticColors.textSecondary))

        case .color:
            Rectangle()
                .fill(element.elementData.color ?? .gray)

        case .text:
            ZStack {
                Rectangle()
                    .fill(SemanticColors.textPrimary.opacity(Opacity.strong))

                Text(element.elementData.text ?? "Text")
                    .font(.system(size: max(8, element.size.height * 0.3)))
                    .foregroundColor(SemanticColors.textPrimary)
                    .multilineTextAlignment(.center)
            }

        case .inspiration:
            VStack(spacing: 2) {
                Image(systemName: "lightbulb")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text(element.elementData.text ?? "Inspiration")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xs)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)
        }
    }
}

// MARK: - Element Metadata Row

struct ElementMetadataRow: View {
    let element: VisualElement
    let index: Int
    let branding: BrandingSettings

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index).")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(branding.primaryColor)
                .frame(width: 20, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(element.elementType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let text = element.elementData.text, !text.isEmpty {
                    Text("Text: \(text)")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))
                }

                if let color = element.elementData.color {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)

                        Text(color.toHex())
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(branding.textColor.opacity(0.7))
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}
