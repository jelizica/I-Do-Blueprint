//
//  ColorComparisonHelper.swift
//  I Do Blueprint
//
//  Helper for comparing color similarity
//

import Foundation
import SwiftUI

/// Helper for comparing colors by HSB values
struct ColorComparisonHelper {
    
    /// Check if two colors are similar within a threshold
    static func areSimilar(_ color1: Color, _ color2: Color, threshold: Double) -> Bool {
        let hsb1 = color1.hsb
        let hsb2 = color2.hsb
        
        let hueDiff = abs(hsb1.hue - hsb2.hue)
        let satDiff = abs(hsb1.saturation - hsb2.saturation)
        let brightDiff = abs(hsb1.brightness - hsb2.brightness)
        
        let totalDiff = hueDiff + satDiff + brightDiff
        return totalDiff < threshold
    }
}

// MARK: - Color HSB Extension

extension Color {
    var hsb: (hue: Double, saturation: Double, brightness: Double) {
        let uiColor = NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return (Double(hue * 360), Double(saturation * 100), Double(brightness * 100))
    }
}
