//
//  ExportService.swift
//  I Do Blueprint
//
//  Orchestrates export operations across visual planning content
//

import AppKit
import Combine
import Foundation

@MainActor
class ExportService: ObservableObject {
    private let pdfExportService = PDFExportService()
    private let imageExportService = ImageExportService()
    
    // MARK: - Mood Board Export
    
    func exportMoodBoard(
        _ moodBoard: MoodBoard,
        format: ExportFormat,
        quality: ExportQuality = .high,
        includeMetadata: Bool = true
    ) async throws -> URL {
        switch format {
        case .pdf:
            return try await pdfExportService.exportMoodBoardToPDF(
                moodBoard,
                quality: quality,
                includeMetadata: includeMetadata
            )
        case .png, .jpeg:
            return try await imageExportService.exportMoodBoardToImage(
                moodBoard,
                format: format,
                quality: quality
            )
        case .svg:
            throw ExportError.unsupportedFormat // SVG export could be implemented later
        }
    }
    
    // MARK: - Color Palette Export
    
    func exportColorPalette(
        _ palette: ColorPalette,
        format: ExportFormat,
        quality: ExportQuality = .high,
        includeHexCodes: Bool = true
    ) async throws -> URL {
        switch format {
        case .pdf:
            return try await pdfExportService.exportColorPaletteToPDF(
                palette,
                quality: quality,
                includeHexCodes: includeHexCodes
            )
        case .png, .jpeg:
            return try await imageExportService.exportColorPaletteToImage(
                palette,
                format: format,
                quality: quality,
                includeHexCodes: includeHexCodes
            )
        case .svg:
            throw ExportError.unsupportedFormat
        }
    }
    
    // MARK: - Seating Chart Export
    
    func exportSeatingChart(
        _ chart: SeatingChart,
        format: ExportFormat,
        quality: ExportQuality = .high,
        includeGuestList: Bool = true
    ) async throws -> URL {
        switch format {
        case .pdf:
            return try await pdfExportService.exportSeatingChartToPDF(
                chart,
                quality: quality,
                includeGuestList: includeGuestList
            )
        case .png, .jpeg:
            return try await imageExportService.exportSeatingChartToImage(
                chart,
                format: format,
                quality: quality
            )
        case .svg:
            throw ExportError.unsupportedFormat
        }
    }
    
    // MARK: - Batch Export
    
    func exportMultipleMoodBoards(
        _ moodBoards: [MoodBoard],
        format: ExportFormat,
        quality: ExportQuality = .high
    ) async throws -> URL {
        guard format == .pdf else {
            throw ExportError.unsupportedFormat
        }
        
        return try await pdfExportService.exportMultipleMoodBoardsToPDF(
            moodBoards,
            quality: quality
        )
    }
    
    // MARK: - Sharing Utilities
    
    func shareFile(at url: URL, from view: NSView) {
        FileExportHelper.shareFile(at: url, from: view)
    }
    
    func saveFileWithDialog(at url: URL, suggestedFilename: String) {
        FileExportHelper.saveFileWithDialog(at: url, suggestedFilename: suggestedFilename)
    }
}
