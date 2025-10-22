//
//  ColorPaletteSearchResultCard.swift
//  I Do Blueprint
//
//  Search result card for color palettes
//

import SwiftUI

struct ColorPaletteSearchResultCard: View {
    private let logger = AppLogger.ui
    let palette: ColorPalette
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Color swatches preview
                colorSwatchesPreview
                    .frame(height: 120)
                
                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(palette.name)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    // Description
                    if let description = palette.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Metadata row
                    HStack(spacing: 12) {
                        // Color count
                        HStack(spacing: 4) {
                            Image(systemName: "paintpalette")
                                .font(.caption2)
                            Text("\(palette.colors.count) colors")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        // Default badge
                        if palette.isDefault {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("Default")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    // Date
                    Text(palette.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 8 : 4, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Color Swatches Preview
    
    private var colorSwatchesPreview: some View {
        GeometryReader { geometry in
            if palette.colors.isEmpty {
                emptyPaletteView
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(palette.colors.enumerated()), id: \.offset) { index, hexColor in
                        colorSwatch(hexColor: hexColor)
                            .frame(width: geometry.size.width / CGFloat(palette.colors.count))
                    }
                }
            }
        }
    }
    
    private func colorSwatch(hexColor: String) -> some View {
        ZStack {
            if let color = Color(hex: hexColor) {
                color
                
                // Show hex value on hover
                if isHovered {
                    VStack {
                        Spacer()
                        Text(hexColor.uppercased())
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(contrastColor(for: hexColor))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .padding(.bottom, 4)
                    }
                }
            } else {
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                    )
            }
        }
    }
    
    private var emptyPaletteView: some View {
        VStack(spacing: 8) {
            Image(systemName: "paintpalette")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Colors")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Helper Methods
    
    private func contrastColor(for hexColor: String) -> Color {
        guard let color = Color(hex: hexColor) else { return .white }
        
        // Convert to NSColor to get RGB components
        let nsColor = NSColor(color)
        guard let rgb = nsColor.usingColorSpace(.deviceRGB) else { return .white }
        
        // Calculate relative luminance
        let luminance = 0.299 * rgb.redComponent + 0.587 * rgb.greenComponent + 0.114 * rgb.blueComponent
        
        // Return white for dark colors, black for light colors
        return luminance > 0.5 ? .black : .white
    }
}

#Preview {
    let samplePalette = ColorPalette(
        name: "Romantic Blush",
        colors: ["#FFB6C1", "#FFC0CB", "#FFE4E1", "#FFF0F5", "#E6E6FA"],
        description: "Soft and romantic pink tones perfect for a spring wedding",
        isDefault: true
    )
    
    ColorPaletteSearchResultCard(palette: samplePalette) {
        // TODO: Implement action - print("Selected palette")
    }
    .frame(width: 280, height: 240)
    .padding()
}
