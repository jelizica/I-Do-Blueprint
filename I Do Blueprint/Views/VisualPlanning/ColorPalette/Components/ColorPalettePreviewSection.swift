//
//  ColorPalettePreviewSection.swift
//  My Wedding Planning App
//
//  Preview and save section for Color Palette Creator
//

import SwiftUI

struct ColorPalettePreviewSection: View {
    @Binding var selectedPaletteColors: [PaletteColor]
    @Binding var paletteName: String

    let currentHarmonyType: ColorHarmonyType
    let getContrastRating: () -> String
    let getContrastColor: () -> Color
    let onBack: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview & Save")
                .font(.headline)

            Text("Review your palette and see how it works together")
                .font(.caption)
                .foregroundColor(.secondary)

            // Palette statistics
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Colors:")
                    Spacer()
                    Text("\(selectedPaletteColors.count)")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Harmony:")
                    Spacer()
                    Text(currentHarmonyType.displayName)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Contrast:")
                    Spacer()
                    Text(getContrastRating())
                        .fontWeight(.medium)
                        .foregroundColor(getContrastColor())
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save Palette") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(paletteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
