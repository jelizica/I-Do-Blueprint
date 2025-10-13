//
//  ColorPalettePaletteMockupView.swift
//  My Wedding Planning App
//
//  Mockup preview view for Color Palette Creator
//

import SwiftUI

struct ColorPalettePaletteMockupView: View {
    @Binding var selectedPaletteColors: [PaletteColor]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Wedding Mockup")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Wedding invitation mockup
                if !selectedPaletteColors.isEmpty {
                    WeddingMockupView(colors: selectedPaletteColors.map(\.color))
                        .padding(.horizontal, 20)
                } else {
                    Text("Add colors to see wedding mockup")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding(.vertical, 20)
        }
    }
}
