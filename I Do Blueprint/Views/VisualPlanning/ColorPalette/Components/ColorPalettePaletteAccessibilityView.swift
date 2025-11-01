//
//  ColorPalettePaletteAccessibilityView.swift
//  My Wedding Planning App
//
//  Accessibility preview view for Color Palette Creator
//

import SwiftUI

struct ColorPalettePaletteAccessibilityView: View {
    @Binding var selectedPaletteColors: [PaletteColor]

    private func generateContrastPairs() -> [(Color, Color)] {
        var pairs: [(Color, Color)] = []

        for i in 0 ..< selectedPaletteColors.count {
            for j in 0 ..< selectedPaletteColors.count {
                if i != j {
                    pairs.append((
                        selectedPaletteColors[i].color,
                        selectedPaletteColors[j].color))
                }
            }
        }

        return pairs
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Accessibility Analysis")
                    .font(.title2)
                    .fontWeight(.semibold)

                if selectedPaletteColors.count >= 2 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 1), spacing: 12) {
                        ForEach(generateContrastPairs(), id: \.0) { pair in
                            AccessibilityContrastCard(
                                backgroundColor: pair.0,
                                foregroundColor: pair.1)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                } else {
                    Text("Add more colors to analyze accessibility")
                        .foregroundColor(.secondary)
                        .padding(.top, Spacing.huge)
                }
            }
            .padding(.vertical, Spacing.xl)
        }
    }
}
