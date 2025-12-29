//
//  ColorAlgorithmModels.swift
//  I Do Blueprint
//
//  Supporting models for color extraction algorithms
//

import AppKit
import Foundation

// MARK: - Color Cluster

struct ColorCluster {
    let centroid: SIMD3<Float>
    let points: [SIMD3<Float>]
    let inertia: Float
}

// MARK: - Accessibility Models

struct AccessibilityInfo {
    let contrastPairs: [ContrastPair]
    let overallCompliance: Bool
    let recommendations: [String]
}

struct ContrastPair {
    let color1: NSColor
    let color2: NSColor
    let ratio: Double
    let wcagAA: Bool
    let wcagAAA: Bool
}

// MARK: - Extraction Error

enum ColorExtractionError: LocalizedError {
    case invalidImageData
    case imageConversionFailed
    case filterCreationFailed
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "Invalid image data provided"
        case .imageConversionFailed:
            "Failed to convert image for processing"
        case .filterCreationFailed:
            "Failed to create Core Image filter"
        case .processingFailed:
            "Color extraction processing failed"
        }
    }
}

// MARK: - SIMD Extensions

extension SIMD3 where Scalar == Float {
    var r: Float { x }
    var g: Float { y }
    var b: Float { z }
}
