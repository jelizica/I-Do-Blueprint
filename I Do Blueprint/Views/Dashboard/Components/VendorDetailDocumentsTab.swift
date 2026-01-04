//
//  VendorDetailDocumentsTab.swift
//  I Do Blueprint
//
//  Documents tab content for vendor detail modal
//

import SwiftUI

struct VendorDetailDocumentsTab: View {
    let documents: [Document]
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            if isLoading {
                loadingView
            } else if !documents.isEmpty {
                documentsList
            } else {
                VendorEmptyStateView(
                    icon: "doc.text",
                    title: "No Documents",
                    message: "Documents linked to this vendor will appear here. Upload documents from the Documents page and link them to this vendor."
                )
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
    
    private var documentsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Documents (\(documents.count))",
                icon: "doc.text.fill",
                color: SemanticColors.primaryAction
            )
            
            VStack(spacing: Spacing.sm) {
                ForEach(documents) { document in
                    DocumentRow(document: document)
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Supporting Views

struct DocumentRow: View {
    let document: Document
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "doc.fill")
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.primaryAction)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(document.originalFilename)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(document.documentType.displayName)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            Text(document.uploadedAt.formatted(date: .abbreviated, time: .omitted))
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .padding(Spacing.sm)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.sm)
    }
}
