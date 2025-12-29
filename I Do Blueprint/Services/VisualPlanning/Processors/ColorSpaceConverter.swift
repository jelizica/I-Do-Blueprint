//
//  ColorSpaceConverter.swift
//  I Do Blueprint
//
//  Color space conversion utilities
//

import AppKit
import Foundation

/// Pure functions for color space conversions
enum ColorSpaceConverter {
    
    // MARK: - Vibrancy Calculation
    
    static func calculateVibrancy(_ color: SIMD3<Float>) -> Double {
        let max = Swift.max(color.x, Swift.max(color.y, color.z))
        let min = Swift.min(color.x, Swift.min(color.y, color.z))
        let saturation = max > 0 ? (max - min) / max : 0
        return Double(saturation)
    }
    
    // MARK: - Color Distance
    
    static func calculateColorDistance(_ color1: NSColor, _ color2: NSColor) -> Double {
        guard let rgb1 = color1.usingColorSpace(.deviceRGB),
              let rgb2 = color2.usingColorSpace(.deviceRGB) else { return 0 }

        let dr = rgb1.redComponent - rgb2.redComponent
        let dg = rgb1.greenComponent - rgb2.greenComponent
        let db = rgb1.blueComponent - rgb2.blueComponent

        return sqrt(dr * dr + dg * dg + db * db)
    }
    
    // MARK: - Relative Luminance (WCAG)
    
    static func calculateRelativeLuminance(_ color: NSColor) -> Double {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return 0 }

        func gammaCorrect(_ component: CGFloat) -> Double {
            let c = Double(component)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }

        let r = gammaCorrect(rgb.redComponent)
        let g = gammaCorrect(rgb.greenComponent)
        let b = gammaCorrect(rgb.blueComponent)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    // MARK: - Contrast Ratio (WCAG)
    
    static func calculateContrastRatio(_ color1: NSColor, _ color2: NSColor) -> Double {
        let luminance1 = calculateRelativeLuminance(color1)
        let luminance2 = calculateRelativeLuminance(color2)

        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)

        return (lighter + 0.05) / (darker + 0.05)
    }
}
