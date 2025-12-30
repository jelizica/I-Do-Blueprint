//
//  ImageExportGenerator.swift
//  I Do Blueprint
//
//  Image export generation service (PNG/JPEG)
//

import Foundation
import SwiftUI
import AppKit

/// Protocol for image export operations
protocol ImageExportProtocol {
    func generateImage() async throws -> URL
}

/// Actor responsible for image export generation (PNG/JPEG)
actor ImageExportGenerator: ImageExportProtocol {
    private let template: ExportTemplate
    private let content: ExportContent
    private let customizations: ExportCustomizations
    private let branding: BrandingSettings
    
    init(
        template: ExportTemplate,
        content: ExportContent,
        customizations: ExportCustomizations,
        branding: BrandingSettings
    ) {
        self.template = template
        self.content = content
        self.customizations = customizations
        self.branding = branding
    }
    
    // MARK: - Public Interface
    
    @MainActor
    func generateImage() async throws -> URL {
        // Validate content availability before rendering
        try validateContent(for: template.category)

        // Generate high-resolution image export
        let renderer = ImageRenderer(content: generateImageContent())
        renderer.scale = customizations.imageScale

        guard let nsImage = renderer.nsImage else {
            throw ExportError.imageGenerationFailed
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(template.name)_\(Date().timeIntervalSince1970).\(template.outputFormat.fileExtension)"
            )

        let imageData: Data
        switch template.outputFormat {
        case .png:
            guard let data = nsImage.pngData else {
                throw ExportError.imageGenerationFailed
            }
            imageData = data
        case .jpeg:
            guard let data = nsImage.jpegData(compressionFactor: customizations.jpegQuality) else {
                throw ExportError.imageGenerationFailed
            }
            imageData = data
        default:
            throw ExportError.unsupportedFormat
        }

        try imageData.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Content Generation
    
    // MARK: - Validation

    @MainActor
    private func validateContent(for category: ExportCategory) throws {
        switch category {
        case .moodBoard:
            guard !content.moodBoards.isEmpty else {
                throw ExportError.missingContent
            }
        case .seatingChart:
            guard !content.seatingCharts.isEmpty else {
                throw ExportError.missingContent
            }
        case .colorPalette, .comprehensive:
            // No specific validation needed
            break
        }
    }

    @ViewBuilder
    @MainActor
    private func generateImageContent() -> some View {
        switch template.category {
        case .moodBoard:
            if let moodBoard = content.moodBoards.first {
                ExportMoodBoardView(
                    moodBoard: moodBoard,
                    template: template,
                    branding: branding,
                    showMetadata: template.features.contains(.metadata)
                )
            }
        case .colorPalette:
            ExportColorPalettesView(
                palettes: content.colorPalettes,
                template: template,
                branding: branding,
                showHexCodes: template.features.contains(.hexCodes),
                showUsageGuide: template.features.contains(.usageGuide)
            )
        case .seatingChart:
            if let chart = content.seatingCharts.first {
                ExportSeatingChartView(
                    chart: chart,
                    template: template,
                    branding: branding,
                    showGuestList: template.features.contains(.guestList)
                )
            }
        case .comprehensive:
            ComprehensiveExportView(
                content: content,
                template: template,
                branding: branding
            )
        }
    }
}
