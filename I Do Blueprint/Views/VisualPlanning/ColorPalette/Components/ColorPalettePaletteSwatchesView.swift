//
//  ColorPalettePaletteSwatchesView.swift
//  My Wedding Planning App
//
//  Swatches preview view for Color Palette Creator
//

import SwiftUI

struct ColorPalettePaletteSwatchesView: View {
    @Binding var selectedPaletteColors: [PaletteColor]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Color Swatches")
                    .font(.title2)
                    .fontWeight(.semibold)

                if selectedPaletteColors.isEmpty {
                    Text("No colors selected yet")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 16) {
                        // Large swatches in scrollable horizontal view
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(selectedPaletteColors.enumerated()), id: \.offset) { _, paletteColor in
                                    VStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(paletteColor.color)
                                            .frame(width: 100, height: 100)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                        VStack(spacing: 2) {
                                            Text(paletteColor.role.title)
                                                .font(.caption)
                                                .fontWeight(.medium)

                                            Text(paletteColor.color.hexString)
                                                .font(.system(.caption2, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Color strip
                        HStack(spacing: 0) {
                            ForEach(selectedPaletteColors.indices, id: \.self) { index in
                                Rectangle()
                                    .fill(selectedPaletteColors[index].color)
                                    .frame(height: 80)
                            }
                        }
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 20)
        }
    }
}
