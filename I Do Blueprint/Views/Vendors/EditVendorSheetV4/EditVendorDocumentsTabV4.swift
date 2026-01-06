//
//  EditVendorDocumentsTabV4.swift
//  I Do Blueprint
//
//  Documents tab for Edit Vendor Modal V4 (View Only)
//  Displays: Document grid with file type icons, view/download actions
//

import SwiftUI

struct EditVendorDocumentsTabV4: View {
    // MARK: - Properties
    
    let documents: [Document]
    let isLoading: Bool
    
    // MARK: - State
    
    @State private var hoveredDocumentId: UUID?
    
    // MARK: - Grid Layout
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: Spacing.lg)
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            // View Only Banner
            viewOnlyBanner
            
            if isLoading {
                loadingView
            } else if documents.isEmpty {
                emptyStateView
            } else {
                // Documents Grid
                LazyVGrid(columns: columns, spacing: Spacing.lg) {
                    ForEach(documents) { document in
                        documentCard(document)
                    }
                }
            }
        }
    }
    
    // MARK: - View Only Banner
    
    private var viewOnlyBanner: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.info)
                .frame(width: 32, height: 32)
                .background(SemanticColors.info.opacity(Opacity.verySubtle))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("View-Only Access")
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("Documents for this vendor are managed in the main Contracts Portal. You can view and download files here, but edits must be made by an administrator.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    SemanticColors.backgroundSecondary,
                    SemanticColors.backgroundPrimary
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .macOSShadow(.subtle)
    }
    
    // MARK: - Document Card
    
    private func documentCard(_ document: Document) -> some View {
        let isHovered = hoveredDocumentId == document.id
        
        return VStack(alignment: .leading, spacing: 0) {
            // Preview Area
            ZStack {
                // Background color based on file type
                documentBackgroundColor(for: document)
                
                // File type icon or preview
                documentPreview(for: document)
                
                // File type badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(documentFileExtension(document))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SemanticColors.textSecondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(
                                SemanticColors.backgroundPrimary.opacity(0.9)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                            .textCase(.uppercase)
                    }
                    .padding(Spacing.sm)
                }
                
                // Hover overlay with actions
                if isHovered {
                    Color.black.opacity(0.6)
                    
                    HStack(spacing: Spacing.md) {
                        actionButton(icon: "eye", title: "View") {
                            viewDocument(document)
                        }
                        
                        actionButton(icon: "arrow.down.circle", title: "Download") {
                            downloadDocument(document)
                        }
                    }
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            
            // Document Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(document.displayName)
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack {
                    Text(documentCategory(document))
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    Spacer()
                    
                    Text(documentMetadata(document))
                        .font(.system(size: 11))
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }
            .padding(Spacing.md)
        }
        .background(SemanticColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .macOSShadow(isHovered ? .elevated : .subtle)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            hoveredDocumentId = hovering ? document.id : nil
        }
    }
    
    // MARK: - Document Preview
    
    @ViewBuilder
    private func documentPreview(for document: Document) -> some View {
        let fileType = documentFileType(document)
        
        switch fileType {
        case .pdf:
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(documentIconColor(for: document))
        case .image:
            // For images, show a placeholder icon
            // In a real implementation, this would load from storage
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(documentIconColor(for: document))
        case .spreadsheet:
            Image(systemName: "tablecells")
                .font(.system(size: 48))
                .foregroundColor(documentIconColor(for: document))
        case .document:
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(documentIconColor(for: document))
        case .other:
            Image(systemName: "doc")
                .font(.system(size: 48))
                .foregroundColor(documentIconColor(for: document))
        }
    }
    
    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(SemanticColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(SemanticColors.backgroundPrimary)
                .clipShape(Circle())
                .macOSShadow(.elevated)
        }
        .buttonStyle(.plain)
        .help(title)
    }
    
    // MARK: - Document Helpers
    
    private enum DocumentFileType {
        case pdf
        case image
        case spreadsheet
        case document
        case other
    }
    
    private func documentFileType(_ document: Document) -> DocumentFileType {
        let ext = documentFileExtension(document).lowercased()
        
        switch ext {
        case "pdf":
            return .pdf
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return .image
        case "xlsx", "xls", "csv":
            return .spreadsheet
        case "doc", "docx", "txt", "rtf":
            return .document
        default:
            return .other
        }
    }
    
    private func documentFileExtension(_ document: Document) -> String {
        return document.fileExtension.isEmpty ? "FILE" : document.fileExtension
    }
    
    private func documentBackgroundColor(for document: Document) -> Color {
        let fileType = documentFileType(document)
        
        switch fileType {
        case .pdf:
            return Color(red: 0.98, green: 0.92, blue: 0.94) // Rose tint
        case .image:
            return SemanticColors.backgroundSecondary
        case .spreadsheet:
            return Color(red: 0.92, green: 0.98, blue: 0.94) // Mint tint
        case .document:
            return Color(red: 0.92, green: 0.95, blue: 0.98) // Blue tint
        case .other:
            return SemanticColors.backgroundSecondary
        }
    }
    
    private func documentIconColor(for document: Document) -> Color {
        let fileType = documentFileType(document)
        
        switch fileType {
        case .pdf:
            return SemanticColors.primaryAction.opacity(0.5)
        case .image:
            return SemanticColors.textTertiary
        case .spreadsheet:
            return AppColors.Vendor.booked.opacity(0.5)
        case .document:
            return SemanticColors.info.opacity(0.5)
        case .other:
            return SemanticColors.textTertiary
        }
    }
    
    private func documentCategory(_ document: Document) -> String {
        // Map document type to category
        return document.documentType.displayName
    }
    
    private func documentMetadata(_ document: Document) -> String {
        var parts: [String] = []
        
        // File size
        parts.append(document.formattedSize)
        
        // Date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        parts.append(formatter.string(from: document.uploadedAt))
        
        return parts.joined(separator: " • ")
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Actions
    
    private func viewDocument(_ document: Document) {
        // In a real implementation, this would open the document from storage
        // For now, we'll just log the action
        print("View document: \(document.originalFilename)")
    }
    
    private func downloadDocument(_ document: Document) {
        // In a real implementation, this would download the document from storage
        // For now, we'll just log the action
        print("Download document: \(document.originalFilename)")
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.textTertiary)
            
            VStack(spacing: Spacing.xs) {
                Text("No Documents")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("Documents for this vendor will appear here once uploaded.")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading documents...")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Spacing.huge)
    }
    
    // MARK: - Helper Views
    
    private var glassCardBackground: some View {
        SemanticColors.backgroundPrimary.opacity(0.4)
    }
}

// MARK: - Preview

#Preview("Documents Tab - Empty") {
    EditVendorDocumentsTabV4(
        documents: [],
        isLoading: false
    )
    .padding()
    .frame(width: 850, height: 400)
}

#Preview("Documents Tab - Loading") {
    EditVendorDocumentsTabV4(
        documents: [],
        isLoading: true
    )
    .padding()
    .frame(width: 850, height: 400)
}
