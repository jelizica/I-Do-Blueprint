//
//  ImageExportService.swift
//  I Do Blueprint
//
//  Image export functionality (PNG, JPEG)
//

import AppKit
import Foundation

/// Service responsible for image export operations
@MainActor
class ImageExportService {
    private let moodBoardRenderer = MoodBoardExportRenderer()
    private let colorPaletteRenderer = ColorPaletteExportRenderer()
    private let seatingChartRenderer = SeatingChartExportRenderer()
    
    // MARK: - Mood Board Image Export
    
    func exportMoodBoardToImage(
        _ moodBoard: MoodBoard,
        format: ExportFormat,
        quality: ExportQuality
    ) async throws -> URL {
        let image = try await moodBoardRenderer.renderMoodBoardPage(moodBoard, quality: quality)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(moodBoard.boardName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)"
            )
            .appendingPathExtension(format.fileExtension)
        
        guard let imageData = format == .png ? image.pngData : image.jpegData(compressionFactor: 0.9) else {
            throw ExportError.renderingFailed
        }
        
        try imageData.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Color Palette Image Export
    
    func exportColorPaletteToImage(
        _ palette: ColorPalette,
        format: ExportFormat,
        quality: ExportQuality,
        includeHexCodes: Bool
    ) async throws -> URL {
        let image = try await colorPaletteRenderer.renderColorPalettePage(
            palette,
            quality: quality,
            includeHexCodes: includeHexCodes
        )
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(palette.name.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)"
            )
            .appendingPathExtension(format.fileExtension)
        
        guard let imageData = format == .png ? image.pngData : image.jpegData(compressionFactor: 0.9) else {
            throw ExportError.renderingFailed
        }
        
        try imageData.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Seating Chart Image Export
    
    func exportSeatingChartToImage(
        _ chart: SeatingChart,
        format: ExportFormat,
        quality: ExportQuality
    ) async throws -> URL {
        let image = try await seatingChartRenderer.renderSeatingChartPage(chart, quality: quality)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(chart.chartName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)
        
        guard let imageData = format == .png ? image.pngData : image.jpegData(compressionFactor: 0.9) else {
            throw ExportError.renderingFailed
        }
        
        try imageData.write(to: tempURL)
        return tempURL
    }
}
