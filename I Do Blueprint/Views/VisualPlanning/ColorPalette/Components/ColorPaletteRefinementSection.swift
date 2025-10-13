//
//  ColorPaletteRefinementSection.swift
//  My Wedding Planning App
//
//  Color refinement section for Color Palette Creator
//

import SwiftUI

struct ColorPaletteRefinementSection: View {
    @Binding var selectedPaletteColors: [PaletteColor]

    let addCustomColor: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Refine Palette")
                .font(.headline)

            Text("Adjust individual colors to perfect your palette")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(selectedPaletteColors.indices, id: \.self) { index in
                        ColorRefinementRow(
                            paletteColor: $selectedPaletteColors[index],
                            onColorChange: { color in
                                selectedPaletteColors[index].color = color
                            })
                    }
                }
            }

            // Add/Remove colors
            HStack {
                Button("Add Color") {
                    addCustomColor()
                }
                .buttonStyle(.bordered)

                if selectedPaletteColors.count > 2 {
                    Button("Remove Last") {
                        selectedPaletteColors.removeLast()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }

            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Preview") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
