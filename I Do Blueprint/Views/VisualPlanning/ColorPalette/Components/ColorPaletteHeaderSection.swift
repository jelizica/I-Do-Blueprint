//
//  ColorPaletteHeaderSection.swift
//  My Wedding Planning App
//
//  Header section for Color Palette Creator
//

import SwiftUI

struct ColorPaletteHeaderSection: View {
    @Binding var paletteName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                Text("Color Palette Creator")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Close") {
                    onDismiss()
                }
            }

            TextField("Enter palette name...", text: $paletteName)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
}
