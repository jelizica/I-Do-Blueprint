//
//  DocumentsLoadingView.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Loading skeleton view for documents
struct DocumentsLoadingView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: Spacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    DocumentCardSkeleton()
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
