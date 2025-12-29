//
//  V3VendorDocumentsContent.swift
//  I Do Blueprint
//
//  Documents tab content for V3 vendor detail view
//

import SwiftUI
import Dependencies

struct V3VendorDocumentsContent: View {
    let documents: [Document]
    let isLoading: Bool

    @State private var selectedDocument: Document?

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            if isLoading {
                loadingState
            } else if !documents.isEmpty {
                documentsContent
            } else {
                emptyState
            }
        }
        .sheet(item: $selectedDocument) { document in
            V3DocumentDetailSheet(document: document)
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading documents...")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("No Documents")
                .font(Typography.heading)
                .foregroundColor(AppColors.textSecondary)

            Text("Documents linked to this vendor will appear here. Upload documents from the Documents page and link them to this vendor.")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxxl)
    }

    // MARK: - Documents Content

    private var documentsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Documents",
                icon: "doc.text.fill",
                color: AppColors.primary
            )

            VStack(spacing: Spacing.sm) {
                ForEach(documents) { document in
                    V3DocumentRow(document: document)
                        .onTapGesture {
                            selectedDocument = document
                        }
                }
            }
        }
    }
}

// MARK: - Document Row

private struct V3DocumentRow: View {
    let document: Document

    @State private var isHovering = false

    private var documentTypeIcon: String {
        switch document.documentType {
        case .contract: return "doc.text.fill"
        case .invoice: return "doc.plaintext.fill"
        case .receipt: return "receipt.fill"
        case .photo: return "photo.fill"
        case .other: return "doc.fill"
        }
    }

    private var documentTypeColor: Color {
        switch document.documentType {
        case .contract: return .blue
        case .invoice: return .green
        case .receipt: return .orange
        case .photo: return .purple
        case .other: return .gray
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Document Icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(documentTypeColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: documentTypeIcon)
                    .font(.system(size: 20))
                    .foregroundColor(documentTypeColor)
            }

            // Document Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(document.originalFilename)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    // Document Type Badge
                    Text(document.documentType.displayName)
                        .font(Typography.caption)
                        .foregroundColor(documentTypeColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(documentTypeColor.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)

                    // File Size
                    Text(document.formattedSize)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    // Upload Date
                    Text("•")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(document.uploadedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovering ? AppColors.primary.opacity(0.3) : AppColors.border, lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.originalFilename), \(document.documentType.displayName)")
        .accessibilityHint("Double tap to view document details")
    }
}

// MARK: - Document Detail Sheet

private struct V3DocumentDetailSheet: View {
    let document: Document
    @Environment(\.dismiss) var dismiss
    @State private var isDownloading = false
    @Dependency(\.documentRepository) var documentRepository

    private let logger = AppLogger.ui

    private var documentTypeIcon: String {
        switch document.documentType {
        case .contract: return "doc.text.fill"
        case .invoice: return "doc.plaintext.fill"
        case .receipt: return "receipt.fill"
        case .photo: return "photo.fill"
        case .other: return "doc.fill"
        }
    }

    private var documentTypeColor: Color {
        switch document.documentType {
        case .contract: return .blue
        case .invoice: return .green
        case .receipt: return .orange
        case .photo: return .purple
        case .other: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Document Details")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.xl)
            .background(AppColors.cardBackground)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Document Icon and Name
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(documentTypeColor.opacity(0.1))
                                .frame(width: 64, height: 64)

                            Image(systemName: documentTypeIcon)
                                .font(.system(size: 32))
                                .foregroundColor(documentTypeColor)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(document.originalFilename)
                                .font(Typography.heading)
                                .foregroundColor(AppColors.textPrimary)

                            Text(document.documentType.displayName)
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    Divider()

                    // Document Details
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        V3DocumentDetailRow(label: "File Size", value: document.formattedSize)
                        V3DocumentDetailRow(label: "File Type", value: document.fileExtension)
                        V3DocumentDetailRow(label: "Uploaded", value: document.uploadedAt.formatted(date: .long, time: .shortened))
                        V3DocumentDetailRow(label: "Uploaded By", value: document.uploadedBy)

                        if !document.tags.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Tags")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                FlowLayout(spacing: Spacing.xs) {
                                    ForEach(document.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(Typography.caption)
                                            .foregroundColor(AppColors.primary)
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, Spacing.xs)
                                            .background(AppColors.primary.opacity(0.1))
                                            .cornerRadius(CornerRadius.sm)
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Actions
                    VStack(spacing: Spacing.sm) {
                        Button {
                            downloadDocument()
                        } label: {
                            HStack {
                                if isDownloading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                }
                                Text(isDownloading ? "Downloading..." : "Download Document")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDownloading)
                    }
                }
                .padding(Spacing.xl)
            }
        }
        .frame(width: 500, height: 600)
        .background(AppColors.background)
    }

    private func downloadDocument() {
        isDownloading = true

        Task {
            do {
                // Get document data
                let data = try await documentRepository.downloadDocument(document: document)

                // Show save panel
                await MainActor.run {
                    let panel = NSSavePanel()
                    panel.nameFieldStringValue = document.originalFilename
                    panel.canCreateDirectories = true

                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            do {
                                try data.write(to: url)
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            } catch {
                                logger.error("Error saving file", error: error)
                            }
                        }
                        isDownloading = false
                    }
                }
            } catch {
                logger.error("Error downloading document", error: error)
                await MainActor.run {
                    isDownloading = false
                }
            }
        }
    }
}

// MARK: - Document Detail Row

private struct V3DocumentDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// Note: FlowLayout is defined in MoodBoardDetailsView.swift and reused here

// MARK: - Preview

#Preview("Documents Content - With Data") {
    V3VendorDocumentsContent(
        documents: [
            Document(
                id: UUID(),
                coupleId: UUID(),
                originalFilename: "Vendor Contract.pdf",
                storagePath: "contracts/vendor-contract.pdf",
                fileSize: 1024000,
                mimeType: "application/pdf",
                documentType: .contract,
                bucketName: "invoices-and-contracts",
                vendorId: 1,
                expenseId: nil,
                paymentId: nil,
                tags: ["contract", "signed"],
                uploadedBy: "user@example.com",
                uploadedAt: Date(),
                updatedAt: Date(),
                autoTagStatus: .manual,
                autoTagSource: .manual,
                autoTaggedAt: nil,
                autoTagError: nil
            ),
            Document(
                id: UUID(),
                coupleId: UUID(),
                originalFilename: "Invoice.pdf",
                storagePath: "invoices/invoice.pdf",
                fileSize: 512000,
                mimeType: "application/pdf",
                documentType: .invoice,
                bucketName: "invoices-and-contracts",
                vendorId: 1,
                expenseId: nil,
                paymentId: nil,
                tags: [],
                uploadedBy: "user@example.com",
                uploadedAt: Date(),
                updatedAt: Date(),
                autoTagStatus: .manual,
                autoTagSource: .manual,
                autoTaggedAt: nil,
                autoTagError: nil
            )
        ],
        isLoading: false
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Documents Content - Empty") {
    V3VendorDocumentsContent(
        documents: [],
        isLoading: false
    )
    .padding()
    .background(AppColors.background)
}
