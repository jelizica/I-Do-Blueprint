//
//  DocumentCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import QuickLook
import SwiftUI

struct DocumentCard: View {
    let document: Document
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false
    @State private var thumbnailImage: NSImage?

    private let logger = AppLogger.ui

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail or icon section
            thumbnailSection
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(alignment: .topTrailing) {
                    if isSelectionMode {
                        selectionCheckbox
                            .padding(Spacing.sm)
                    }
                }

            // Content section
            VStack(alignment: .leading, spacing: 12) {
                // Document type badge
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: document.documentType.iconName)
                            .font(.caption2)
                        Text(document.documentType.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(colorForType(document.documentType).opacity(0.15)))
                    .foregroundColor(colorForType(document.documentType))

                    Spacer()

                    // File extension
                    Text(document.fileExtension)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                // File name
                Text(document.originalFilename)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                // Tags
                if !document.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(document.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1)))
                                    .foregroundColor(.blue)
                            }
                            if document.tags.count > 3 {
                                Text("+\(document.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Footer with metadata
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(formatDate(document.uploadedAt))
                        .font(.caption2)

                    Spacer()

                    Text(document.formattedSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.secondary)

                // Action buttons (shows on hover)
                if isHovered, !isSelectionMode {
                    actionButtons
                }
            }
            .padding(Spacing.md)
        }
        .frame(minHeight: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: isHovered || isSelected ? Color.blue.opacity(0.2) : SemanticColors.textPrimary.opacity(Opacity.verySubtle),
                    radius: isHovered || isSelected ? 8 : 4,
                    x: 0,
                    y: isHovered || isSelected ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
        .scaleEffect(isHovered && !isSelectionMode ? 1.02 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    // MARK: - Thumbnail Section

    private var thumbnailSection: some View {
        Group {
            if let thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                // File type icon
                VStack(spacing: 8) {
                    Image(systemName: iconForDocument(document))
                        .font(.system(size: 48))
                        .foregroundColor(colorForType(document.documentType))

                    Text(document.fileExtension)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Selection Checkbox

    private var selectionCheckbox: some View {
        Button(action: onToggleSelection) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .secondary)
                .background(
                    Circle()
                        .fill(Color(NSColor.windowBackgroundColor))
                        .frame(width: 28, height: 28))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                // Open document
                if let url = try? getPublicURL() {
                    // ✅ Validate URL before opening
                    do {
                        try URLValidator.validate(url)
                        NSWorkspace.shared.open(url)
                    } catch {
                        logger.error("Rejected unsafe document URL", error: error)
                    }
                }
            }) {
                Label("View", systemImage: "eye")
                    .font(.caption)
            }
            .buttonStyle(.borderless)

            Button(action: {
                // Download document
                Task {
                    await downloadDocument()
                }
            }) {
                Label("Download", systemImage: "arrow.down.circle")
                    .font(.caption)
            }
            .buttonStyle(.borderless)

            Spacer()

            Button(action: { showingDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete this document? This action cannot be undone.")
            }
        }
    }

    // MARK: - Helper Methods

    private func loadThumbnail() {
        guard document.isImage else { return }

        Task {
            do {
                let url = try getPublicURL()
                if let imageData = try? Data(contentsOf: url),
                   let image = NSImage(data: imageData) {
                    await MainActor.run {
                        thumbnailImage = image
                    }
                }
            } catch {
                logger.error("Failed to load thumbnail", error: error)
            }
        }
    }

    private func getPublicURL() throws -> URL {
        let api = DocumentsAPI()
        return try api.getPublicURL(bucketName: document.bucketName, path: document.storagePath)
    }

    private func downloadDocument() async {
        do {
            let api = DocumentsAPI()
            let data = try await api.downloadFile(bucketName: document.bucketName, path: document.storagePath)

            // Show save panel
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = document.originalFilename
            savePanel.canCreateDirectories = true

            await MainActor.run {
                if savePanel.runModal() == .OK {
                    if let url = savePanel.url {
                        try? data.write(to: url)
                    }
                }
            }
        } catch {
            logger.error("Failed to download document", error: error)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func iconForDocument(_ document: Document) -> String {
        if document.isPDF {
            "doc.richtext.fill"
        } else if document.isImage {
            "photo.fill"
        } else {
            "doc.fill"
        }
    }

    private func colorForType(_ type: DocumentType) -> Color {
        switch type.color {
        case "blue": .blue
        case "green": .green
        case "orange": .orange
        case "purple": .purple
        case "gray": .gray
        default: .primary
        }
    }
}

// MARK: - Document List Row

struct DocumentListRow: View {
    let document: Document
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 16) {
            // Selection checkbox
            if isSelectionMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }

            // File icon
            Image(systemName: iconForDocument(document))
                .font(.title2)
                .foregroundColor(colorForType(document.documentType))
                .frame(width: 40)

            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.originalFilename)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    // Type
                    Text(document.documentType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Size
                    Text(document.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Date
                    Text(formatDate(document.uploadedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Tags
                    if !document.tags.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                            Text("\(document.tags.count)")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            // Actions (shows on hover)
            if isHovered, !isSelectionMode {
                HStack(spacing: 8) {
                    Button(action: {
                        if let url = try? getPublicURL() {
                            // ✅ Validate URL before opening
                            do {
                                try URLValidator.validate(url)
                                NSWorkspace.shared.open(url)
                            } catch {
                                AppLogger.ui.warning("Rejected unsafe URL: \(url.absoluteString)")
                            }
                        }
                    }) {
                        Image(systemName: "eye")
                    }
                    .buttonStyle(.borderless)

                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(
            Rectangle()
                .fill(isSelected ? Color.blue
                    .opacity(0.1) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)))
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this document? This action cannot be undone.")
        }
    }

    private func getPublicURL() throws -> URL {
        let api = DocumentsAPI()
        return try api.getPublicURL(bucketName: document.bucketName, path: document.storagePath)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func iconForDocument(_ document: Document) -> String {
        if document.isPDF {
            "doc.richtext.fill"
        } else if document.isImage {
            "photo.fill"
        } else {
            "doc.fill"
        }
    }

    private func colorForType(_ type: DocumentType) -> Color {
        switch type.color {
        case "blue": .blue
        case "green": .green
        case "orange": .orange
        case "purple": .purple
        case "gray": .gray
        default: .primary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DocumentCard(
            document: Document(
                id: UUID(),
                coupleId: UUID(),
                originalFilename: "Venue_Contract_Final.pdf",
                storagePath: "contracts/venue.pdf",
                fileSize: 2_500_000,
                mimeType: "application/pdf",
                documentType: .contract,
                bucketName: "invoices-and-contracts",
                vendorId: 1,
                expenseId: nil,
                paymentId: nil,
                tags: ["venue", "signed", "important"],
                uploadedBy: "user@example.com",
                uploadedAt: Date().addingTimeInterval(-86400 * 5),
                updatedAt: Date().addingTimeInterval(-86400 * 2),
                autoTagStatus: .manual,
                autoTagSource: .manual,
                autoTaggedAt: nil,
                autoTagError: nil),
            isSelected: false,
            isSelectionMode: false,
            onTap: {},
            onToggleSelection: {},
            onDelete: {})
            .frame(width: 280)
    }
    .padding()
}
