//
//  ColorPaletteExport.swift
//  I Do Blueprint
//
//  Color palette export view components
//

import SwiftUI

// MARK: - Export Color Palettes View

struct ExportColorPalettesView: View {
    let palettes: [ColorPalette]
    let template: ExportTemplate
    let branding: BrandingSettings
    let showHexCodes: Bool
    let showUsageGuide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header
            Text("Color Palettes")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(branding.primaryColor)

            // Palettes
            ForEach(palettes) { palette in
                ColorPaletteExportCard(
                    palette: palette,
                    branding: branding,
                    showHexCodes: showHexCodes,
                    showUsageGuide: showUsageGuide)
            }

            Spacer()
        }
        .padding(Spacing.huge)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

// MARK: - Color Palette Export Card

struct ColorPaletteExportCard: View {
    let palette: ColorPalette
    let branding: BrandingSettings
    let showHexCodes: Bool
    let showUsageGuide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Palette header
            VStack(alignment: .leading, spacing: 4) {
                Text(palette.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(branding.textColor)

                if let description = palette.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(branding.textColor.opacity(0.7))
                }
            }

            // Color swatches
            HStack(spacing: 16) {
                ForEach(palette.colors.prefix(4).indices, id: \.self) { index in
                    if let color = Color.fromHexString(palette.colors[index]) {
                        ColorSwatch(color: color, size: 60)
                    }
                }
            }

            // Usage guide
            if showUsageGuide {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage Guidelines")
                        .font(.headline)
                        .foregroundColor(branding.primaryColor)

                    Text("Primary: Main color for headers and important elements")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))

                    Text("Secondary: Supporting color for backgrounds and accents")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))

                    Text("Accent: Highlight color for calls-to-action and emphasis")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))

                    Text("Neutral: Text and subtle background elements")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))
                }
            }
        }
        .padding()
        .background(branding.primaryColor.opacity(0.05))
        .cornerRadius(8)
    }
}
