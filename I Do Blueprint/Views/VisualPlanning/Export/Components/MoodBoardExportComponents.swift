//
//  MoodBoardExportComponents.swift
//  I Do Blueprint
//
//  Mood board export view components
//

import SwiftUI

// MARK: - Mood Board Export View

struct MoodBoardExportView: View {
    let moodBoard: MoodBoard

    var body: some View {
        ZStack {
            // Background
            moodBoard.backgroundColor

            // Elements
            ForEach(moodBoard.elements) { element in
                MoodBoardElementExportView(element: element)
            }

            // Title overlay (optional)
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(moodBoard.boardName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)

                        Text(moodBoard.styleCategory.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 1)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial))

                    Spacer()
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Mood Board Element Export View

struct MoodBoardElementExportView: View {
    let element: VisualElement

    @ViewBuilder
    var body: some View {
        switch element.elementType {
        case .image:
            if let imageUrl = element.elementData.imageUrl,
               let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

        case .color:
            RoundedRectangle(cornerRadius: 8)
                .fill(element.elementData.color ?? .gray)

        case .text:
            Text(element.elementData.text ?? "")
                .font(.system(size: max(12, element.size.height * 0.3)))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

        case .inspiration:
            VStack(spacing: 4) {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text(element.elementData.text ?? "Inspiration")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Mood Board Metadata View

struct MoodBoardMetadataView: View {
    let moodBoard: MoodBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood Board Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(moodBoard.boardName)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 1)
            }

            // Basic Information
            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Information")
                    .font(.headline)

                MetadataRow(label: "Board Name", value: moodBoard.boardName)
                MetadataRow(label: "Style Category", value: moodBoard.styleCategory.displayName)
                MetadataRow(label: "Description", value: moodBoard.boardDescription ?? "No description")
                MetadataRow(
                    label: "Canvas Size",
                    value: "\(Int(moodBoard.canvasSize.width)) × \(Int(moodBoard.canvasSize.height))")
                MetadataRow(label: "Created", value: DateFormatter.standard.string(from: moodBoard.createdAt))
                MetadataRow(label: "Updated", value: DateFormatter.standard.string(from: moodBoard.updatedAt))
            }

            // Elements Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Elements Summary")
                    .font(.headline)

                let elementCounts = Dictionary(grouping: moodBoard.elements, by: { $0.elementType })
                    .mapValues { $0.count }

                ForEach(ElementType.allCases, id: \.self) { type in
                    if let count = elementCounts[type], count > 0 {
                        MetadataRow(label: type.displayName, value: "\(count)")
                    }
                }

                MetadataRow(label: "Total Elements", value: "\(moodBoard.elements.count)")
            }

            // Color Analysis
            if let dominantColors = extractDominantColors() {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Analysis")
                        .font(.headline)

                    Text("Dominant Colors")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        ForEach(Array(dominantColors.enumerated()), id: \.offset) { _, color in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)

                                Text(color.hexString)
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("Generated by My Wedding Planning App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(Color.white)
    }

    private func extractDominantColors() -> [Color]? {
        let colors = moodBoard.elements
            .compactMap(\.elementData.color)
            .filter { $0 != .clear && $0 != .white }

        return Array(Set(colors)).prefix(5).map { $0 }
    }
}
