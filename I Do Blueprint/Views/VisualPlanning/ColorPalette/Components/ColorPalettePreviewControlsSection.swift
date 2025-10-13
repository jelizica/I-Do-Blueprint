//
//  ColorPalettePreviewControlsSection.swift
//  My Wedding Planning App
//
//  Preview controls for Color Palette Creator
//

import SwiftUI

struct ColorPalettePreviewControlsSection: View {
    @Binding var previewMode: PalettePreviewMode

    var body: some View {
        VStack(spacing: 8) {
            Text("Preview Mode")
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("Preview", selection: $previewMode) {
                ForEach(PalettePreviewMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}
