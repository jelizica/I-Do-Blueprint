//
//  ExportTemplateManager.swift
//  I Do Blueprint
//
//  Template management and persistence service
//

import Foundation
import SwiftUI

/// Protocol for template management operations
protocol ExportTemplateManagerProtocol {
    func loadAvailableTemplates() -> [ExportTemplate]
    func loadCustomTemplates() -> [ExportTemplate]
    func saveCustomTemplate(_ template: ExportTemplate)
    func deleteCustomTemplate(id: String)
}

/// Service responsible for template management and persistence
class ExportTemplateManager: ExportTemplateManagerProtocol {
    
    // MARK: - Template Loading
    
    func loadAvailableTemplates() -> [ExportTemplate] {
        [
            // Mood Board Templates
            ExportTemplate(
                id: "mood-board-portfolio",
                name: "Portfolio Presentation",
                description: "Professional mood board portfolio with cover page and detailed descriptions",
                category: .moodBoard,
                outputFormat: .pdf,
                features: [.coverPage, .metadata, .descriptions, .colorPalette, .styleGuide],
                previewImage: "template-portfolio"
            ),
            ExportTemplate(
                id: "mood-board-vendor",
                name: "Vendor Presentation",
                description: "Vendor-focused presentation with specifications and requirements",
                category: .moodBoard,
                outputFormat: .pdf,
                features: [.coverPage, .specifications, .requirements, .contactInfo, .timeline],
                previewImage: "template-vendor"
            ),
            ExportTemplate(
                id: "mood-board-inspiration",
                name: "Inspiration Collage",
                description: "Visual-focused layout perfect for social sharing",
                category: .moodBoard,
                outputFormat: .png,
                features: [.collageLayout, .socialOptimized, .branding],
                previewImage: "template-inspiration"
            ),
            
            // Color Palette Templates
            ExportTemplate(
                id: "color-palette-guide",
                name: "Color Style Guide",
                description: "Comprehensive color guide with hex codes and usage recommendations",
                category: .colorPalette,
                outputFormat: .pdf,
                features: [.hexCodes, .colorNames, .usageGuide, .accessibility, .printing],
                previewImage: "template-color-guide"
            ),
            ExportTemplate(
                id: "color-palette-vendor",
                name: "Vendor Color Sheet",
                description: "Printer-friendly color specifications for vendors",
                category: .colorPalette,
                outputFormat: .pdf,
                features: [.hexCodes, .cmykValues, .pantoneMatching, .printOptimized],
                previewImage: "template-color-vendor"
            ),
            
            // Seating Chart Templates
            ExportTemplate(
                id: "seating-chart-elegant",
                name: "Elegant Reception Plan",
                description: "Beautiful seating chart with guest details and table assignments",
                category: .seatingChart,
                outputFormat: .pdf,
                features: [.guestList, .tableDetails, .specialRequirements, .decorativeElements],
                previewImage: "template-seating-elegant"
            ),
            ExportTemplate(
                id: "seating-chart-venue",
                name: "Venue Layout Plan",
                description: "Technical layout for venue coordinators and staff",
                category: .seatingChart,
                outputFormat: .pdf,
                features: [.measurements, .staffNotes, .accessibilityInfo, .emergencyExits],
                previewImage: "template-seating-venue"
            ),
            
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
                previewImage: "template-vision-book"
            ),
            ExportTemplate(
                id: "vendor-package",
                name: "Vendor Communication Package",
                description: "Complete package for vendor coordination and communication",
                category: .comprehensive,
                outputFormat: .pdf,
                features: [.specifications, .requirements, .timeline, .contactInfo, .budgetAllocation],
                previewImage: "template-vendor-package"
            )
        ]
    }
    
    func loadCustomTemplates() -> [ExportTemplate] {
        guard let data = UserDefaults.standard.data(forKey: "CustomExportTemplates"),
              let templates = try? JSONDecoder().decode([ExportTemplate].self, from: data) else {
            return []
        }
        return templates
    }
    
    // MARK: - Template Persistence
    
    func saveCustomTemplate(_ template: ExportTemplate) {
        var customTemplates = loadCustomTemplates()
        
        // Remove existing template with same ID if present
        customTemplates.removeAll { $0.id == template.id }
        
        // Add new/updated template
        customTemplates.append(template)
        
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(customTemplates) {
            UserDefaults.standard.set(data, forKey: "CustomExportTemplates")
        }
    }
    
    func deleteCustomTemplate(id: String) {
        var customTemplates = loadCustomTemplates()
        customTemplates.removeAll { $0.id == id }
        
        if let data = try? JSONEncoder().encode(customTemplates) {
            UserDefaults.standard.set(data, forKey: "CustomExportTemplates")
        }
    }
    
    // MARK: - Template Creation
    
    func createCustomTemplate(
        name: String,
        description: String,
        category: ExportCategory,
        features: [TemplateFeature],
        layout: TemplateLayout
    ) -> ExportTemplate {
        let template = ExportTemplate(
            id: "custom-\(UUID().uuidString)",
            name: name,
            description: description,
            category: category,
            outputFormat: .pdf,
            features: features,
            isCustom: true,
            customLayout: layout
        )
        
        saveCustomTemplate(template)
        return template
    }
    
    // MARK: - Template Preview
    
    func generateTemplatePreview(
        template: ExportTemplate,
        sampleContent: ExportContent,
        branding: BrandingSettings
    ) async -> NSImage? {
        let previewGenerator = TemplatePreviewGenerator(
            template: template,
            branding: branding
        )
        
        return await previewGenerator.generatePreview(with: sampleContent)
    }
}
