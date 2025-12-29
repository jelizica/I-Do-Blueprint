//
//  ColorExtractionModels.swift
//  I Do Blueprint
//
//  Core data models for color extraction
//

import AppKit
import Foundation
import SwiftUI

// MARK: - Extraction Algorithm

enum ColorExtractionAlgorithm: String, CaseIterable {
    case vibrant = "vibrant"
    case quantization = "quantization"
    case clustering = "clustering"
    case dominant = "dominant"

    var displayName: String {
        switch self {
        case .vibrant: "Vibrant"
        case .quantization: "Quantization"
        case .clustering: "K-Means Clustering"
        case .dominant: "Dominant Colors"
        }
    }

    var description: String {
        switch self {
        case .vibrant: "Extracts vibrant and saturated colors"
        case .quantization: "Reduces color palette through quantization"
        case .clustering: "Groups similar colors using k-means clustering"
        case .dominant: "Identifies most prominent colors in the image"
        }
    }
}

// MARK: - Extraction Options

struct ColorExtractionOptions {
    let maxColors: Int
    let includeAccessibility: Bool
    let qualityThreshold: Double

    init(maxColors: Int = 6, includeAccessibility: Bool = true, qualityThreshold: Double = 0.1) {
        self.maxColors = maxColors
        self.includeAccessibility = includeAccessibility
        self.qualityThreshold = qualityThreshold
    }
}

// MARK: - Extracted Color

struct ExtractedColor {
    let color: NSColor
    let population: Double // 0.0 to 1.0
    let confidence: Double // 0.0 to 1.0

    var swiftUIColor: Color {
        Color(nsColor: color)
    }

    var hexString: String {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return "#000000" }
        return String(
            format: "#%02X%02X%02X",
            Int(rgb.redComponent * 255),
            Int(rgb.greenComponent * 255),
            Int(rgb.blueComponent * 255))
    }
}

// MARK: - Extraction Metadata

struct ExtractionMetadata {
    let algorithm: ColorExtractionAlgorithm
    let imageSize: CGSize
    let colorCount: Int
    let parameters: [String: Any]
}

// MARK: - Extraction Result

struct ColorExtractionResult {
    let colors: [ExtractedColor]
    let algorithm: ColorExtractionAlgorithm
    let qualityScore: Double
    let processingTimeMs: Double
    let metadata: ExtractionMetadata
    let accessibilityInfo: AccessibilityInfo?
}
