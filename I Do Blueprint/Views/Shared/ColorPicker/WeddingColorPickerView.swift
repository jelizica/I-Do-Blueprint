//
//  WeddingColorPickerView.swift
//  I Do Blueprint
//
//  SwiftUI wrapper for ColorSelector package by jaywcjlove
//  Provides a macOS-optimized color picker for wedding colors
//

import SwiftUI
import ColorSelector

// MARK: - Wedding Color Picker View

/// A macOS-optimized color picker using ColorSelector package
/// Replaces the native ColorPicker with better UX and centered modal presentation
struct WeddingColorPickerView: View {
    @Binding var selectedColor: Color
    
    let label: String
    let showLabel: Bool
    let showHexInput: Bool
    let presetColors: [NSColor]
    
    @State private var hexInput: String = ""
    
    init(
        label: String = "Color",
        selectedColor: Binding<Color>,
        showLabel: Bool = true,
        showHexInput: Bool = true,
        presetColors: [NSColor] = WeddingColorPresets.allNSColors
    ) {
        self.label = label
        self._selectedColor = selectedColor
        self.showLabel = showLabel
        self.showHexInput = showHexInput
        self.presetColors = presetColors
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // ColorSelector with wedding presets
            ColorSelector(selection: $selectedColor)
                .environment(\.swatchColors, presetColors)
                .frame(width: 44, height: 44)
                .accessibilityLabel("\(label) color picker")
                .accessibilityHint("Opens color picker popover")
            
            if showLabel {
                Text(label)
                    .font(Typography.body)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            if showHexInput {
                TextField("#RRGGBB", text: $hexInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: hexInput) { _, newValue in
                        let cleaned = newValue.replacingOccurrences(of: "#", with: "")
                        if cleaned.count == 6, cleaned.allSatisfy({ $0.isHexDigit }) {
                            selectedColor = Color.fromHex(cleaned)
                        }
                    }
                    .onChange(of: selectedColor) { _, newColor in
                        hexInput = newColor.toHex()
                    }
                    .accessibilityLabel("Hex color code")
            }
        }
        .onAppear {
            hexInput = selectedColor.toHex()
        }
    }
}

// MARK: - Wedding Color Presets

/// Curated wedding color presets
enum WeddingColorPresets {
    // Romantic Blush
    static let romanticBlush1 = NSColor(hex: "FFE5E5")!
    static let romanticBlush2 = NSColor(hex: "FFC0CB")!
    
    // Garden Party
    static let gardenParty1 = NSColor(hex: "E8F5E9")!
    static let gardenParty2 = NSColor(hex: "81C784")!
    
    // Elegant Navy
    static let elegantNavy1 = NSColor(hex: "1A237E")!
    static let elegantNavy2 = NSColor(hex: "FFD700")!
    
    // Rustic Earth
    static let rusticEarth1 = NSColor(hex: "D4A574")!
    static let rusticEarth2 = NSColor(hex: "8B7355")!
    
    // Modern Minimalist
    static let modernMinimalist1 = NSColor(hex: "000000")!
    static let modernMinimalist2 = NSColor(hex: "FFFFFF")!
    
    // Lavender Dreams
    static let lavenderDreams1 = NSColor(hex: "E1BEE7")!
    static let lavenderDreams2 = NSColor(hex: "9C27B0")!
    
    // Sunset Romance
    static let sunsetRomance1 = NSColor(hex: "FF6B6B")!
    static let sunsetRomance2 = NSColor(hex: "FFA500")!
    
    // Ocean Breeze
    static let oceanBreeze1 = NSColor(hex: "B3E5FC")!
    static let oceanBreeze2 = NSColor(hex: "0277BD")!
    
    // Sage Serenity
    static let sageSerenity1 = NSColor(hex: "C8D5B9")!
    static let sageSerenity2 = NSColor(hex: "5A9070")!
    
    // Terracotta Warm
    static let terracottaWarm1 = NSColor(hex: "E07A5F")!
    static let terracottaWarm2 = NSColor(hex: "F4A261")!
    
    /// All preset colors for quick selection
    static let allNSColors: [NSColor] = [
        romanticBlush1, romanticBlush2,
        gardenParty1, gardenParty2,
        elegantNavy1, elegantNavy2,
        rusticEarth1, rusticEarth2,
        lavenderDreams1, lavenderDreams2,
        sunsetRomance1, sunsetRomance2,
        oceanBreeze1, oceanBreeze2,
        sageSerenity1, sageSerenity2,
        terracottaWarm1, terracottaWarm2
    ]
    
    /// Preset pairs for gradient selection
    static let pairs: [(NSColor, NSColor)] = [
        (romanticBlush1, romanticBlush2),
        (gardenParty1, gardenParty2),
        (elegantNavy1, elegantNavy2),
        (rusticEarth1, rusticEarth2),
        (lavenderDreams1, lavenderDreams2),
        (sunsetRomance1, sunsetRomance2),
        (oceanBreeze1, oceanBreeze2),
        (sageSerenity1, sageSerenity2),
        (terracottaWarm1, terracottaWarm2)
    ]
}

// MARK: - NSColor Hex Extension

extension NSColor {
    /// Initialize NSColor from hex string
    convenience init?(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 else { return nil }
        
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Preview

#Preview("Wedding Color Picker") {
    @Previewable @State var selectedColor = Color.fromHex("FFE5E5")
    
    return VStack(spacing: Spacing.lg) {
        WeddingColorPickerView(
            label: "Wedding Color 1",
            selectedColor: $selectedColor
        )
        
        WeddingColorPickerView(
            label: "Wedding Color 2",
            selectedColor: $selectedColor,
            showHexInput: false
        )
        
        // Preview with custom presets
        WeddingColorPickerView(
            label: "Custom Presets",
            selectedColor: $selectedColor,
            presetColors: [
                NSColor(hex: "FFE5E5")!,
                NSColor(hex: "FFC0CB")!,
                NSColor(hex: "E8F5E9")!,
                NSColor(hex: "81C784")!
            ]
        )
    }
    .padding()
}
