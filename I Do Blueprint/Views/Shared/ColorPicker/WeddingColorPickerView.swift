//
//  WeddingColorPickerView.swift
//  I Do Blueprint
//
//  SwiftUI wrapper for ColorSelector package by jaywcjlove
//  Provides a macOS-optimized color picker for wedding colors with modal presentation
//

import SwiftUI
import ColorSelector

// MARK: - Wedding Color Picker View

/// A macOS-optimized color picker using ColorSelector package
/// Opens in a modal sheet matching the guest management pattern
struct WeddingColorPickerView: View {
    @Binding var selectedColor: Color
    @State private var showingPicker = false
    
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
            // Color preview button
            Button(action: { showingPicker = true }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label) color picker")
            .accessibilityHint("Opens color picker modal")
            
            if showLabel {
                Text(label)
                    .font(Typography.bodyRegular)
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
        .sheet(isPresented: $showingPicker) {
            WeddingColorPickerModal(
                selectedColor: $selectedColor,
                presetColors: presetColors
            )
        }
        .onAppear {
            hexInput = selectedColor.toHex()
        }
    }
}

// MARK: - Wedding Color Picker Modal

/// Modal presentation of ColorSelector with wedding color presets
/// Redesigned layout: Selected Color (with integrated picker) + Wedding Presets (wrapped grid)
struct WeddingColorPickerModal: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: Color
    let presetColors: [NSColor]
    
    @State private var currentColor: Color
    @State private var isSaving = false
    
    init(
        selectedColor: Binding<Color>,
        presetColors: [NSColor]
    ) {
        self._selectedColor = selectedColor
        self.presetColors = presetColors
        self._currentColor = State(initialValue: selectedColor.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            modalHeader
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Selected Color with Integrated Picker
                    selectedColorSection
                    
                    Divider()
                        .padding(.horizontal, Spacing.xl)
                    
                    // Wedding Color Presets (Wrapped Grid)
                    presetsSection
                }
                .padding(.vertical, Spacing.xl)
            }
            
            Divider()
            
            // Footer
            modalFooter
        }
    }
    
    // MARK: - Header
    
    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose Wedding Color")
                    .font(Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("Select from presets or use the color wheel")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close color picker")
        }
        .padding(Spacing.lg)
        .background(SemanticColors.controlBackground)
    }
    
    // MARK: - Selected Color Section (with Integrated Picker)
    
    private var selectedColorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Selected Color")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(.horizontal, Spacing.xl)
            
            HStack(alignment: .top, spacing: Spacing.xl) {
                // Left: Color Preview and Hex Info
                VStack(alignment: .leading, spacing: Spacing.md) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentColor)
                        .frame(width: 120, height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Hex Code")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                        
                        Text(currentColor.toHex())
                            .font(Typography.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(SemanticColors.textPrimary)
                            .textSelection(.enabled)
                    }
                }
                
                // Right: Integrated Color Picker
                ColorSelector(selection: Binding(
                    get: { currentColor },
                    set: { if let newColor = $0 { currentColor = newColor } }
                ))
                    .environment(\.swatchColors, presetColors)
                    .frame(width: 280, height: 280)
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
    
    // MARK: - Presets Section (Wrapped Grid)
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Wedding Color Presets")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(.horizontal, Spacing.xl)
            
            Text("Quick selection of popular wedding color combinations")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
                .padding(.horizontal, Spacing.xl)
            
            // Wrapped Grid Layout
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 100), spacing: Spacing.md)
                ],
                spacing: Spacing.md
            ) {
                ForEach(Array(presetColors.enumerated()), id: \.offset) { index, nsColor in
                    let color = Color(nsColor: nsColor)
                    Button(action: {
                        currentColor = color
                    }) {
                        VStack(spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            currentColor.toHex() == color.toHex()
                                                ? SemanticColors.primaryAction
                                                : SemanticColors.borderPrimary,
                                            lineWidth: currentColor.toHex() == color.toHex() ? 3 : 1
                                        )
                                )
                            
                            if currentColor.toHex() == color.toHex() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(SemanticColors.primaryAction)
                                    .font(.caption)
                            } else {
                                // Spacer to maintain consistent height
                                Color.clear
                                    .frame(height: 16)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Preset color \(index + 1)")
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
    
    // MARK: - Footer
    
    private var modalFooter: some View {
        HStack(spacing: Spacing.md) {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button {
                saveColor()
            } label: {
                if isSaving {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Applying...")
                    }
                } else {
                    Text("Select Color")
                }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
        }
        .padding(Spacing.lg)
        .background(SemanticColors.controlBackground)
    }
    
    // MARK: - Actions
    
    private func saveColor() {
        isSaving = true
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            selectedColor = currentColor
            isSaving = false
            dismiss()
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

#Preview("Color Picker Modal") {
    @Previewable @State var selectedColor = Color.fromHex("FFE5E5")
    @Previewable @State var showModal = true
    
    return Button("Show Color Picker") {
        showModal = true
    }
    .sheet(isPresented: $showModal) {
        WeddingColorPickerModal(
            selectedColor: $selectedColor,
            presetColors: WeddingColorPresets.allNSColors
        )
    }
}
