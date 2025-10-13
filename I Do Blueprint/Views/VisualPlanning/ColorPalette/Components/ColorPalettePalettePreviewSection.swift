//
//  ColorPalettePalettePreviewSection.swift
//  My Wedding Planning App
//
//  Main palette preview section wrapper for Color Palette Creator
//

import SwiftUI

struct ColorPalettePalettePreviewSection: View {
    @Binding var previewMode: PalettePreviewMode
    @Binding var selectedPaletteColors: [PaletteColor]

    var body: some View {
        Group {
            switch previewMode {
            case .swatches:
                ColorPalettePaletteSwatchesView(selectedPaletteColors: $selectedPaletteColors)
            case .gradients:
                ColorPalettePaletteGradientsView(selectedPaletteColors: $selectedPaletteColors)
            case .mockup:
                ColorPalettePaletteMockupView(selectedPaletteColors: $selectedPaletteColors)
            case .accessibility:
                ColorPalettePaletteAccessibilityView(selectedPaletteColors: $selectedPaletteColors)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
