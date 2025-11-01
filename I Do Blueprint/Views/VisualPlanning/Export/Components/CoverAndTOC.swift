//
//  CoverAndTOC.swift
//  I Do Blueprint
//
//  Cover page and table of contents components for exports
//

import SwiftUI

// MARK: - Cover Page View

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
        .padding(Spacing.huge)
        .frame(width: 595, height: 842) // A4 size in points
        .background(branding.backgroundColor)
    }
}

// MARK: - Table of Contents View

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
        .padding(Spacing.huge)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

// MARK: - Contents Item

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
            .foregroundColor(AppColors.textSecondary)
            .frame(height: 20)

            Text("\(pageNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
