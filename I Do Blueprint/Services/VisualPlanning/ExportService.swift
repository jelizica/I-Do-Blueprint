//
//  ExportService.swift
//  My Wedding Planning App
//
//  Service for exporting visual planning content to various formats
//

import AppKit
import Combine
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class ExportService: ObservableObject {
    enum ExportFormat {
        case pdf, png, jpeg, svg

        var title: String {
            switch self {
            case .pdf: "PDF"
            case .png: "PNG"
            case .jpeg: "JPEG"
            case .svg: "SVG"
            }
        }

        var fileExtension: String {
            switch self {
            case .pdf: "pdf"
            case .png: "png"
            case .jpeg: "jpg"
            case .svg: "svg"
            }
        }
    }

    enum ExportQuality {
        case low, medium, high, ultra

        var title: String {
            switch self {
            case .low: "Low (72 DPI)"
            case .medium: "Medium (150 DPI)"
            case .high: "High (300 DPI)"
            case .ultra: "Ultra (600 DPI)"
            }
        }

        var dpi: CGFloat {
            switch self {
            case .low: 72
            case .medium: 150
            case .high: 300
            case .ultra: 600
            }
        }

        var scale: CGFloat {
            dpi / 72.0 // 72 DPI is the default screen resolution
        }
    }

    enum ExportError: LocalizedError {
        case renderingFailed
        case fileCreationFailed
        case invalidData
        case unsupportedFormat

        var errorDescription: String? {
            switch self {
            case .renderingFailed: "Failed to render content"
            case .fileCreationFailed: "Failed to create export file"
            case .invalidData: "Invalid data provided"
            case .unsupportedFormat: "Unsupported export format"
            }
        }
    }

    // MARK: - Mood Board Export

    func exportMoodBoard(
        _ moodBoard: MoodBoard,
        format: ExportFormat,
        quality: ExportQuality = .high,
        includeMetadata: Bool = true) async throws -> URL {
        switch format {
        case .pdf:
            return try await exportMoodBoardToPDF(moodBoard, quality: quality, includeMetadata: includeMetadata)
        case .png:
            return try await exportMoodBoardToImage(moodBoard, format: .png, quality: quality)
        case .jpeg:
            return try await exportMoodBoardToImage(moodBoard, format: .jpeg, quality: quality)
        case .svg:
            throw ExportError.unsupportedFormat // SVG export could be implemented later
        }
    }

    private func exportMoodBoardToPDF(
        _ moodBoard: MoodBoard,
        quality: ExportQuality,
        includeMetadata: Bool) async throws -> URL {
        let pdfDocument = PDFDocument()

        // Create main mood board page
        let mainPageData = try await renderMoodBoardPage(moodBoard, quality: quality)
        guard let mainPage = PDFPage(image: mainPageData) else {
            throw ExportError.renderingFailed
        }
        pdfDocument.insert(mainPage, at: 0)

        // Add metadata page if requested
        if includeMetadata {
            let metadataPageData = try await renderMoodBoardMetadataPage(moodBoard, quality: quality)
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
                "\(moodBoard.boardName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)")
            .appendingPathExtension("pdf")

        guard pdfDocument.write(to: tempURL) else {
            throw ExportError.fileCreationFailed
        }

        return tempURL
    }

    private func exportMoodBoardToImage(
        _ moodBoard: MoodBoard,
        format: ExportFormat,
        quality: ExportQuality) async throws -> URL {
        let image = try await renderMoodBoardPage(moodBoard, quality: quality)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(moodBoard.boardName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)

        guard let imageData = format == .png ? image.pngData : image.jpegData(compressionFactor: 0.9) else {
            throw ExportError.renderingFailed
        }

        try imageData.write(to: tempURL)
        return tempURL
    }

    private func renderMoodBoardPage(_ moodBoard: MoodBoard, quality: ExportQuality) async throws -> NSImage {
        let canvasSize = CGSize(
            width: moodBoard.canvasSize.width * quality.scale,
            height: moodBoard.canvasSize.height * quality.scale)

        let renderer = ImageRenderer(content:
            MoodBoardExportView(moodBoard: moodBoard)
                .frame(width: canvasSize.width, height: canvasSize.height))

        renderer.scale = quality.scale

        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }

        return nsImage
    }

    private func renderMoodBoardMetadataPage(_ moodBoard: MoodBoard, quality: ExportQuality) async throws -> NSImage {
        let pageSize = CGSize(width: 612 * quality.scale, height: 792 * quality.scale) // US Letter

        let renderer = ImageRenderer(content:
            MoodBoardMetadataView(moodBoard: moodBoard)
                .frame(width: pageSize.width, height: pageSize.height))

        renderer.scale = quality.scale

        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }

        return nsImage
    }

    // MARK: - Color Palette Export

    func exportColorPalette(
        _ palette: ColorPalette,
        format: ExportFormat,
        quality: ExportQuality = .high,
        includeHexCodes: Bool = true) async throws -> URL {
        switch format {
        case .pdf:
            return try await exportColorPaletteToPDF(palette, quality: quality, includeHexCodes: includeHexCodes)
        case .png:
            return try await exportColorPaletteToImage(
                palette,
                format: .png,
                quality: quality,
                includeHexCodes: includeHexCodes)
        case .jpeg:
            return try await exportColorPaletteToImage(
                palette,
                format: .jpeg,
                quality: quality,
                includeHexCodes: includeHexCodes)
        case .svg:
            throw ExportError.unsupportedFormat
        }
    }

    private func exportColorPaletteToPDF(
        _ palette: ColorPalette,
        quality: ExportQuality,
        includeHexCodes: Bool) async throws -> URL {
        let pdfDocument = PDFDocument()

        let pageData = try await renderColorPalettePage(palette, quality: quality, includeHexCodes: includeHexCodes)
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
                "\(palette.name.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)")
            .appendingPathExtension("pdf")

        guard pdfDocument.write(to: tempURL) else {
            throw ExportError.fileCreationFailed
        }

        return tempURL
    }

    private func exportColorPaletteToImage(
        _ palette: ColorPalette,
        format: ExportFormat,
        quality: ExportQuality,
        includeHexCodes: Bool) async throws -> URL {
        let image = try await renderColorPalettePage(palette, quality: quality, includeHexCodes: includeHexCodes)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(palette.name.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)

        guard let imageData = format == .png ? image.pngData : image.jpegData(compressionFactor: 0.9) else {
            throw ExportError.renderingFailed
        }

        try imageData.write(to: tempURL)
        return tempURL
    }

    private func renderColorPalettePage(
        _ palette: ColorPalette,
        quality: ExportQuality,
        includeHexCodes: Bool) async throws -> NSImage {
        let pageSize = CGSize(width: 612 * quality.scale, height: 792 * quality.scale) // US Letter

        let renderer = ImageRenderer(content:
            ColorPaletteExportView(palette: palette, includeHexCodes: includeHexCodes)
                .frame(width: pageSize.width, height: pageSize.height))

        renderer.scale = quality.scale

        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }

        return nsImage
    }

    // MARK: - Seating Chart Export

    func exportSeatingChart(
        _ chart: SeatingChart,
        format: ExportFormat,
        quality: ExportQuality = .high,
        includeGuestList: Bool = true) async throws -> URL {
        switch format {
        case .pdf:
            return try await exportSeatingChartToPDF(chart, quality: quality, includeGuestList: includeGuestList)
        case .png:
            return try await exportSeatingChartToImage(chart, format: .png, quality: quality)
        case .jpeg:
            return try await exportSeatingChartToImage(chart, format: .jpeg, quality: quality)
        case .svg:
            throw ExportError.unsupportedFormat
        }
    }

    private func exportSeatingChartToPDF(
        _ chart: SeatingChart,
        quality: ExportQuality,
        includeGuestList: Bool) async throws -> URL {
        let pdfDocument = PDFDocument()

        // Main seating chart page
        let chartPageData = try await renderSeatingChartPage(chart, quality: quality)
        guard let chartPage = PDFPage(image: chartPageData) else {
            throw ExportError.renderingFailed
        }
        pdfDocument.insert(chartPage, at: 0)

        // Guest list page if requested
        if includeGuestList, !chart.guests.isEmpty {
            let guestListPageData = try await renderGuestListPage(chart, quality: quality)
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

    private func exportSeatingChartToImage(
        _ chart: SeatingChart,
        format: ExportFormat,
        quality: ExportQuality) async throws -> URL {
        let image = try await renderSeatingChartPage(chart, quality: quality)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(chart.chartName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)

        guard let imageData = format == .png ? image.pngData : image.jpegData(compressionFactor: 0.9) else {
            throw ExportError.renderingFailed
        }

        try imageData.write(to: tempURL)
        return tempURL
    }

    private func renderSeatingChartPage(_ chart: SeatingChart, quality: ExportQuality) async throws -> NSImage {
        let canvasSize = CGSize(
            width: chart.venueConfiguration.dimensions.width * quality.scale,
            height: chart.venueConfiguration.dimensions.height * quality.scale)

        let renderer = ImageRenderer(content:
            SeatingChartExportView(chart: chart)
                .frame(width: canvasSize.width, height: canvasSize.height))

        renderer.scale = quality.scale

        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }

        return nsImage
    }

    private func renderGuestListPage(_ chart: SeatingChart, quality: ExportQuality) async throws -> NSImage {
        let pageSize = CGSize(width: 612 * quality.scale, height: 792 * quality.scale) // US Letter

        let renderer = ImageRenderer(content:
            GuestListExportView(chart: chart)
                .frame(width: pageSize.width, height: pageSize.height))

        renderer.scale = quality.scale

        guard let nsImage = renderer.nsImage else {
            throw ExportError.renderingFailed
        }

        return nsImage
    }

    // MARK: - Batch Export

    func exportMultipleMoodBoards(
        _ moodBoards: [MoodBoard],
        format: ExportFormat,
        quality: ExportQuality = .high) async throws -> URL {
        guard format == .pdf else {
            throw ExportError.unsupportedFormat
        }

        let pdfDocument = PDFDocument()

        for (index, moodBoard) in moodBoards.enumerated() {
            let pageData = try await renderMoodBoardPage(moodBoard, quality: quality)
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

    // MARK: - Sharing Utilities

    func shareFile(at url: URL, from view: NSView) {
        let sharingPicker = NSSharingServicePicker(items: [url])
        sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }

    func saveFileWithDialog(at url: URL, suggestedFilename: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = suggestedFilename
        savePanel.allowedContentTypes = [.init(filenameExtension: url.pathExtension) ?? .data]

        if savePanel.runModal() == .OK, let destinationURL = savePanel.url {
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
            } catch {
                AppLogger.export.error("Failed to save file", error: error)
            }
        }
    }
}
