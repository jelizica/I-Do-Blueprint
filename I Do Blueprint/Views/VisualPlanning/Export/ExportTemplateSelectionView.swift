//
//  ExportTemplateSelectionView.swift
//  My Wedding Planning App
//
//  Template selection and customization interface for advanced exports
//

import SwiftUI

struct ExportTemplateSelectionView: View {
    @StateObject private var templateService = AdvancedExportTemplateService.shared
    @Environment(\.dismiss) private var dismiss

    let content: ExportContent
    let onExportComplete: (URL) -> Void

    @State private var selectedTemplate: ExportTemplate?
    @State private var selectedCategory: ExportCategory = .moodBoard
    @State private var customizations = ExportCustomizations()
    @State private var showingBrandingSettings = false
    @State private var showingCustomizationPanel = false
    @State private var isExporting = false
    @State private var exportError: Error?
    @State private var showingError = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            HStack(spacing: 0) {
                // Template selection sidebar
                templateSelectionSidebar

                Divider()

                // Main content area
                mainContentArea
            }
        }
        .frame(width: 1000, height: 700)
        .alert("Export Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(exportError?.localizedDescription ?? "Unknown error occurred")
        }
        .sheet(isPresented: $showingBrandingSettings) {
            BrandingSettingsView(branding: $templateService.customBranding)
        }
        .sheet(isPresented: $showingCustomizationPanel) {
            ExportCustomizationView(
                customizations: $customizations,
                template: selectedTemplate)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Export Template Selection")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Choose a professional template for your export")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Branding Settings") {
                    showingBrandingSettings = true
                }
                .buttonStyle(.bordered)

                if selectedTemplate != nil {
                    Button("Customize") {
                        showingCustomizationPanel = true
                    }
                    .buttonStyle(.bordered)
                }

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button(isExporting ? "Exporting..." : "Export") {
                    performExport()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTemplate == nil || isExporting)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Template Selection Sidebar

    private var templateSelectionSidebar: some View {
        VStack(spacing: 0) {
            // Category picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(ExportCategory.allCases, id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.displayName)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Template list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id,
                            content: content) {
                            selectedTemplate = template
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Main Content Area

    private var mainContentArea: some View {
        VStack(spacing: 0) {
            if let selectedTemplate {
                // Template preview and details
                templatePreviewSection(template: selectedTemplate)
            } else {
                // Empty state
                emptyStateSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func templatePreviewSection(template: ExportTemplate) -> some View {
        VStack(spacing: 20) {
            // Template details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: template.category.icon)
                            .foregroundColor(.blue)

                        Text(template.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)

                        Image(systemName: template.outputFormat.icon)
                            .foregroundColor(.purple)

                        Text(template.outputFormat.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                    }
                }

                // Features
                TemplateFeaturesList(features: template.features)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Live preview
            templateLivePreview(template: template)

            Spacer()
        }
        .padding()
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Select a Template")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Choose from our professional export templates to create beautiful presentations of your wedding planning work")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func templateLivePreview(template: ExportTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)

            // Preview container
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Template preview view
                TemplatePreviewView(
                    template: template,
                    content: content,
                    branding: templateService.customBranding)
                    .scaleEffect(0.8)
                    .cornerRadius(8)
            }
            .frame(height: 240)

            // Preview controls
            HStack {
                Text("Live preview with your content")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Refresh Preview") {
                    // Force preview refresh
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Filtered Templates

    private var filteredTemplates: [ExportTemplate] {
        templateService.availableTemplates.filter { template in
            template.category == selectedCategory ||
                (selectedCategory == .comprehensive && template.category == .comprehensive)
        }
    }

    // MARK: - Export Logic

    private func performExport() {
        guard let template = selectedTemplate else { return }

        isExporting = true

        Task {
            do {
                let exportURL = try await templateService.generateExport(
                    template: template,
                    content: content,
                    customizations: customizations)

                await MainActor.run {
                    isExporting = false
                    onExportComplete(exportURL)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: ExportTemplate
    let isSelected: Bool
    let content: ExportContent
    let onSelect: () -> Void

    @State private var previewImage: NSImage?

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Preview image or placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)

                    if let previewImage {
                        Image(nsImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120)
                            .cornerRadius(8)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: template.category.icon)
                                .font(.title)
                                .foregroundColor(.secondary)

                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Template info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Features count
                    Text("\(template.features.count) features")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .onAppear {
            loadPreviewImage()
        }
    }

    private func loadPreviewImage() {
        Task {
            let templateService = AdvancedExportTemplateService.shared
            let image = await templateService.generateTemplatePreview(
                template: template,
                sampleContent: content)

            await MainActor.run {
                previewImage = image
            }
        }
    }
}

// MARK: - Template Features List

struct TemplateFeaturesList: View {
    let features: [TemplateFeature]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Features")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(feature.displayName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Branding Settings View

struct BrandingSettingsView: View {
    @Binding var branding: BrandingSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Branding Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            // Settings form
            Form {
                Section("Company Information") {
                    TextField("Company Name", text: $branding.companyName)
                    TextField("Footer Text", text: $branding.footerText)
                }

                Section("Contact Information") {
                    TextField("Email", text: $branding.contactInfo.email)
                    TextField("Phone", text: $branding.contactInfo.phone)
                    TextField("Website", text: $branding.contactInfo.website)
                    TextField("Address", text: $branding.contactInfo.address)
                }

                Section("Colors") {
                    ColorPicker("Primary Color", selection: $branding.primaryColor)
                    ColorPicker("Secondary Color", selection: $branding.secondaryColor)
                    ColorPicker("Background Color", selection: $branding.backgroundColor)
                    ColorPicker("Text Color", selection: $branding.textColor)
                }

                Section("Watermark") {
                    Toggle("Include Watermark", isOn: $branding.includeWatermark)
                    if branding.includeWatermark {
                        TextField("Watermark Text", text: $branding.watermarkText)
                        HStack {
                            Text("Opacity")
                            Slider(value: $branding.watermarkOpacity, in: 0 ... 1)
                            Text("\(Int(branding.watermarkOpacity * 100))%")
                                .frame(width: 40)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Export Customization View

struct ExportCustomizationView: View {
    @Binding var customizations: ExportCustomizations
    let template: ExportTemplate?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Customizations")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            // Customization form
            Form {
                if template?.outputFormat == .png || template?.outputFormat == .jpeg {
                    Section("Image Quality") {
                        HStack {
                            Text("Scale")
                            Slider(value: $customizations.imageScale, in: 1 ... 4, step: 0.5)
                            Text("\(customizations.imageScale, specifier: "%.1f")x")
                                .frame(width: 40)
                        }

                        if template?.outputFormat == .jpeg {
                            HStack {
                                Text("JPEG Quality")
                                Slider(value: $customizations.jpegQuality, in: 0.1 ... 1.0, step: 0.1)
                                Text("\(Int(customizations.jpegQuality * 100))%")
                                    .frame(width: 40)
                            }
                        }
                    }
                }

                Section("Document Options") {
                    Toggle("Include Timestamp", isOn: $customizations.includeTimestamp)
                    Toggle("Page Numbering", isOn: $customizations.pageNumbering)
                    Toggle("Print Optimized", isOn: $customizations.printOptimized)
                }

                Section("Custom Headers & Footers") {
                    TextField("Custom Header", text: Binding(
                        get: { customizations.customHeader ?? "" },
                        set: { customizations.customHeader = $0.isEmpty ? nil : $0 }))

                    TextField("Custom Footer", text: Binding(
                        get: { customizations.customFooter ?? "" },
                        set: { customizations.customFooter = $0.isEmpty ? nil : $0 }))
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 500)
    }
}

#Preview {
    let sampleContent = ExportContent(
        projectTitle: "Sarah & John's Wedding",
        projectSubtitle: "June 15, 2024",
        moodBoards: [
            MoodBoard(
                tenantId: "sample",
                boardName: "Romantic Garden",
                boardDescription: "Soft and elegant",
                styleCategory: .romantic,
                canvasSize: CGSize(width: 800, height: 600),
                backgroundColor: .white)
        ],
        colorPalettes: [
            ColorPalette(
                name: "Blush & Gold",
                colors: ["#FFC0CB", "#FFFFFF", "#FFD700", "#808080"],
                description: "Romantic blush and gold palette",
                isDefault: false)
        ])

    ExportTemplateSelectionView(
        content: sampleContent,
        onExportComplete: { _ in })
}
