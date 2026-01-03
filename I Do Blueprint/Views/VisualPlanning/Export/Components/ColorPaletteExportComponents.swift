//
//  ColorPaletteExportComponents.swift
//  I Do Blueprint
//
//  Color palette export view components
//

import SwiftUI

// MARK: - Color Palette Export View

struct ColorPaletteExportView: View {
    let palette: ColorPalette
    let includeHexCodes: Bool

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Text("Wedding Color Palette")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(palette.name)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(SemanticColors.textSecondary)
                    .frame(height: 2)
                    .frame(maxWidth: 400)
            }

            // Main color swatches
            VStack(spacing: 24) {
                Text("Primary Colors")
                    .font(.headline)

                HStack(spacing: 20) {
                    // Display colors from the colors array
                    let colorLabels = ["Primary", "Secondary", "Accent", "Neutral"]
                    ForEach(palette.colors.prefix(4).indices, id: \.self) { index in
                        if let color = Color.fromHexString(palette.colors[index]) {
                            ColorSwatchExport(
                                color: color,
                                label: index < colorLabels.count ? colorLabels[index] : "Color \(index + 1)",
                                includeHex: includeHexCodes)
                        }
                    }
                }
            }

            // Additional colors if available (beyond the first 4)
            if palette.colors.count > 4 {
                VStack(spacing: 16) {
                    Text("Additional Colors")
                        .font(.headline)

                    HStack(spacing: 16) {
                        ForEach(palette.colors.dropFirst(4).indices, id: \.self) { index in
                            if let color = Color.fromHexString(palette.colors[index]) {
                                ColorSwatchExport(
                                    color: color,
                                    label: "Color \(index - 3)",
                                    includeHex: includeHexCodes)
                            }
                        }
                    }
                }
            }

            // Color strip
            VStack(spacing: 12) {
                Text("Color Strip")
                    .font(.headline)

                HStack(spacing: 0) {
                    ForEach(palette.colors, id: \.self) { hexColor in
                        Rectangle().fill(Color.fromHexString(hexColor) ?? .gray)
                    }
                }
                .frame(height: 60)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4)
            }

            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                if let description = palette.description {
                    MetadataRow(label: "Description", value: description)
                }

                MetadataRow(label: "Default", value: palette.isDefault ? "Yes" : "No")

                MetadataRow(label: "Created", value: DateFormatter.standard.string(from: palette.createdAt))
            }

            Spacer()

            // Footer
            HStack {
                Text("My Wedding Planning App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.huge)
        .background(SemanticColors.textPrimary)
    }
}

// MARK: - Color Swatch Export

struct ColorSwatchExport: View {
    let color: Color
    let label: String
    let includeHex: Bool

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(SemanticColors.textPrimary.opacity(Opacity.subtle), lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 4)

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)

            if includeHex {
                Text(color.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}
