//
//  VendorDetailDocumentsTabV2.swift
//  I Do Blueprint
//
//  Enhanced documents tab with drag & drop upload area and document thumbnails
//

import SwiftUI
import UniformTypeIdentifiers

struct VendorDetailDocumentsTabV2: View {
    let vendor: Vendor
    let documents: [Document]
    let isLoading: Bool

    @State private var isDragging = false
    @State private var showingFilePicker = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if isLoading {
                loadingView
            } else {
                // Drag & Drop Upload Area
                uploadArea

                // Documents Grid
                if !documents.isEmpty {
                    documentsGrid
                } else {
                    emptyDocumentsView
                }
            }
        }
    }

    // MARK: - Components

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading documents...")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var uploadArea: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .foregroundColor(isDragging ? SemanticColors.primaryAction : SemanticColors.borderLight)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(isDragging ? SemanticColors.primaryAction.opacity(Opacity.verySubtle) : SemanticColors.backgroundSecondary)
                    )
                    .frame(height: 140)

                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(SemanticColors.primaryAction.opacity(Opacity.subtle))
                            .frame(width: 56, height: 56)

                        Image(systemName: isDragging ? "arrow.down.doc.fill" : "icloud.and.arrow.up.fill")
                            .font(.system(size: 24))
                            .foregroundColor(SemanticColors.primaryAction)
                    }

                    VStack(spacing: Spacing.xs) {
                        Text(isDragging ? "Drop files here" : "Drag & drop files here")
                            .font(Typography.bodyRegular)
                            .fontWeight(.medium)
                            .foregroundColor(SemanticColors.textPrimary)

                        Text("or")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)

                        Button(action: { showingFilePicker = true }) {
                            Text("Browse Files")
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(SemanticColors.primaryAction)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
                                .cornerRadius(CornerRadius.md)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers: providers)
            }

            // Supported formats
            HStack(spacing: Spacing.sm) {
                ForEach(supportedFormats, id: \.self) { format in
                    DocumentFormatBadge(format: format)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .image, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }

    private var documentsGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeaderV2(
                    title: "Documents (\(documents.count))",
                    icon: "doc.fill",
                    color: SemanticColors.primaryAction
                )

                Spacer()
            }

            LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                ForEach(documents) { document in
                    DocumentThumbnailCardV2(document: document)
                }
            }
        }
    }

    private var emptyDocumentsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.textSecondary.opacity(Opacity.medium))

            VStack(spacing: Spacing.xs) {
                Text("No Documents")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Documents linked to this vendor will appear here.\nUpload files using the area above.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Computed Properties

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.md),
            GridItem(.flexible(), spacing: Spacing.md),
            GridItem(.flexible(), spacing: Spacing.md)
        ]
    }

    private var supportedFormats: [String] {
        ["PDF", "PNG", "JPG", "DOC", "TXT"]
    }

    // MARK: - Actions

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                // TODO: Handle file upload to Supabase storage
                print("Dropped file: \(url)")
            }
        }
        return true
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                // TODO: Handle file upload to Supabase storage
                print("Selected file: \(url)")
            }
        case .failure(let error):
            print("File import error: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct DocumentFormatBadge: View {
    let format: String

    var body: some View {
        Text(format)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(SemanticColors.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.sm)
    }
}

struct DocumentThumbnailCardV2: View {
    let document: Document

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail area
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(thumbnailBackgroundColor)
                    .frame(height: 100)

                // File type icon or preview
                VStack(spacing: Spacing.sm) {
                    Image(systemName: iconForDocumentType)
                        .font(.system(size: 32))
                        .foregroundColor(iconColor)

                    Text(fileExtension.uppercased())
                        .font(Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(iconColor)
                }
            }

            // Document info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(document.originalFilename)
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(2)

                Text(document.uploadedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(isHovering ? SemanticColors.primaryAction.opacity(Opacity.semiLight) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var fileExtension: String {
        let components = document.originalFilename.split(separator: ".")
        return components.last.map(String.init) ?? "FILE"
    }

    private var iconForDocumentType: String {
        switch document.documentType {
        case .contract: return "doc.text.fill"
        case .invoice: return "doc.text.fill"
        case .receipt: return "receipt.fill"
        case .photo: return "photo.fill"
        case .other: return "doc.fill"
        }
    }

    private var iconColor: Color {
        switch fileExtension.lowercased() {
        case "pdf": return Color.fromHex("E53935")
        case "doc", "docx": return Color.fromHex("2196F3")
        case "xls", "xlsx": return Color.fromHex("4CAF50")
        case "png", "jpg", "jpeg", "gif": return Color.fromHex("FF9800")
        case "txt": return SemanticColors.textSecondary
        default: return SemanticColors.primaryAction
        }
    }

    private var thumbnailBackgroundColor: Color {
        iconColor.opacity(Opacity.verySubtle)
    }
}
