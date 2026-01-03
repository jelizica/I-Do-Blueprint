//
//  SeatingChartExport.swift
//  I Do Blueprint
//
//  Seating chart export view components
//

import SwiftUI

// MARK: - Export Seating Chart View

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
                    .fill(SemanticColors.textSecondary.opacity(Opacity.subtle))
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
            }

            Spacer()
        }
        .padding(Spacing.huge)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}

// MARK: - Statistic View

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
