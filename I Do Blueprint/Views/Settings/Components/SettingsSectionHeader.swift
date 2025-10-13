//
//  SettingsSectionHeader.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct SettingsSectionHeader: View {
    let title: String
    let subtitle: String
    let sectionName: String
    let isSaving: Bool
    let hasUnsavedChanges: Bool
    let onSave: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onSave) {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isSaving ? "Saving..." : "Save \(title)")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasUnsavedChanges || isSaving)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    SettingsSectionHeader(
        title: "Global Settings",
        subtitle: "Core wedding information and preferences",
        sectionName: "global",
        isSaving: false,
        hasUnsavedChanges: true,
        onSave: {})
        .padding()
}
