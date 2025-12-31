//
//  MoodBoardExportRenderer.swift
//  I Do Blueprint
//
//  Renders mood boards for export
//

import AppKit
import SwiftUI

/// Service responsible for rendering mood boards to images
@MainActor
class MoodBoardExportRenderer {
    
    // MARK: - Public Interface
    
    /// Render mood board canvas to image
    func renderMoodBoardPage(_ moodBoard: MoodBoard, quality: ExportQuality) async throws -> NSImage {
        let canvasSize = CGSize(
            width: moodBoard.canvasSize.width * quality.scale,
            height: moodBoard.canvasSize.height * quality.scale
        )
        
        let renderer = ImageRenderer(content:
            MoodBoardExportView(moodBoard: moodBoard)
                .frame(width: canvasSize.width, height: canvasSize.height)
        )
        
        renderer.scale = quality.scale
        
        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }
        
        return nsImage
    }
    
    /// Render mood board metadata page to image
    func renderMetadataPage(_ moodBoard: MoodBoard, quality: ExportQuality) async throws -> NSImage {
        let pageSize = CGSize(width: 612 * quality.scale, height: 792 * quality.scale) // US Letter
        
        let renderer = ImageRenderer(content:
            MoodBoardMetadataView(moodBoard: moodBoard)
                .frame(width: pageSize.width, height: pageSize.height)
        )
        
        renderer.scale = quality.scale
        
        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }
        
        return nsImage
    }
}
