//
//  ComprehensiveExport.swift
//  I Do Blueprint
//
//  Comprehensive export view components
//

import SwiftUI

// MARK: - Comprehensive Export View

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
                CompactSummaryCard(
                    title: "Mood Boards",
                    value: "\(content.moodBoards.count)",
                    icon: "photo.on.rectangle.angled",
                    color: .blue)

                CompactSummaryCard(
                    title: "Color Palettes",
                    value: "\(content.colorPalettes.count)",
                    icon: "paintpalette",
                    color: .purple)

                CompactSummaryCard(
                    title: "Seating Charts",
                    value: "\(content.seatingCharts.count)",
                    icon: "tablecells",
                    color: .green)

                CompactSummaryCard(
                    title: "Style Guide",
                    value: content.stylePreferences != nil ? "1" : "0",
                    icon: "sparkles",
                    color: .orange)
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
        .padding(Spacing.huge)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

// MARK: - Preview Section

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
        .background(AppColors.textSecondary.opacity(0.1))
        .cornerRadius(8)
    }
}
