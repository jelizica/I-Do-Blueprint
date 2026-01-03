//
//  ExportInterfaceView.swift
//  My Wedding Planning App
//
//  User interface for exporting visual planning content
//

import SwiftUI

struct ExportInterfaceView: View {
    @StateObject private var exportService = ExportService()
    @Environment(\.dismiss) private var dismiss

    let exportType: ExportType
    let item: ExportableItem

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var selectedQuality: ExportQuality = .high
    @State private var includeMetadata = true
    @State private var includeHexCodes = true
    @State private var includeGuestList = true
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var exportError: Error?
    @State private var showingError = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Preview section
                    previewSection

                    // Export settings
                    exportSettingsSection

                    // Format-specific options
                    formatOptionsSection
                }
                .padding()
            }

            Divider()

            // Actions
            actionButtonsSection
        }
        .frame(width: 600, height: 700)
        .alert("Export Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(exportError?.localizedDescription ?? "Unknown error occurred")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Image(systemName: exportType.icon)
                .font(.title2)
                .foregroundColor(exportType.color)

            VStack(alignment: .leading, spacing: 2) {
                Text("Export \(exportType.title)")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(item.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
        }
        .padding()
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)

            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.textSecondary.opacity(Opacity.subtle))
                .frame(height: 150)
                .overlay(
                    Group {
                        switch exportType {
                        case .moodBoard:
                            if case .moodBoard(let moodBoard) = item {
                                MoodBoardPreviewThumbnail(moodBoard: moodBoard)
                            }

                        case .colorPalette:
                            if case .colorPalette(let palette) = item {
                                ColorPalettePreviewThumbnail(palette: palette)
                            }

                        case .seatingChart:
                            if case .seatingChart(let chart) = item {
                                SeatingChartPreviewThumbnail(chart: chart)
                            }
                        }
                    })
                .cornerRadius(12)
        }
    }

    // MARK: - Export Settings Section

    private var exportSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Settings")
                .font(.headline)

            // Format selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Format")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Format", selection: $selectedFormat) {
                    ForEach([ExportFormat.pdf, .png, .jpeg], id: \.self) { format in
                        HStack {
                            Image(systemName: format.icon)
                            Text(format.displayName)
                        }
                        .tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Quality selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Quality")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Quality", selection: $selectedQuality) {
                    ForEach(ExportQuality.allCases, id: \.self) { quality in
                        Text(quality.title).tag(quality)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Format Options Section

    private var formatOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Options")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                switch exportType {
                case .moodBoard:
                    Toggle("Include metadata page", isOn: $includeMetadata)
                        .font(.subheadline)

                case .colorPalette:
                    Toggle("Include hex color codes", isOn: $includeHexCodes)
                        .font(.subheadline)

                case .seatingChart:
                    Toggle("Include guest list", isOn: $includeGuestList)
                        .font(.subheadline)
                }

                if selectedFormat == .pdf {
                    Toggle("Optimize for printing", isOn: .constant(true))
                        .font(.subheadline)
                        .disabled(true)
                }
            }

            // File size estimate
            estimatedFileSizeView
        }
    }

    // MARK: - Estimated File Size

    private var estimatedFileSizeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated File Size")
                .font(.subheadline)
                .fontWeight(.medium)

            let estimatedSize = calculateEstimatedFileSize()
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)

                Text(estimatedSize)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack {
            if let exportedFileURL {
                Button("Save to Downloads") {
                    let fileName = generateFileName()
                    exportService.saveFileWithDialog(at: exportedFileURL, suggestedFilename: fileName)
                }
                .buttonStyle(.bordered)

                Button("Share") {
                    // Get the main window's content view
                    if let window = NSApplication.shared.keyWindow,
                       let contentView = window.contentView {
                        exportService.shareFile(at: exportedFileURL, from: contentView)
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)

            Button(isExporting ? "Exporting..." : "Export") {
                performExport()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func performExport() {
        isExporting = true
        exportError = nil

        Task {
            do {
                let fileURL = try await performActualExport()
                await MainActor.run {
                    exportedFileURL = fileURL
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showingError = true
                    isExporting = false
                }
            }
        }
    }

    private func performActualExport() async throws -> URL {
        switch exportType {
        case .moodBoard:
            if case .moodBoard(let moodBoard) = item {
                return try await exportService.exportMoodBoard(
                    moodBoard,
                    format: selectedFormat,
                    quality: selectedQuality,
                    includeMetadata: includeMetadata)
            }

        case .colorPalette:
            if case .colorPalette(let palette) = item {
                return try await exportService.exportColorPalette(
                    palette,
                    format: selectedFormat,
                    quality: selectedQuality,
                    includeHexCodes: includeHexCodes)
            }

        case .seatingChart:
            if case .seatingChart(let chart) = item {
                return try await exportService.exportSeatingChart(
                    chart,
                    format: selectedFormat,
                    quality: selectedQuality,
                    includeGuestList: includeGuestList)
            }
        }

        throw ExportError.invalidData
    }

    private func calculateEstimatedFileSize() -> String {
        let baseSize: Double
        let qualityMultiplier = selectedQuality.scale

        switch exportType {
        case .moodBoard:
            baseSize = selectedFormat == .pdf ? 2.0 : 1.5
        case .colorPalette:
            baseSize = selectedFormat == .pdf ? 0.5 : 0.3
        case .seatingChart:
            baseSize = selectedFormat == .pdf ? 1.0 : 0.8
        }

        let estimatedMB = baseSize * qualityMultiplier * (includeMetadata ? 1.5 : 1.0)

        if estimatedMB < 1.0 {
            return String(format: "%.0f KB", estimatedMB * 1024)
        } else {
            return String(format: "%.1f MB", estimatedMB)
        }
    }

    private func generateFileName() -> String {
        let baseName = item.displayName.replacingOccurrences(of: " ", with: "_")
        let timestamp = DateFormatter.filename.string(from: Date())
        return "\(baseName)_\(timestamp).\(selectedFormat.fileExtension)"
    }
}

// MARK: - Export Types and Items

enum ExportType {
    case moodBoard, colorPalette, seatingChart

    var title: String {
        switch self {
        case .moodBoard: "Mood Board"
        case .colorPalette: "Color Palette"
        case .seatingChart: "Seating Chart"
        }
    }

    var icon: String {
        switch self {
        case .moodBoard: "photo.on.rectangle.angled"
        case .colorPalette: "paintpalette"
        case .seatingChart: "tablecells"
        }
    }

    var color: Color {
        switch self {
        case .moodBoard: .blue
        case .colorPalette: .purple
        case .seatingChart: .green
        }
    }
}

enum ExportableItem {
    case moodBoard(MoodBoard)
    case colorPalette(ColorPalette)
    case seatingChart(SeatingChart)

    var displayName: String {
        switch self {
        case .moodBoard(let moodBoard):
            moodBoard.boardName
        case .colorPalette(let palette):
            palette.name
        case .seatingChart(let chart):
            chart.chartName
        }
    }
}

// MARK: - Preview Thumbnails

struct MoodBoardPreviewThumbnail: View {
    let moodBoard: MoodBoard

    var body: some View {
        ZStack {
            moodBoard.backgroundColor

            ForEach(moodBoard.elements.prefix(3)) { element in
                if element.elementType == .image,
                   let imageUrl = element.elementData.imageUrl,
                   let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
                   let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .position(
                            x: element.position.x * 0.3,
                            y: element.position.y * 0.3)
                }
            }

            // Title overlay
            VStack {
                HStack {
                    Text(moodBoard.boardName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textPrimary)
                        .padding(Spacing.xs)
                        .background(SemanticColors.textPrimary.opacity(Opacity.medium))
                        .cornerRadius(4)

                    Spacer()
                }
                Spacer()
            }
            .padding(Spacing.sm)
        }
        .cornerRadius(8)
    }
}

struct ColorPalettePreviewThumbnail: View {
    let palette: ColorPalette

    var body: some View {
        VStack(spacing: 8) {
            Text(palette.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            HStack(spacing: 4) {
                ForEach(palette.colors.prefix(4), id: \.self) { hexColor in
                    Circle()
                        .fill(Color.fromHexString(hexColor) ?? .gray)
                        .frame(width: 20, height: 20)
                }
            }

            HStack(spacing: 0) {
                ForEach(palette.colors.prefix(4), id: \.self) { hexColor in
                    Rectangle().fill(Color.fromHexString(hexColor) ?? .gray)
                }
            }
            .frame(height: 20)
            .cornerRadius(4)
        }
        .padding()
    }
}

struct SeatingChartPreviewThumbnail: View {
    let chart: SeatingChart

    var body: some View {
        VStack(spacing: 8) {
            Text(chart.chartName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            ZStack {
                SemanticColors.textSecondary.opacity(Opacity.subtle)

                // Sample tables
                ForEach(0 ..< min(chart.tables.count, 6), id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 16, height: 16)
                        .position(
                            x: CGFloat(20 + (index % 3) * 25),
                            y: CGFloat(20 + (index / 3) * 25))
                }
            }
            .frame(height: 60)
            .cornerRadius(4)

            Text("\(chart.tables.count) tables • \(chart.guests.count) guests")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Extensions



extension DateFormatter {
    static let filename: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter
    }()
}

#Preview {
    let sampleMoodBoard = MoodBoard(
        tenantId: "sample",
        boardName: "Romantic Garden Wedding",
        boardDescription: "Soft and elegant mood board",
        styleCategory: .romantic,
        canvasSize: CGSize(width: 800, height: 600),
        backgroundColor: .white)

    return ExportInterfaceView(
        exportType: .moodBoard,
        item: .moodBoard(sampleMoodBoard))
}
