//
//  AdvancedExportTemplateService.swift
//  My Wedding Planning App
//
//  Advanced export templates and customization for professional presentations
//

import Combine
import Foundation
import PDFKit
import SwiftUI

@MainActor
class AdvancedExportTemplateService: ObservableObject {
    static let shared = AdvancedExportTemplateService()

    @Published var availableTemplates: [ExportTemplate] = []
    @Published var customBranding: BrandingSettings = .init()
    @Published var isGenerating = false
    @Published var lastExportURL: URL?

    private let performanceService = PerformanceOptimizationService.shared

    init() {
        loadAvailableTemplates()
        loadCustomBranding()
    }

    // MARK: - Template Management

    private func loadAvailableTemplates() {
        availableTemplates = [
            // Mood Board Templates
            ExportTemplate(
                id: "mood-board-portfolio",
                name: "Portfolio Presentation",
                description: "Professional mood board portfolio with cover page and detailed descriptions",
                category: .moodBoard,
                outputFormat: .pdf,
                features: [.coverPage, .metadata, .descriptions, .colorPalette, .styleGuide],
                previewImage: "template-portfolio"),
            ExportTemplate(
                id: "mood-board-vendor",
                name: "Vendor Presentation",
                description: "Vendor-focused presentation with specifications and requirements",
                category: .moodBoard,
                outputFormat: .pdf,
                features: [.coverPage, .specifications, .requirements, .contactInfo, .timeline],
                previewImage: "template-vendor"),
            ExportTemplate(
                id: "mood-board-inspiration",
                name: "Inspiration Collage",
                description: "Visual-focused layout perfect for social sharing",
                category: .moodBoard,
                outputFormat: .png,
                features: [.collageLayout, .socialOptimized, .branding],
                previewImage: "template-inspiration"),

            // Color Palette Templates
            ExportTemplate(
                id: "color-palette-guide",
                name: "Color Style Guide",
                description: "Comprehensive color guide with hex codes and usage recommendations",
                category: .colorPalette,
                outputFormat: .pdf,
                features: [.hexCodes, .colorNames, .usageGuide, .accessibility, .printing],
                previewImage: "template-color-guide"),
            ExportTemplate(
                id: "color-palette-vendor",
                name: "Vendor Color Sheet",
                description: "Printer-friendly color specifications for vendors",
                category: .colorPalette,
                outputFormat: .pdf,
                features: [.hexCodes, .cmykValues, .pantoneMatching, .printOptimized],
                previewImage: "template-color-vendor"),

            // Seating Chart Templates
            ExportTemplate(
                id: "seating-chart-elegant",
                name: "Elegant Reception Plan",
                description: "Beautiful seating chart with guest details and table assignments",
                category: .seatingChart,
                outputFormat: .pdf,
                features: [.guestList, .tableDetails, .specialRequirements, .decorativeElements],
                previewImage: "template-seating-elegant"),
            ExportTemplate(
                id: "seating-chart-venue",
                name: "Venue Layout Plan",
                description: "Technical layout for venue coordinators and staff",
                category: .seatingChart,
                outputFormat: .pdf,
                features: [.measurements, .staffNotes, .accessibilityInfo, .emergencyExits],
                previewImage: "template-seating-venue"),

            // Comprehensive Templates
            ExportTemplate(
                id: "wedding-vision-book",
                name: "Complete Wedding Vision Book",
                description: "Full presentation including all visual planning elements",
                category: .comprehensive,
                outputFormat: .pdf,
                features: [
                    .coverPage,
                    .tableOfContents,
                    .moodBoards,
                    .colorPalettes,
                    .seatingCharts,
                    .styleGuide,
                    .timeline,
                    .vendorContacts
                ],
                previewImage: "template-vision-book"),
            ExportTemplate(
                id: "vendor-package",
                name: "Vendor Communication Package",
                description: "Complete package for vendor coordination and communication",
                category: .comprehensive,
                outputFormat: .pdf,
                features: [.specifications, .requirements, .timeline, .contactInfo, .budgetAllocation],
                previewImage: "template-vendor-package")
        ]
    }

    // MARK: - Export Generation

    func generateExport(
        template: ExportTemplate,
        content: ExportContent,
        customizations: ExportCustomizations = ExportCustomizations()) async throws -> URL {
        isGenerating = true
        defer { isGenerating = false }

        let generator = ExportGenerator(
            template: template,
            content: content,
            customizations: customizations,
            branding: customBranding,
            performanceService: performanceService)

        let exportURL = try await generator.generate()
        lastExportURL = exportURL

        return exportURL
    }

    func generateBatchExport(
        templates: [ExportTemplate],
        content: ExportContent,
        customizations: ExportCustomizations = ExportCustomizations()) async throws -> [URL] {
        isGenerating = true
        defer { isGenerating = false }

        var exportURLs: [URL] = []

        for template in templates {
            let generator = ExportGenerator(
                template: template,
                content: content,
                customizations: customizations,
                branding: customBranding,
                performanceService: performanceService)

            let exportURL = try await generator.generate()
            exportURLs.append(exportURL)
        }

        return exportURLs
    }

    // MARK: - Template Customization

    func createCustomTemplate(
        name: String,
        description: String,
        category: ExportCategory,
        features: [TemplateFeature],
        layout: TemplateLayout) -> ExportTemplate {
        let customTemplate = ExportTemplate(
            id: "custom-\(UUID().uuidString)",
            name: name,
            description: description,
            category: category,
            outputFormat: .pdf,
            features: features,
            isCustom: true,
            customLayout: layout)

        availableTemplates.append(customTemplate)
        saveCustomTemplates()

        return customTemplate
    }

    func updateCustomBranding(_ branding: BrandingSettings) {
        customBranding = branding
        saveCustomBranding()
    }

    // MARK: - Persistence

    private func saveCustomTemplates() {
        let customTemplates = availableTemplates.filter(\.isCustom)
        if let data = try? JSONEncoder().encode(customTemplates) {
            UserDefaults.standard.set(data, forKey: "CustomExportTemplates")
        }
    }

    private func loadCustomBranding() {
        if let data = UserDefaults.standard.data(forKey: "CustomBranding"),
           let branding = try? JSONDecoder().decode(BrandingSettings.self, from: data) {
            customBranding = branding
        }
    }

    private func saveCustomBranding() {
        if let data = try? JSONEncoder().encode(customBranding) {
            UserDefaults.standard.set(data, forKey: "CustomBranding")
        }
    }

    // MARK: - Template Preview

    func generateTemplatePreview(template: ExportTemplate, sampleContent: ExportContent) async -> NSImage? {
        let previewGenerator = TemplatePreviewGenerator(
            template: template,
            branding: customBranding)

        return await previewGenerator.generatePreview(with: sampleContent)
    }
}

// MARK: - Export Generator

actor ExportGenerator {
    private let template: ExportTemplate
    private let content: ExportContent
    private let customizations: ExportCustomizations
    private let branding: BrandingSettings
    private let performanceService: PerformanceOptimizationService

    init(
        template: ExportTemplate,
        content: ExportContent,
        customizations: ExportCustomizations,
        branding: BrandingSettings,
        performanceService: PerformanceOptimizationService) {
        self.template = template
        self.content = content
        self.customizations = customizations
        self.branding = branding
        self.performanceService = performanceService
    }

    func generate() async throws -> URL {
        switch template.outputFormat {
        case .pdf:
            try await generatePDFExport()
        case .png, .jpeg:
            try await generateImageExport()
        case .svg:
            try await generateSVGExport()
        }
    }

    private func generatePDFExport() async throws -> URL {
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

    @MainActor
    private func generateImageExport() async throws -> URL {
        // Generate high-resolution image export
        let renderer = ImageRenderer(content: generateImageContent())
        renderer.scale = customizations.imageScale

        guard let nsImage = renderer.nsImage else {
            throw ExportError.imageGenerationFailed
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(template.name)_\(Date().timeIntervalSince1970).\(template.outputFormat.fileExtension)")

        let imageData: Data
        switch template.outputFormat {
        case .png:
            guard let data = nsImage.pngData else { throw ExportError.imageGenerationFailed }
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

    private func generateSVGExport() async throws -> URL {
        // Generate SVG export (simplified implementation)
        let svgContent = generateSVGContent()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(template.name)_\(Date().timeIntervalSince1970).svg")

        try svgContent.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    // MARK: - Page Generation Methods

    @MainActor
    private func generateCoverPage() async throws -> PDFPage {
        let coverView = CoverPageView(
            title: content.projectTitle ?? "Wedding Visual Planning",
            subtitle: content.projectSubtitle ?? "Style Guide & Inspiration",
            branding: branding,
            template: template)

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
            branding: branding)

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
            showMetadata: template.features.contains(.metadata))

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
            showUsageGuide: template.features.contains(.usageGuide))

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
            showGuestList: template.features.contains(.guestList))

        let renderer = ImageRenderer(content: chartView)
        renderer.scale = 2.0

        guard let image = renderer.nsImage,
              let mainPage = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }

        pages.append(mainPage)

        // Guest list page if requested
        if template.features.contains(.guestList), !chart.guests.isEmpty {
            let guestListView = GuestListView()

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
            template: template)

        let renderer = ImageRenderer(content: styleGuideView)
        renderer.scale = 2.0

        guard let image = renderer.nsImage,
              let page = PDFPage(image: image) else {
            throw ExportError.pageGenerationFailed
        }

        return [page]
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
                    showMetadata: template.features.contains(.metadata))
            }
        case .colorPalette:
            ExportColorPalettesView(
                palettes: content.colorPalettes,
                template: template,
                branding: branding,
                showHexCodes: template.features.contains(.hexCodes),
                showUsageGuide: template.features.contains(.usageGuide))
        case .seatingChart:
            if let chart = content.seatingCharts.first {
                ExportSeatingChartView(
                    chart: chart,
                    template: template,
                    branding: branding,
                    showGuestList: template.features.contains(.guestList))
            }
        case .comprehensive:
            ComprehensiveExportView(
                content: content,
                template: template,
                branding: branding)
        }
    }

    private func generateSVGContent() -> String {
        // Simplified SVG generation - in production this would be more sophisticated
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">
            <rect width="100%" height="100%" fill="\(branding.backgroundColor.toHex())"/>
            <text x="400" y="300" text-anchor="middle" font-size="24" fill="\(branding.primaryColor.toHex())">
                \(content.projectTitle ?? "Wedding Planning Export")
            </text>
        </svg>
        """
    }
}

// MARK: - Data Models

struct ExportTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: ExportCategory
    let outputFormat: ExportFormat
    let features: [TemplateFeature]
    let previewImage: String?
    let isCustom: Bool
    let customLayout: TemplateLayout?

    init(
        id: String,
        name: String,
        description: String,
        category: ExportCategory,
        outputFormat: ExportFormat,
        features: [TemplateFeature],
        previewImage: String? = nil,
        isCustom: Bool = false,
        customLayout: TemplateLayout? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.outputFormat = outputFormat
        self.features = features
        self.previewImage = previewImage
        self.isCustom = isCustom
        self.customLayout = customLayout
    }
}

enum ExportCategory: String, CaseIterable, Codable {
    case moodBoard = "mood_board"
    case colorPalette = "color_palette"
    case seatingChart = "seating_chart"
    case comprehensive

    var displayName: String {
        switch self {
        case .moodBoard: "Mood Board"
        case .colorPalette: "Color Palette"
        case .seatingChart: "Seating Chart"
        case .comprehensive: "Comprehensive"
        }
    }

    var icon: String {
        switch self {
        case .moodBoard: "photo.on.rectangle.angled"
        case .colorPalette: "paintpalette"
        case .seatingChart: "tablecells"
        case .comprehensive: "doc.richtext"
        }
    }
}

enum ExportFormat: String, CaseIterable, Codable {
    case pdf
    case png
    case jpeg
    case svg

    var displayName: String {
        rawValue.uppercased()
    }

    var fileExtension: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .pdf: "doc.richtext"
        case .png, .jpeg: "photo"
        case .svg: "square.and.pencil"
        }
    }
}

enum TemplateFeature: String, CaseIterable, Codable {
    case coverPage = "cover_page"
    case tableOfContents = "table_of_contents"
    case metadata
    case descriptions
    case colorPalette = "color_palette"
    case styleGuide = "style_guide"
    case hexCodes = "hex_codes"
    case colorNames = "color_names"
    case usageGuide = "usage_guide"
    case accessibility
    case printing
    case cmykValues = "cmyk_values"
    case pantoneMatching = "pantone_matching"
    case printOptimized = "print_optimized"
    case guestList = "guest_list"
    case tableDetails = "table_details"
    case specialRequirements = "special_requirements"
    case decorativeElements = "decorative_elements"
    case measurements
    case staffNotes = "staff_notes"
    case accessibilityInfo = "accessibility_info"
    case emergencyExits = "emergency_exits"
    case specifications
    case requirements
    case contactInfo = "contact_info"
    case timeline
    case vendorContacts = "vendor_contacts"
    case budgetAllocation = "budget_allocation"
    case moodBoards = "mood_boards"
    case colorPalettes = "color_palettes"
    case seatingCharts = "seating_charts"
    case collageLayout = "collage_layout"
    case socialOptimized = "social_optimized"
    case branding

    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var description: String {
        switch self {
        case .coverPage: "Professional cover page with title and branding"
        case .tableOfContents: "Organized table of contents for navigation"
        case .metadata: "Detailed information about each element"
        case .descriptions: "Comprehensive descriptions and inspiration notes"
        case .colorPalette: "Color swatches and palette information"
        case .styleGuide: "Complete style guide with guidelines"
        case .hexCodes: "Precise hex color codes for reproduction"
        case .guestList: "Complete guest list with seating assignments"
        case .socialOptimized: "Optimized dimensions for social media sharing"
        case .branding: "Custom branding and watermarks"
        default: displayName
        }
    }
}

struct TemplateLayout: Codable {
    var pageSize: CGSize
    var margins: CodableEdgeInsets
    var columns: Int
    var spacing: CGFloat
    var headerHeight: CGFloat
    var footerHeight: CGFloat
}

struct CodableEdgeInsets: Codable {
    var top: CGFloat
    var leading: CGFloat
    var bottom: CGFloat
    var trailing: CGFloat

    init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    var edgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

struct BrandingSettings: Codable {
    var companyName: String = ""
    var companyLogo: String? // Base64 encoded image
    var primaryColor: Color = .blue
    var secondaryColor: Color = .gray
    var backgroundColor: Color = .white
    var textColor: Color = .black
    var fontFamily: String = "System"
    var watermarkText: String = ""
    var watermarkOpacity: Double = 0.1
    var includeWatermark: Bool = false
    var footerText: String = ""
    var contactInfo: ContactInfo = .init()
}

struct ContactInfo: Codable {
    var email: String = ""
    var phone: String = ""
    var website: String = ""
    var address: String = ""
}

struct ExportContent {
    var projectTitle: String?
    var projectSubtitle: String?
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []
    var stylePreferences: StylePreferences?
}

struct ExportCustomizations {
    var imageScale: CGFloat = 2.0
    var jpegQuality: CGFloat = 0.9
    var includeTimestamp: Bool = true
    var customHeader: String?
    var customFooter: String?
    var pageNumbering: Bool = true
    var printOptimized: Bool = false
}

enum ExportError: LocalizedError {
    case pageGenerationFailed
    case imageGenerationFailed
    case unsupportedFormat
    case templateNotFound

    var errorDescription: String? {
        switch self {
        case .pageGenerationFailed: "Failed to generate PDF page"
        case .imageGenerationFailed: "Failed to generate image"
        case .unsupportedFormat: "Unsupported export format"
        case .templateNotFound: "Template not found"
        }
    }
}

// MARK: - Extensions

extension NSImage {
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmapRep.representation(using: .png, properties: [:])
    }

    func jpegData(compressionFactor: CGFloat) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
    }
}
