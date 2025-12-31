//
//  PDFExportService.swift
//  I Do Blueprint
//
//  PDF export functionality
//

import AppKit
import Foundation
import PDFKit

/// Service responsible for PDF export operations
@MainActor
class PDFExportService {
    private let moodBoardRenderer = MoodBoardExportRenderer()
    private let colorPaletteRenderer = ColorPaletteExportRenderer()
    private let seatingChartRenderer = SeatingChartExportRenderer()
    
    // MARK: - Mood Board PDF Export
    
    func exportMoodBoardToPDF(
        _ moodBoard: MoodBoard,
        quality: ExportQuality,
        includeMetadata: Bool
    ) async throws -> URL {
        let pdfDocument = PDFDocument()
        
        // Create main mood board page
        let mainPageData = try await moodBoardRenderer.renderMoodBoardPage(moodBoard, quality: quality)
        guard let mainPage = PDFPage(image: mainPageData) else {
            throw ExportError.renderingFailed
        }
        pdfDocument.insert(mainPage, at: 0)
        
        // Add metadata page if requested
        if includeMetadata {
            let metadataPageData = try await moodBoardRenderer.renderMetadataPage(moodBoard, quality: quality)
            guard let metadataPage = PDFPage(image: metadataPageData) else {
                throw ExportError.renderingFailed
            }
            pdfDocument.insert(metadataPage, at: 1)
        }
        
        // Set PDF metadata
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: moodBoard.boardName,
            PDFDocumentAttribute.authorAttribute: "My Wedding Planning App",
            PDFDocumentAttribute.subjectAttribute: "Wedding Mood Board",
            PDFDocumentAttribute.creatorAttribute: "Visual Planning Suite",
            PDFDocumentAttribute.creationDateAttribute: Date()
        ]
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(moodBoard.boardName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)"
            )
            .appendingPathExtension("pdf")
        
        guard pdfDocument.write(to: tempURL) else {
            throw ExportError.fileCreationFailed
        }
        
        return tempURL
    }
    
    // MARK: - Color Palette PDF Export
    
    func exportColorPaletteToPDF(
        _ palette: ColorPalette,
        quality: ExportQuality,
        includeHexCodes: Bool
    ) async throws -> URL {
        let pdfDocument = PDFDocument()
        
        let pageData = try await colorPaletteRenderer.renderColorPalettePage(
            palette,
            quality: quality,
            includeHexCodes: includeHexCodes
        )
        guard let page = PDFPage(image: pageData) else {
            throw ExportError.renderingFailed
        }
        pdfDocument.insert(page, at: 0)
        
        // Set PDF metadata
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: palette.name,
            PDFDocumentAttribute.authorAttribute: "My Wedding Planning App",
            PDFDocumentAttribute.subjectAttribute: "Wedding Color Palette",
            PDFDocumentAttribute.creatorAttribute: "Visual Planning Suite",
            PDFDocumentAttribute.creationDateAttribute: Date()
        ]
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(palette.name.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)"
            )
            .appendingPathExtension("pdf")
        
        guard pdfDocument.write(to: tempURL) else {
            throw ExportError.fileCreationFailed
        }
        
        return tempURL
    }
    
    // MARK: - Seating Chart PDF Export
    
    func exportSeatingChartToPDF(
        _ chart: SeatingChart,
        quality: ExportQuality,
        includeGuestList: Bool
    ) async throws -> URL {
        let pdfDocument = PDFDocument()
        
        // Main seating chart page
        let chartPageData = try await seatingChartRenderer.renderSeatingChartPage(chart, quality: quality)
        guard let chartPage = PDFPage(image: chartPageData) else {
            throw ExportError.renderingFailed
        }
        pdfDocument.insert(chartPage, at: 0)
        
        // Guest list page if requested
        if includeGuestList, !chart.guests.isEmpty {
            let guestListPageData = try await seatingChartRenderer.renderGuestListPage(chart, quality: quality)
            guard let guestListPage = PDFPage(image: guestListPageData) else {
                throw ExportError.renderingFailed
            }
            pdfDocument.insert(guestListPage, at: 1)
        }
        
        // Set PDF metadata
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: chart.chartName,
            PDFDocumentAttribute.authorAttribute: "My Wedding Planning App",
            PDFDocumentAttribute.subjectAttribute: "Wedding Seating Chart",
            PDFDocumentAttribute.creatorAttribute: "Visual Planning Suite",
            PDFDocumentAttribute.creationDateAttribute: Date()
        ]
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(chart.chartName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)")
            .appendingPathExtension("pdf")
        
        guard pdfDocument.write(to: tempURL) else {
            throw ExportError.fileCreationFailed
        }
        
        return tempURL
    }
    
    // MARK: - Batch PDF Export
    
    func exportMultipleMoodBoardsToPDF(
        _ moodBoards: [MoodBoard],
        quality: ExportQuality
    ) async throws -> URL {
        let pdfDocument = PDFDocument()
        
        for (index, moodBoard) in moodBoards.enumerated() {
            let pageData = try await moodBoardRenderer.renderMoodBoardPage(moodBoard, quality: quality)
            guard let page = PDFPage(image: pageData) else {
                throw ExportError.renderingFailed
            }
            pdfDocument.insert(page, at: index)
        }
        
        // Set PDF metadata
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: "Wedding Mood Boards Collection",
            PDFDocumentAttribute.authorAttribute: "My Wedding Planning App",
            PDFDocumentAttribute.subjectAttribute: "Wedding Visual Planning",
            PDFDocumentAttribute.creatorAttribute: "Visual Planning Suite",
            PDFDocumentAttribute.creationDateAttribute: Date()
        ]
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Mood_Boards_Collection_\(UUID().uuidString)")
            .appendingPathExtension("pdf")
        
        guard pdfDocument.write(to: tempURL) else {
            throw ExportError.fileCreationFailed
        }
        
        return tempURL
    }
}
