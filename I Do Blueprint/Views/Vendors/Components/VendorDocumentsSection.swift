//
//  VendorDocumentsSection.swift
//  I Do Blueprint
//
//  Displays documents linked to a vendor
//

import SwiftUI
import Dependencies

struct VendorDocumentsSection: View {
    let documents: [Document]
    @State private var selectedDocument: Document?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Documents",
                icon: "doc.text.fill",
                color: AppColors.primary
            )

            VStack(spacing: Spacing.sm) {
                ForEach(documents) { document in
                    DocumentRowView(document: document)
                        .onTapGesture {
                            selectedDocument = document
                        }
                }
            }
        }
        .sheet(item: $selectedDocument) { document in
            DocumentDetailSheet(document: document)
        }
    }
}

// MARK: - Document Row View

struct DocumentRowView: View {
    let document: Document

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
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var documentTypeIcon: String {
        switch document.documentType {
        case .contract:
            return "doc.text.fill"
        case .invoice:
            return "doc.plaintext.fill"
        case .receipt:
            return "receipt.fill"
        case .photo:
            return "photo.fill"
        case .other:
            return "doc.fill"
        }
    }

    private var documentTypeColor: Color {
        switch document.documentType {
        case .contract:
            return .blue
        case .invoice:
            return .green
        case .receipt:
            return .orange
        case .photo:
            return .purple
        case .other:
            return .gray
        }
    }
}

// MARK: - Document Detail Sheet

struct DocumentDetailSheet: View {
    let document: Document
    @Environment(\.dismiss) var dismiss
    @State private var isDownloading = false
    @Dependency(\.documentRepository) var documentRepository

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Document Details")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
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
                        DocumentDetailRow(label: "File Size", value: document.formattedSize)
                        DocumentDetailRow(label: "File Type", value: document.fileExtension)
                        DocumentDetailRow(label: "Uploaded", value: document.uploadedAt.formatted(date: .long, time: .shortened))
                        DocumentDetailRow(label: "Uploaded By", value: document.uploadedBy)

                        if !document.tags.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Tags")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                TagFlowLayout(spacing: Spacing.xs) {
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
                        Button(action: { downloadDocument() }) {
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
                            .foregroundColor(AppColors.textPrimary)
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

    private var documentTypeIcon: String {
        switch document.documentType {
        case .contract:
            return "doc.text.fill"
        case .invoice:
            return "doc.plaintext.fill"
        case .receipt:
            return "receipt.fill"
        case .photo:
            return "photo.fill"
        case .other:
            return "doc.fill"
        }
    }

    private var documentTypeColor: Color {
        switch document.documentType {
        case .contract:
            return .blue
        case .invoice:
            return .green
        case .receipt:
            return .orange
        case .photo:
            return .purple
        case .other:
            return .gray
        }
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
                                AppLogger.ui.error("Error saving file", error: error)
                            }
                        }
                        isDownloading = false
                    }
                }
            } catch {
                AppLogger.ui.error("Error downloading document", error: error)
                isDownloading = false
            }
        }
    }
}

// MARK: - Document Detail Row

struct DocumentDetailRow: View {
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

// MARK: - Tag Flow Layout

struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    VendorDocumentsSection(documents: [
        Document(
            id: UUID(),
            coupleId: UUID(),
            originalFilename: "DJ Contract.pdf",
            storagePath: "contracts/dj-contract.pdf",
            fileSize: 1024000,
            mimeType: "application/pdf",
            documentType: .contract,
            bucketName: "invoices-and-contracts",
            vendorId: 96,
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
            originalFilename: "DJ Invoice.pdf",
            storagePath: "invoices/dj-invoice.pdf",
            fileSize: 512000,
            mimeType: "application/pdf",
            documentType: .invoice,
            bucketName: "invoices-and-contracts",
            vendorId: 96,
            expenseId: nil,
            paymentId: nil,
            tags: ["invoice", "paid"],
            uploadedBy: "user@example.com",
            uploadedAt: Date(),
            updatedAt: Date(),
            autoTagStatus: .manual,
            autoTagSource: .manual,
            autoTaggedAt: nil,
            autoTagError: nil
        )
    ])
}
