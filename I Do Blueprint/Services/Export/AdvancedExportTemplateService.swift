//
//  AdvancedExportTemplateService.swift
//  My Wedding Planning App
//
//  Advanced export templates and customization for professional presentations
//

// swiftlint:disable file_length

import Combine
import Foundation
import PDFKit
import SwiftUI

// Import extracted models
// Models are now in Services/Export/Models/
// - ExportTemplate.swift: ExportTemplate, ExportCategory, ExportFormat, TemplateFeature, TemplateLayout, CodableEdgeInsets
// - BrandingSettings.swift: BrandingSettings, ContactInfo
// - ExportModels.swift: ExportContent, ExportCustomizations, ExportError

@MainActor
class AdvancedExportTemplateService: ObservableObject {
    static let shared = AdvancedExportTemplateService()

    @Published var availableTemplates: [ExportTemplate] = []
    @Published var customBranding: BrandingSettings = .init()
    @Published var isGenerating = false
    @Published var lastExportURL: URL?

    // Composed services
    private let templateManager: ExportTemplateManager
    private let brandingManager: BrandingSettingsManager
    private let performanceService = PerformanceOptimizationService.shared

    init(
        templateManager: ExportTemplateManager = ExportTemplateManager(),
        brandingManager: BrandingSettingsManager = BrandingSettingsManager()
    ) {
        self.templateManager = templateManager
        self.brandingManager = brandingManager
        
        loadAvailableTemplates()
        loadCustomBranding()
    }

    // MARK: - Template Management

    private func loadAvailableTemplates() {
        let builtInTemplates = templateManager.loadAvailableTemplates()
        let customTemplates = templateManager.loadCustomTemplates()
        availableTemplates = builtInTemplates + customTemplates
    }

    // MARK: - Export Generation

    func generateExport(
        template: ExportTemplate,
        content: ExportContent,
        customizations: ExportCustomizations = ExportCustomizations()) async throws -> URL {
        isGenerating = true
        defer { isGenerating = false }

        let exportURL: URL
        
        // Delegate to format-specific generators
        switch template.outputFormat {
        case .pdf:
            let pdfGenerator = PDFExportGenerator(
                template: template,
                content: content,
                customizations: customizations,
                branding: customBranding
            )
            exportURL = try await pdfGenerator.generatePDF(
                template: template,
                content: content,
                customizations: customizations,
                branding: customBranding
            )
            
        case .png, .jpeg:
            let imageGenerator = ImageExportGenerator(
                template: template,
                content: content,
                customizations: customizations,
                branding: customBranding
            )
            exportURL = try await imageGenerator.generateImage()
            
        case .svg:
            let svgGenerator = SVGExportGenerator(
                template: template,
                content: content,
                customizations: customizations,
                branding: customBranding
            )
            exportURL = try await svgGenerator.generateSVG(
                template: template,
                content: content,
                customizations: customizations,
                branding: customBranding
            )
        }
        
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
            let exportURL = try await generateExport(
                template: template,
                content: content,
                customizations: customizations
            )
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
        layout: TemplateLayout
    ) -> ExportTemplate {
        let customTemplate = templateManager.createCustomTemplate(
            name: name,
            description: description,
            category: category,
            features: features,
            layout: layout
        )
        
        availableTemplates.append(customTemplate)
        return customTemplate
    }

    func updateCustomBranding(_ branding: BrandingSettings) {
        customBranding = branding
        brandingManager.saveBranding(branding)
    }

    // MARK: - Persistence

    private func loadCustomBranding() {
        customBranding = brandingManager.loadBranding()
    }

    // MARK: - Template Preview

    func generateTemplatePreview(
        template: ExportTemplate,
        sampleContent: ExportContent
    ) async -> NSImage? {
        await templateManager.generateTemplatePreview(
            template: template,
            sampleContent: sampleContent,
            branding: customBranding
        )
    }
}

// MARK: - Export Generators
// All format-specific generation logic has been extracted to Services/Export/Generators/
// - PDFExportGenerator.swift: PDF generation with page composition
// - ImageExportGenerator.swift: PNG/JPEG generation with ImageRenderer
// - SVGExportGenerator.swift: SVG generation

// MARK: - Data Models
// All data models have been extracted to Services/Export/Models/
// This keeps the service focused on business logic rather than data structures

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
