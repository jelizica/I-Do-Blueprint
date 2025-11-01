//
//  ColorPalettePaletteGradientsView.swift
//  My Wedding Planning App
//
//  Gradients preview view for Color Palette Creator
//

import SwiftUI

struct ColorPalettePaletteGradientsView: View {
    @Binding var selectedPaletteColors: [PaletteColor]

    private func generateGradientCombinations() -> [(Color, Color)] {
        var combinations: [(Color, Color)] = []

        for i in 0 ..< selectedPaletteColors.count {
            for j in (i + 1) ..< selectedPaletteColors.count {
                combinations.append((
                    selectedPaletteColors[i].color,
                    selectedPaletteColors[j].color))
            }
        }

        return combinations
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Gradient Combinations")
                    .font(.title2)
                    .fontWeight(.semibold)

                if selectedPaletteColors.count >= 2 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 1), spacing: 12) {
                        ForEach(generateGradientCombinations(), id: \.0) { gradient in
                            VStack(spacing: 6) {
                                LinearGradient(
                                    colors: [gradient.0, gradient.1],
                                    startPoint: .leading,
                                    endPoint: .trailing)
                                    .frame(height: 60)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                                HStack(spacing: 8) {
                                    Text(gradient.0.hexString)
                                        .font(.system(.caption, design: .monospaced))
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                    Text(gradient.1.hexString)
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                } else {
                    Text("Add more colors to see gradient combinations")
                        .foregroundColor(.secondary)
                        .padding(.top, Spacing.huge)
                }
            }
            .padding(.vertical, Spacing.xl)
        }
    }
}
