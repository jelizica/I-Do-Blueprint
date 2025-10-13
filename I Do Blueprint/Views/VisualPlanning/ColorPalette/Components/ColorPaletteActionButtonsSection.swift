//
//  ColorPaletteActionButtonsSection.swift
//  My Wedding Planning App
//
//  Action buttons section for Color Palette Creator
//

import SwiftUI

struct ColorPaletteActionButtonsSection: View {
    let canLoadFromMoodBoard: Bool
    let onReset: () -> Void
    let onLoadFromMoodBoard: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button("Reset Palette") {
                onReset()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)

            Button("Load from Mood Board") {
                onLoadFromMoodBoard()
            }
            .buttonStyle(.bordered)
            .disabled(!canLoadFromMoodBoard)
        }
    }
}
