//
//  ColorPickerSheet.swift
//  I Do Blueprint
//
//  Color picker interface for selecting primary wedding colors
//

import SwiftUI

// MARK: - Primary Color Picker Sheet

struct PrimaryColorPickerSheet: View {
    @Binding var colors: [Color]
    let maxColors: Int
    let onDismiss: () -> Void

    @State private var selectedColorIndex: Int?
    @State private var tempColor: Color = .blue
    @State private var showingAddColor = false
    @State private var showingEditColor = false

    private let logger = AppLogger.ui

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Color list
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Current colors
                    if !colors.isEmpty {
                        currentColorsSection
                    }

                    // Add color button
                    if colors.count < maxColors {
                        addColorButton
                    }

                    // Color harmony suggestions
                    if !colors.isEmpty {
                        harmonySuggestionsSection
                    }

                    // Guidance text
                    if colors.isEmpty {
                        emptyStateSection
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            footerSection
        }
        .frame(width: 500, height: 600)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Text("Choose Primary Colors")
                .font(Typography.heading)

            Spacer()

            Text("\(colors.count)/\(maxColors)")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
    }

    // MARK: - Current Colors Section

    private var currentColorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Colors")
                .font(Typography.subheading)

            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                ColorRow(
                    color: color,
                    index: index,
                    onEdit: { editColor(at: index) },
                    onDelete: { deleteColor(at: index) })
            }
        }
    }

    // MARK: - Add Color Button

    private var addColorButton: some View {
        Button(action: { showingAddColor = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Color")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingAddColor) {
            ColorPickerModal(
                title: "Add Color",
                selectedColor: $tempColor,
                onSave: {
                    colors.append(tempColor)
                    showingAddColor = false
                    logger.info("Added color: \(tempColor.hexString)")
                },
                onCancel: {
                    showingAddColor = false
                })
        }
    }

    // MARK: - Harmony Suggestions Section

    private var harmonySuggestionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Suggested Harmonies")
                .font(Typography.subheading)

            Text("Based on your selected colors")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)

            // Show complementary, analogous, triadic suggestions
            HStack(spacing: Spacing.sm) {
                ForEach(suggestedColors, id: \.self) { color in
                    Button(action: {
                        if colors.count < maxColors {
                            colors.append(color)
                            logger.info("Added suggested color: \(color.hexString)")
                        }
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(colors.count >= maxColors)
                    .accessibilityLabel("Add suggested color \(color.hexString)")
                }
            }
        }
    }

    // MARK: - Empty State Section

    private var emptyStateSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "paintpalette")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("No Colors Selected")
                .font(Typography.subheading)

            Text("Choose 2-4 primary colors that will define your wedding palette")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func editColor(at index: Int) {
        selectedColorIndex = index
        tempColor = colors[index]
        showingEditColor = true
    }

    private func deleteColor(at index: Int) {
        let removedColor = colors[index]
        colors.remove(at: index)
        logger.info("Removed color: \(removedColor.hexString)")
    }

    private var suggestedColors: [Color] {
        // Generate complementary, analogous, or triadic colors
        // based on existing colors
        guard let firstColor = colors.first else { return [] }
        return generateHarmonyColors(from: firstColor)
    }

    private func generateHarmonyColors(from color: Color) -> [Color] {
        // Convert color to HSB
        let nsColor = NSColor(color)
        guard let rgb = nsColor.usingColorSpace(.deviceRGB) else { return [] }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        NSColor(red: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent, alpha: 1.0)
            .getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        var suggestions: [Color] = []

        // Complementary (opposite on color wheel)
        let complementaryHue = (hue + 0.5).truncatingRemainder(dividingBy: 1.0)
        suggestions.append(Color(hue: complementaryHue, saturation: saturation, brightness: brightness))

        // Analogous (adjacent colors)
        let analogous1Hue = (hue + 0.083).truncatingRemainder(dividingBy: 1.0) // +30 degrees
        let analogous2Hue = (hue - 0.083 + 1.0).truncatingRemainder(dividingBy: 1.0) // -30 degrees
        suggestions.append(Color(hue: analogous1Hue, saturation: saturation, brightness: brightness))
        suggestions.append(Color(hue: analogous2Hue, saturation: saturation, brightness: brightness))

        // Triadic (120 degrees apart)
        let triadic1Hue = (hue + 0.333).truncatingRemainder(dividingBy: 1.0)
        let triadic2Hue = (hue + 0.666).truncatingRemainder(dividingBy: 1.0)
        suggestions.append(Color(hue: triadic1Hue, saturation: saturation, brightness: brightness))
        suggestions.append(Color(hue: triadic2Hue, saturation: saturation, brightness: brightness))

        // Filter out colors that are too similar to existing colors
        return suggestions.filter { suggestedColor in
            !colors.contains { existingColor in
                colorsAreSimilar(suggestedColor, existingColor)
            }
        }.prefix(5).map { $0 }
    }

    private func colorsAreSimilar(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.hexString
        let hex2 = color2.hexString
        return hex1 == hex2
    }
}

// MARK: - Color Row

struct ColorRow: View {
    let color: Color
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Color preview
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))

            // Color info
            VStack(alignment: .leading, spacing: 4) {
                Text("Color \(index + 1)")
                    .font(Typography.bodyRegular)

                Text(color.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Actions
            HStack(spacing: Spacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit color \(index + 1)")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.error)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete color \(index + 1)")
            }
        }
        .padding()
        .background(AppColors.textSecondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Color Picker Modal

struct ColorPickerModal: View {
    let title: String
    @Binding var selectedColor: Color
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(title)
                .font(Typography.heading)

            ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .frame(height: 200)

            // Show hex value
            Text(selectedColor.hexString)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(AppColors.textSecondary)

            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)

                Spacer()

                Button("Add", action: onSave)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 350)
    }
}

// MARK: - Preview

#Preview {
    PrimaryColorPickerSheet(
        colors: .constant([.blue, .pink]),
        maxColors: 4,
        onDismiss: {})
}
