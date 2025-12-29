//
//  PDFExportGenerator.swift
//  I Do Blueprint
//
//  PDF export generation service
//

import Foundation
import PDFKit
import SwiftUI

/// Protocol for PDF export operations
protocol PDFExportProtocol {
    func generatePDF(
        template: ExportTemplate,
        content: ExportContent,
        customizations: ExportCustomizations,
        branding: BrandingSettings
    ) async throws -> URL
}

/// Actor responsible for PDF export generation
actor PDFExportGenerator: PDFExportProtocol {
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
    
    func generatePDF(
        template: ExportTemplate,
        content: ExportContent,
        customizations: ExportCustomizations,
        branding: BrandingSettings
    ) async throws -> URL {
        let pdfDocument = PDFDocument()
        var pageIndex = 0
        
        // Generate pages based on template features
        if template.features.contains(.coverPage) {
            let coverPage = try await generateCoverPage()
            pdfDocument.insert(coverPage, at: pageIndex)
            pageIndex += 1
        }
        
        if template.features.contains(.tableOfContents) {
            let tocPage = try await generateTableOfContents()
            pdfDocument.insert(tocPage, at: pageIndex)
            pageIndex += 1
        }
        
        if template.features.contains(.moodBoards), !content.moodBoards.isEmpty {
            for moodBoard in content.moodBoards {
                let moodBoardPages = try await generateMoodBoardPages(moodBoard)
                for page in moodBoardPages {
                    pdfDocument.insert(page, at: pageIndex)
                    pageIndex += 1
                }
            }
        }
        
        if template.features.contains(.colorPalettes), !content.colorPalettes.isEmpty {
            let colorPages = try await generateColorPalettePages()
            for page in colorPages {
                pdfDocument.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        if template.features.contains(.seatingCharts), !content.seatingCharts.isEmpty {
            for chart in content.seatingCharts {
                let chartPages = try await generateSeatingChartPages(chart)
                for page in chartPages {
                    pdfDocument.insert(page, at: pageIndex)
                    pageIndex += 1
                }
            }
        }
        
        if template.features.contains(.styleGuide) {
            let stylePages = try await generateStyleGuidePages()
            for page in stylePages {
                pdfDocument.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        // Save PDF
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(template.name)_\(Date().timeIntervalSince1970).pdf")
        
        pdfDocument.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Page Generation Methods
    
    @MainActor
    private func generateCoverPage() async throws -> PDFPage {
        let coverView = CoverPageView(
            title: content.projectTitle ?? "Wedding Visual Planning",
            subtitle: content.projectSubtitle ?? "Style Guide & Inspiration",
            branding: branding,
            template: template
        )
        
        let renderer = ImageRenderer(content: coverView)
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage,
              let pdfPage = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }
        
        return pdfPage
    }
    
    @MainActor
    private func generateTableOfContents() async throws -> PDFPage {
        let tocView = TableOfContentsView(
            content: content,
            template: template,
            branding: branding
        )
        
        let renderer = ImageRenderer(content: tocView)
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage,
              let pdfPage = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }
        
        return pdfPage
    }
    
    @MainActor
    private func generateMoodBoardPages(_ moodBoard: MoodBoard) async throws -> [PDFPage] {
        var pages: [PDFPage] = []
        
        // Main mood board page
        let moodBoardView = ExportMoodBoardView(
            moodBoard: moodBoard,
            template: template,
            branding: branding,
            showMetadata: template.features.contains(.metadata)
        )
        
        let renderer = ImageRenderer(content: moodBoardView)
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage,
              let mainPage = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }
        
        pages.append(mainPage)
        
        // Additional pages for detailed descriptions if requested
        if template.features.contains(.descriptions) && !moodBoard.elements.isEmpty {
            let detailsView = MoodBoardDetailsView(
                moodBoard: moodBoard,
                branding: branding
            )
            
            let detailsRenderer = ImageRenderer(content: detailsView)
            detailsRenderer.scale = 2.0
            
            if let detailsImage = detailsRenderer.nsImage,
               let detailsPage = PDFPage(image: detailsImage) {
                pages.append(detailsPage)
            }
        }
        
        return pages
    }
    
    @MainActor
    private func generateColorPalettePages() async throws -> [PDFPage] {
        let colorView = ExportColorPalettesView(
            palettes: content.colorPalettes,
            template: template,
            branding: branding,
            showHexCodes: template.features.contains(.hexCodes),
            showUsageGuide: template.features.contains(.usageGuide)
        )
        
        let renderer = ImageRenderer(content: colorView)
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage,
              let page = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }
        
        return [page]
    }
    
    @MainActor
    private func generateSeatingChartPages(_ chart: SeatingChart) async throws -> [PDFPage] {
        var pages: [PDFPage] = []
        
        // Main seating chart
        let chartView = ExportSeatingChartView(
            chart: chart,
            template: template,
            branding: branding,
            showGuestList: template.features.contains(.guestList)
        )
        
        let renderer = ImageRenderer(content: chartView)
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage,
              let mainPage = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }
        
        pages.append(mainPage)
        
        // Guest list page if requested
        if template.features.contains(.guestList), !chart.guests.isEmpty {
            let guestListView = GuestManagementViewV4()
            
            let guestRenderer = ImageRenderer(content: guestListView)
            guestRenderer.scale = 2.0
            
            if let guestImage = guestRenderer.nsImage,
               let guestPage = PDFPage(image: guestImage) {
                pages.append(guestPage)
            }
        }
        
        return pages
    }
    
    @MainActor
    private func generateStyleGuidePages() async throws -> [PDFPage] {
        guard let stylePreferences = content.stylePreferences else {
            return []
        }
        
        let styleGuideView = ExportStyleGuideView(
            preferences: stylePreferences,
            branding: branding,
            template: template
        )
        
        let renderer = ImageRenderer(content: styleGuideView)
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage,
              let page = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }
        
        return [page]
    }
}
