//
//  ColorPaletteExportRenderer.swift
//  I Do Blueprint
//
//  Renders color palettes for export
//

import AppKit
import SwiftUI

/// Service responsible for rendering color palettes to images
@MainActor
class ColorPaletteExportRenderer {
    
    // MARK: - Public Interface
    
    /// Render color palette to image
    func renderColorPalettePage(
        _ palette: ColorPalette,
        quality: ExportQuality,
        includeHexCodes: Bool
    ) async throws -> NSImage {
        let pageSize = CGSize(width: 612 * quality.scale, height: 792 * quality.scale) // US Letter
        
        let renderer = ImageRenderer(content:
            ColorPaletteExportView(palette: palette, includeHexCodes: includeHexCodes)
                .frame(width: pageSize.width, height: pageSize.height)
        )
        
        renderer.scale = quality.scale
        
        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }
        
        return nsImage
    }
}
