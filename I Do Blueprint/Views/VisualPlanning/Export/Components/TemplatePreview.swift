//
//  TemplatePreview.swift
//  I Do Blueprint
//
//  Template preview generator and view components
//

import SwiftUI

// MARK: - Template Preview Generator

class TemplatePreviewGenerator {
    private let template: ExportTemplate
    private let branding: BrandingSettings

    init(template: ExportTemplate, branding: BrandingSettings) {
        self.template = template
        self.branding = branding
    }

    func generatePreview(with content: ExportContent) async -> NSImage? {
        let previewView = TemplatePreviewView(
            template: template,
            content: content,
            branding: branding)

        let renderer = ImageRenderer(content: previewView)
        renderer.scale = 1.0

        return renderer.nsImage
    }
}

// MARK: - Template Preview View

struct TemplatePreviewView: View {
    let template: ExportTemplate
    let content: ExportContent
    let branding: BrandingSettings

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            headerSection

            // Main content preview
            mainContentSection

            // Footer section
            footerSection
        }
        .frame(width: 400, height: 300)
        .background(branding.backgroundColor)
        .overlay(
            watermarkOverlay,
            alignment: .center)
    }

    private var headerSection: some View {
        HStack {
            if template.features.contains(.branding) {
                Text(branding.companyName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(branding.primaryColor)
            }

            Spacer()

            Text(template.name)
                .font(.caption)
                .foregroundColor(branding.textColor.opacity(0.7))
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(branding.primaryColor.opacity(0.1))
    }

    private var mainContentSection: some View {
        VStack(spacing: 12) {
            // Content preview based on template category
            switch template.category {
            case .moodBoard:
                moodBoardPreview
            case .colorPalette:
                colorPalettePreview
            case .seatingChart:
                seatingChartPreview
            case .comprehensive:
                comprehensivePreview
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerSection: some View {
        Group {
            if template.features.contains(.contactInfo) || !branding.footerText.isEmpty {
                HStack {
                    if !branding.footerText.isEmpty {
                        Text(branding.footerText)
                            .font(.caption2)
                            .foregroundColor(branding.textColor.opacity(0.6))
                    }

                    Spacer()

                    if !branding.contactInfo.email.isEmpty {
                        Text(branding.contactInfo.email)
                            .font(.caption2)
                            .foregroundColor(branding.textColor.opacity(0.6))
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.sm)
                .background(branding.primaryColor.opacity(0.05))
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var watermarkOverlay: some View {
        if branding.includeWatermark, !branding.watermarkText.isEmpty {
            Text(branding.watermarkText)
                .font(.title)
                .fontWeight(.light)
                .foregroundColor(branding.textColor.opacity(branding.watermarkOpacity))
                .rotationEffect(.degrees(-45))
        }
    }

    // MARK: - Content Previews

    private var moodBoardPreview: some View {
        VStack(spacing: 8) {
            if template.features.contains(.coverPage) {
                Rectangle()
                    .fill(branding.primaryColor.opacity(0.3))
                    .frame(height: 40)
                    .overlay(
                        Text("Cover Page")
                            .font(.caption)
                            .foregroundColor(branding.textColor))
            }

            HStack(spacing: 8) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    Rectangle()
                        .fill(SemanticColors.textSecondary.opacity(Opacity.light))
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            if template.features.contains(.metadata) {
                Rectangle()
                    .fill(branding.secondaryColor.opacity(0.2))
                    .frame(height: 30)
                    .overlay(
                        Text("Metadata & Descriptions")
                            .font(.caption2)
                            .foregroundColor(branding.textColor))
            }
        }
    }

    private var colorPalettePreview: some View {
        VStack(spacing: 8) {
            if template.features.contains(.hexCodes) {
                Text("Color Palette with Hex Codes")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(branding.textColor)
            }

            HStack(spacing: 8) {
                ForEach([Color.blue, Color.purple, Color.pink, Color.orange], id: \.self) { color in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)

                        if template.features.contains(.hexCodes) {
                            Text("#HEX")
                                .font(.caption2)
                                .foregroundColor(branding.textColor.opacity(0.7))
                        }
                    }
                }
            }

            if template.features.contains(.usageGuide) {
                Rectangle()
                    .fill(branding.secondaryColor.opacity(0.2))
                    .frame(height: 25)
                    .overlay(
                        Text("Usage Guidelines")
                            .font(.caption2)
                            .foregroundColor(branding.textColor))
            }
        }
    }

    private var seatingChartPreview: some View {
        VStack(spacing: 8) {
            // Chart preview
            ZStack {
                Rectangle()
                    .fill(SemanticColors.textSecondary.opacity(Opacity.subtle))
                    .frame(height: 80)

                ForEach(0 ..< 6, id: \.self) { index in
                    Circle()
                        .fill(branding.primaryColor.opacity(0.6))
                        .frame(width: 12, height: 12)
                        .position(
                            x: 50 + CGFloat(index % 3) * 40,
                            y: 25 + CGFloat(index / 3) * 30)
                }
            }

            if template.features.contains(.guestList) {
                Rectangle()
                    .fill(branding.secondaryColor.opacity(0.2))
                    .frame(height: 30)
                    .overlay(
                        Text("Guest List & Assignments")
                            .font(.caption2)
                            .foregroundColor(branding.textColor))
            }
        }
    }

    private var comprehensivePreview: some View {
        VStack(spacing: 6) {
            ForEach(["Cover", "Mood Boards", "Colors", "Seating", "Style Guide"], id: \.self) { section in
                Rectangle()
                    .fill(branding.primaryColor.opacity(0.3))
                    .frame(height: 20)
                    .overlay(
                        Text(section)
                            .font(.caption2)
                            .foregroundColor(branding.textColor))
            }
        }
    }
}
