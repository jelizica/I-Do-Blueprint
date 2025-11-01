//
//  ColorPaletteComponents.swift
//  My Wedding Planning App
//
//  Supporting components for the color palette creator
//

import SwiftUI

// MARK: - Color Refinement Row

struct ColorRefinementRow: View {
    @Binding var paletteColor: PaletteColor
    let onColorChange: (Color) -> Void

    @State private var showingColorPicker = false

    var body: some View {
        HStack(spacing: 12) {
            // Color swatch
            Button(action: {
                showingColorPicker = true
            }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(paletteColor.color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                // Role picker
                HStack {
                    Text("Role:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Role", selection: $paletteColor.role) {
                        ForEach(ColorRole.allCases, id: \.self) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                // Color info
                VStack(alignment: .leading, spacing: 2) {
                    Text(paletteColor.color.hexString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)

                    let hsb = paletteColor.color.hsbComponents
                    Text("H:\(Int(hsb.hue * 360))° S:\(Int(hsb.saturation * 100))% B:\(Int(hsb.brightness * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Quick adjustment buttons
            VStack(spacing: 4) {
                Button("Lighter") {
                    adjustBrightness(by: 0.1)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button("Darker") {
                    adjustBrightness(by: -0.1)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding()
        .background(AppColors.textSecondary.opacity(0.05))
        .cornerRadius(12)
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(selectedColor: Binding(
                get: { paletteColor.color },
                set: { newColor in
                    paletteColor.color = newColor
                    onColorChange(newColor)
                }))
        }
    }

    private func adjustBrightness(by amount: Double) {
        let hsb = paletteColor.color.hsbComponents
        let newBrightness = max(0.1, min(1.0, hsb.brightness + amount))
        let newColor = Color(hue: hsb.hue, saturation: hsb.saturation, brightness: newBrightness)
        paletteColor.color = newColor
        onColorChange(newColor)
    }
}

// MARK: - Color Picker Sheet

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Color")
                .font(.title2)
                .fontWeight(.semibold)

            ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .frame(height: 300)

            VStack(spacing: 8) {
                Text("Selected Color")
                    .font(.subheadline)
                    .fontWeight(.medium)

                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))

                Text(selectedColor.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

// MARK: - Wedding Mockup View

struct WeddingMockupView: View {
    let colors: [Color]

    var body: some View {
        VStack(spacing: 16) {
            // Wedding invitation mockup
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.first ?? .white)
                    .frame(width: 280, height: 200)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                VStack(spacing: 12) {
                    // Header decoration
                    HStack {
                        ForEach(0 ..< 3, id: \.self) { _ in
                            Circle()
                                .fill(colors.count > 2 ? colors[2] : .gray)
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Title
                    Text("Sarah & Michael")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colors.count > 1 ? colors[1] : .black)

                    Rectangle()
                        .fill(colors.count > 1 ? colors[1] : .gray)
                        .frame(width: 120, height: 1)

                    Text("Request the pleasure of your company")
                        .font(.caption)
                        .foregroundColor(colors.count > 3 ? colors[3] : .secondary)

                    Text("June 15th, 2024")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colors.count > 1 ? colors[1] : .black)

                    // Footer decoration
                    HStack {
                        ForEach(0 ..< 5, id: \.self) { _ in
                            Circle()
                                .fill(colors.count > 2 ? colors[2] : .gray)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                .padding()
            }

            // Color swatches below
            HStack(spacing: 8) {
                ForEach(colors.indices, id: \.self) { index in
                    Circle()
                        .fill(colors[index])
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Accessibility Analysis

enum AccessibilityAnalyzer {
    static func calculateContrastRatio(foreground: Color, background: Color) -> Double {
        let fgLuminance = getLuminance(foreground)
        let bgLuminance = getLuminance(background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    static func meetsWCAGStandard(_ ratio: Double, level: WCAGLevel) -> Bool {
        switch level {
        case .aa:
            ratio >= 4.5
        case .aaa:
            ratio >= 7.0
        case .aaLarge:
            ratio >= 3.0
        case .aaaLarge:
            ratio >= 4.5
        }
    }

    private static func getLuminance(_ color: Color) -> Double {
        let nsColor = NSColor(color)
        let red = nsColor.redComponent
        let green = nsColor.greenComponent
        let blue = nsColor.blueComponent

        let r = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let g = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let b = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}

enum WCAGLevel {
    case aa, aaa, aaLarge, aaaLarge

    var title: String {
        switch self {
        case .aa: "AA"
        case .aaa: "AAA"
        case .aaLarge: "AA Large"
        case .aaaLarge: "AAA Large"
        }
    }
}

struct AccessibilityContrastCard: View {
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        let contrastRatio = AccessibilityAnalyzer.calculateContrastRatio(
            foreground: foregroundColor,
            background: backgroundColor)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Contrast Analysis")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(contrastRatio, specifier: "%.1f"):1")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
            }

            // Preview box
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(height: 80)
                .overlay(
                    VStack(spacing: 4) {
                        Text("Sample Text")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(foregroundColor)

                        Text("Secondary text example")
                            .font(.caption)
                            .foregroundColor(foregroundColor.opacity(0.8))
                    })

            // WCAG compliance
            VStack(alignment: .leading, spacing: 4) {
                ForEach([WCAGLevel.aa, .aaa, .aaLarge, .aaaLarge], id: \.title) { level in
                    HStack {
                        Image(systemName: AccessibilityAnalyzer
                            .meetsWCAGStandard(contrastRatio, level: level) ? "checkmark.circle.fill" :
                            "xmark.circle.fill")
                            .foregroundColor(AccessibilityAnalyzer
                                .meetsWCAGStandard(contrastRatio, level: level) ? .green : .red)
                            .font(.caption)

                        Text("WCAG \(level.title)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.textSecondary.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        ColorRefinementRow(
            paletteColor: .constant(PaletteColor(color: .blue, role: .primary))) { _ in }

        WeddingMockupView(colors: [.blue, .purple, .pink, .gray])

        AccessibilityContrastCard(
            backgroundColor: .white,
            foregroundColor: .black)
    }
    .padding()
}
