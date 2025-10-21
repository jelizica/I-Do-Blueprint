//
//  ExportSupportingViews.swift
//  I Do Blueprint
//
//  Supporting views and extensions for export views
//

import SwiftUI

// MARK: - Metadata Row

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
