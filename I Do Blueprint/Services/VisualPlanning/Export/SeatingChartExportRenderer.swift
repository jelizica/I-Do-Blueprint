//
//  SeatingChartExportRenderer.swift
//  I Do Blueprint
//
//  Renders seating charts for export
//

import AppKit
import SwiftUI

/// Service responsible for rendering seating charts to images
@MainActor
class SeatingChartExportRenderer {
    
    // MARK: - Public Interface
    
    /// Render seating chart to image
    func renderSeatingChartPage(_ chart: SeatingChart, quality: ExportQuality) async throws -> NSImage {
        let canvasSize = CGSize(
            width: chart.venueConfiguration.dimensions.width * quality.scale,
            height: chart.venueConfiguration.dimensions.height * quality.scale
        )
        
        let renderer = ImageRenderer(content:
            SeatingChartExportView(chart: chart)
                .frame(width: canvasSize.width, height: canvasSize.height)
        )
        
        renderer.scale = quality.scale
        
        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }
        
        return nsImage
    }
    
    /// Render guest list page to image
    func renderGuestListPage(_ chart: SeatingChart, quality: ExportQuality) async throws -> NSImage {
        let pageSize = CGSize(width: 612 * quality.scale, height: 792 * quality.scale) // US Letter
        
        let renderer = ImageRenderer(content:
            GuestListExportView(chart: chart)
                .frame(width: pageSize.width, height: pageSize.height)
        )
        
        renderer.scale = quality.scale
        
        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }
        
        return nsImage
    }
}
