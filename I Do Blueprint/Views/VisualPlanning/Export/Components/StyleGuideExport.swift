//
//  StyleGuideExport.swift
//  I Do Blueprint
//
//  Style guide export view components
//

import SwiftUI

// MARK: - Export Style Guide View

struct ExportStyleGuideView: View {
    let preferences: StylePreferences
    let branding: BrandingSettings
    let template: ExportTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Header
            Text("Wedding Style Guide")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(branding.primaryColor)

            // Primary style
            if let primaryStyle = preferences.primaryStyle {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Style")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(branding.primaryColor)

                    HStack(spacing: 16) {
                        Image(systemName: primaryStyle.icon)
                            .font(.largeTitle)
                            .foregroundColor(branding.primaryColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(primaryStyle.displayName)
                                .font(.title3)
                                .fontWeight(.medium)

                            Text(primaryStyle.displayName)
                                .font(.subheadline)
                                .foregroundColor(branding.textColor.opacity(0.7))
                        }
                    }
                }
            }

            // Color preferences
            if !preferences.primaryColors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Palette")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(branding.primaryColor)

                    HStack(spacing: 12) {
                        ForEach(Array(preferences.primaryColors.enumerated()), id: \.offset) { _, color in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 50, height: 50)

                                Text(color.toHex())
                                    .font(.caption2)
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                    }
                }
            }

            // Guidelines
            if let guidelines = preferences.guidelines,
               !guidelines.doElements.isEmpty || !guidelines.avoidElements.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Style Guidelines")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(branding.primaryColor)

                    if !guidelines.doElements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Do Include:")
                                .font(.headline)
                                .foregroundColor(.green)

                            ForEach(guidelines.doElements, id: \.self) { element in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(element)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }

                    if !guidelines.avoidElements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avoid:")
                                .font(.headline)
                                .foregroundColor(.red)

                            ForEach(guidelines.avoidElements, id: \.self) { element in
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text(element)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.huge)
        .frame(width: 595, height: 842)
        .background(branding.backgroundColor)
    }
}
