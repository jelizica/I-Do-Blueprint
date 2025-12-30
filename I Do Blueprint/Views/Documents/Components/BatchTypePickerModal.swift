//
//  BatchTypePickerModal.swift
//  I Do Blueprint
//
//  Extracted from DocumentsView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Modal for selecting a document type for batch operations
struct BatchTypePickerModal: View {
    let selectedCount: Int
    let onSelectType: (DocumentType) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Change Document Type")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(selectedCount) document\(selectedCount == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.xxl)
                
                Divider()
                
                // Type selection list
                VStack(spacing: 0) {
                    ForEach(DocumentType.allCases, id: \.self) { type in
                        Button(action: {
                            onSelectType(type)
                        }) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(colorForType(type).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: iconForType(type))
                                            .foregroundColor(colorForType(type))
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(descriptionForType(type))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.xxl)
                
                Spacer()
            }
            .frame(width: 500, height: 600)
            .navigationTitle("Change Type")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func colorForType(_ type: DocumentType) -> Color {
        switch type {
        case .contract: .blue
        case .invoice: .green
        case .receipt: .orange
        case .photo: .purple
        case .other: .gray
        }
    }
    
    private func iconForType(_ type: DocumentType) -> String {
        switch type {
        case .contract: "doc.text"
        case .invoice: "doc.plaintext"
        case .receipt: "receipt"
        case .photo: "photo"
        case .other: "doc"
        }
    }
    
    private func descriptionForType(_ type: DocumentType) -> String {
        switch type {
        case .contract: "Legal agreements and contracts"
        case .invoice: "Bills and invoices"
        case .receipt: "Payment receipts"
        case .photo: "Photos and images"
        case .other: "Miscellaneous documents"
        }
    }
}
