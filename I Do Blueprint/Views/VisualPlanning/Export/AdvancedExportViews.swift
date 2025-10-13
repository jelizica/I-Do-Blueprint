//
//  AdvancedExportViews.swift
//  My Wedding Planning App
//
//  Advanced export template views for professional presentations
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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
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
        .padding(20)
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
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
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
                        .fill(Color.gray.opacity(0.3))
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
                    .fill(Color.gray.opacity(0.1))
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

// MARK: - Export Template Views

struct CoverPageView: View {
    let title: String
    let subtitle: String
    let branding: BrandingSettings
    let template: ExportTemplate

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo and branding
            if !branding.companyName.isEmpty {
                VStack(spacing: 8) {
                    if let logoData = branding.companyLogo,
                       let data = Data(base64Encoded: logoData),
                       let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 100)
                    }

                    Text(branding.companyName)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(branding.primaryColor)
                }
            }

            // Main title
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(branding.textColor)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(branding.textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Date and template info
            VStack(spacing: 8) {
                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundColor(branding.textColor.opacity(0.7))

                Text("Generated with \(template.name)")
                    .font(.caption)
                    .foregroundColor(branding.textColor.opacity(0.5))
            }

            Spacer(minLength: 50)
        }
        .padding(60)
        .frame(width: 595, height: 842) // A4 size in points
        .background(branding.backgroundColor)
    }
}

struct TableOfContentsView: View {
    let content: ExportContent
    let template: ExportTemplate
    let branding: BrandingSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header
            Text("Table of Contents")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(branding.primaryColor)

            // Contents
            VStack(alignment: .leading, spacing: 16) {
                if template.features.contains(.moodBoards), !content.moodBoards.isEmpty {
                    ContentsItem(title: "Mood Boards", pageNumber: 3, level: 0)
                    ForEach(Array(content.moodBoards.enumerated()), id: \.offset) { index, moodBoard in
                        ContentsItem(title: moodBoard.boardName, pageNumber: 4 + index, level: 1)
                    }
                }

                if template.features.contains(.colorPalettes), !content.colorPalettes.isEmpty {
                    ContentsItem(title: "Color Palettes", pageNumber: 10, level: 0)
                }

                if template.features.contains(.seatingCharts), !content.seatingCharts.isEmpty {
                    ContentsItem(title: "Seating Charts", pageNumber: 12, level: 0)
                }

                if template.features.contains(.styleGuide) {
                    ContentsItem(title: "Style Guide", pageNumber: 15, level: 0)
                }
            }

            Spacer()
        }
        .padding(60)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

struct ContentsItem: View {
    let title: String
    let pageNumber: Int
    let level: Int

    var body: some View {
        HStack {
            Text(title)
                .font(level == 0 ? .headline : .subheadline)
                .fontWeight(level == 0 ? .semibold : .regular)
                .padding(.leading, CGFloat(level) * 20)

            Spacer()

            // Dotted line
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                path.addLine(to: CGPoint(x: 100, y: 10))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            .foregroundColor(.gray)
            .frame(height: 20)

            Text("\(pageNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ExportMoodBoardView: View {
    let moodBoard: MoodBoard
    let template: ExportTemplate
    let branding: BrandingSettings
    let showMetadata: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(moodBoard.boardName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(branding.primaryColor)

                if let description = moodBoard.boardDescription, !description.isEmpty {
                    Text(description)
                        .font(.title3)
                        .foregroundColor(branding.textColor.opacity(0.8))
                }

                Text("Style: \(moodBoard.styleCategory.displayName)")
                    .font(.subheadline)
                    .foregroundColor(branding.textColor.opacity(0.7))
            }

            // Mood board canvas
            ZStack {
                Rectangle()
                    .fill(moodBoard.backgroundColor)
                    .aspectRatio(moodBoard.canvasSize.width / moodBoard.canvasSize.height, contentMode: .fit)
                    .frame(maxHeight: 400)

                ForEach(moodBoard.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                    ExportElementView(element: element)
                        .position(element.position)
                }
            }

            // Metadata section
            if showMetadata, !moodBoard.elements.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Elements")
                        .font(.headline)
                        .foregroundColor(branding.primaryColor)

                    ForEach(Array(moodBoard.elements.enumerated()), id: \.offset) { index, element in
                        ElementMetadataRow(element: element, index: index + 1, branding: branding)
                    }
                }
            }

            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

struct ExportElementView: View {
    let element: VisualElement

    @ViewBuilder
    var body: some View {
        switch element.elementType {
        case .image:
            // Note: Image loading from URL would require AsyncImage or pre-loaded data
            // For now, show placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray))

        case .color:
            Rectangle()
                .fill(element.elementData.color ?? .gray)

        case .text:
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.8))

                Text(element.elementData.text ?? "Text")
                    .font(.system(size: max(8, element.size.height * 0.3)))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }

        case .inspiration:
            VStack(spacing: 2) {
                Image(systemName: "lightbulb")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text(element.elementData.text ?? "Inspiration")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(4)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)
        }
    }
}

struct ElementMetadataRow: View {
    let element: VisualElement
    let index: Int
    let branding: BrandingSettings

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index).")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(branding.primaryColor)
                .frame(width: 20, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(element.elementType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let text = element.elementData.text, !text.isEmpty {
                    Text("Text: \(text)")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))
                }

                if let color = element.elementData.color {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)

                        Text(color.toHex())
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(branding.textColor.opacity(0.7))
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ExportColorPalettesView: View {
    let palettes: [ColorPalette]
    let template: ExportTemplate
    let branding: BrandingSettings
    let showHexCodes: Bool
    let showUsageGuide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header
            Text("Color Palettes")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(branding.primaryColor)

            // Palettes
            ForEach(palettes) { palette in
                ColorPaletteExportCard(
                    palette: palette,
                    branding: branding,
                    showHexCodes: showHexCodes,
                    showUsageGuide: showUsageGuide)
            }

            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

struct ColorPaletteExportCard: View {
    let palette: ColorPalette
    let branding: BrandingSettings
    let showHexCodes: Bool
    let showUsageGuide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Palette header
            VStack(alignment: .leading, spacing: 4) {
                Text(palette.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(branding.textColor)

                if let description = palette.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(branding.textColor.opacity(0.7))
                }
            }

            // Color swatches
            HStack(spacing: 16) {
                ForEach(palette.colors.prefix(4).indices, id: \.self) { index in
                    if let color = Color.fromHexString(palette.colors[index]) {
                        ColorSwatch(color: color, size: 60)
                    }
                }
            }

            // Usage guide
            if showUsageGuide {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage Guidelines")
                        .font(.headline)
                        .foregroundColor(branding.primaryColor)

                    Text("Primary: Main color for headers and important elements")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))

                    Text("Secondary: Supporting color for backgrounds and accents")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))

                    Text("Accent: Highlight color for calls-to-action and emphasis")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))

                    Text("Neutral: Text and subtle background elements")
                        .font(.caption)
                        .foregroundColor(branding.textColor.opacity(0.7))
                }
            }
        }
        .padding()
        .background(branding.primaryColor.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ExportSeatingChartView: View {
    let chart: SeatingChart
    let template: ExportTemplate
    let branding: BrandingSettings
    let showGuestList: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(chart.chartName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(branding.primaryColor)

                if let description = chart.chartDescription, !description.isEmpty {
                    Text(description)
                        .font(.title3)
                        .foregroundColor(branding.textColor.opacity(0.8))
                }

                HStack {
                    Text("\(chart.guests.count) guests")
                    Text("•")
                    Text("\(chart.tables.count) tables")
                }
                .font(.subheadline)
                .foregroundColor(branding.textColor.opacity(0.7))
            }

            // Seating chart visualization
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxHeight: 300)

                ForEach(chart.tables) { table in
                    TableExportView(table: table, assignments: [], guests: chart.guests)
                        .position(table.position)
                }
            }

            // Statistics
            HStack(spacing: 32) {
                StatisticView(title: "Total Tables", value: "\(chart.tables.count)", color: branding.primaryColor)
                StatisticView(title: "Total Guests", value: "\(chart.guests.count)", color: branding.secondaryColor)
                // Note: SeatingChart doesn't have seatAssignments property
                // StatisticView(title: "Assigned Seats", value: "\(chart.seatAssignments.count)", color: branding.primaryColor)
            }

            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ExportStyleGuideView: View {
    let preferences: StylePreferences
    let branding: BrandingSettings
    let template: ExportTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header
            Text("Wedding Style Guide")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(branding.primaryColor)

            // Primary style
            if let primaryStyle = preferences.primaryStyle {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Style")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(branding.primaryColor)

                    HStack(spacing: 16) {
                        Image(systemName: primaryStyle.icon)
                            .font(.largeTitle)
                            .foregroundColor(branding.primaryColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(primaryStyle.displayName)
                                .font(.title3)
                                .fontWeight(.medium)

                            Text(primaryStyle.displayName)
                                .font(.subheadline)
                                .foregroundColor(branding.textColor.opacity(0.7))
                        }
                    }
                }
            }

            // Color preferences
            if !preferences.primaryColors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Palette")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(branding.primaryColor)

                    HStack(spacing: 12) {
                        ForEach(Array(preferences.primaryColors.enumerated()), id: \.offset) { _, color in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 50, height: 50)

                                Text(color.toHex())
                                    .font(.caption2)
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                    }
                }
            }

            // Guidelines
            if let guidelines = preferences.guidelines,
               !guidelines.doElements.isEmpty || !guidelines.avoidElements.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Style Guidelines")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(branding.primaryColor)

                    if !guidelines.doElements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Do Include:")
                                .font(.headline)
                                .foregroundColor(.green)

                            ForEach(guidelines.doElements, id: \.self) { element in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(element)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }

                    if !guidelines.avoidElements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avoid:")
                                .font(.headline)
                                .foregroundColor(.red)

                            ForEach(guidelines.avoidElements, id: \.self) { element in
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text(element)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

struct ComprehensiveExportView: View {
    let content: ExportContent
    let template: ExportTemplate
    let branding: BrandingSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text(content.projectTitle ?? "Wedding Planning Portfolio")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(branding.primaryColor)

            // Summary grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                SummaryCard(
                    title: "Mood Boards",
                    value: Double(content.moodBoards.count),
                    change: nil,
                    color: .blue,
                    icon: "photo.on.rectangle.angled")

                SummaryCard(
                    title: "Color Palettes",
                    value: Double(content.colorPalettes.count),
                    change: nil,
                    color: .purple,
                    icon: "paintpalette")

                SummaryCard(
                    title: "Seating Charts",
                    value: Double(content.seatingCharts.count),
                    change: nil,
                    color: .green,
                    icon: "tablecells")

                SummaryCard(
                    title: "Style Guide",
                    value: Double(content.stylePreferences != nil ? 1 : 0),
                    change: nil,
                    color: .orange,
                    icon: "sparkles")
            }

            // Preview sections
            VStack(alignment: .leading, spacing: 16) {
                if !content.moodBoards.isEmpty {
                    PreviewSection(title: "Mood Boards", count: content.moodBoards.count)
                }

                if !content.colorPalettes.isEmpty {
                    PreviewSection(title: "Color Palettes", count: content.colorPalettes.count)
                }

                if !content.seatingCharts.isEmpty {
                    PreviewSection(title: "Seating Charts", count: content.seatingCharts.count)
                }
            }

            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

struct PreviewSection: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            Text("\(count) items")
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
