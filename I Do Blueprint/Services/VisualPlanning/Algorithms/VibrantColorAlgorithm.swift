//
//  VibrantColorAlgorithm.swift
//  I Do Blueprint
//
//  Vibrant color extraction algorithm using histogram analysis
//

import AppKit
import CoreImage
import Foundation

/// Actor-based vibrant color extraction algorithm
actor VibrantColorAlgorithm: ColorExtractionAlgorithmProtocol {
    
    private let imageProcessor: ImageProcessingService
    
    init(imageProcessor: ImageProcessingService = ImageProcessingService()) {
        self.imageProcessor = imageProcessor
    }
    
    // MARK: - ColorExtractionAlgorithmProtocol
    
    func extractColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> ([ExtractedColor], ExtractionMetadata) {
        
        progressHandler(0.3)
        
        // Use Core Image's built-in area histogram
        guard let histogramFilter = CIFilter(name: "CIAreaHistogram") else {
            throw ColorExtractionError.filterCreationFailed
        }

        histogramFilter.setValue(ciImage, forKey: kCIInputImageKey)
        histogramFilter.setValue(
            CIVector(x: 0, y: 0, z: ciImage.extent.width, w: ciImage.extent.height),
            forKey: "inputExtent")
        histogramFilter.setValue(256, forKey: "inputCount")

        guard let histogramImage = histogramFilter.outputImage else {
            throw ColorExtractionError.processingFailed
        }

        progressHandler(0.5)

        // Extract histogram data
        let histogramData = try await imageProcessor.extractHistogramData(from: histogramImage)

        progressHandler(0.7)

        // Analyze histogram for vibrant colors
        let colors = analyzeHistogramForVibrantColors(histogramData, maxColors: options.maxColors)

        let metadata = ExtractionMetadata(
            algorithm: .vibrant,
            imageSize: ciImage.extent.size,
            colorCount: colors.count,
            parameters: ["vibrant_threshold": 0.6, "saturation_weight": 2.0])

        return (colors, metadata)
    }
    
    // MARK: - Private Helpers
    
    private func analyzeHistogramForVibrantColors(
        _ histogramData: [SIMD4<Float>],
        maxColors: Int
    ) -> [ExtractedColor] {
        var colorCounts: [SIMD3<Float>: Int] = [:]

        // Count color occurrences
        for pixel in histogramData {
            let color = SIMD3<Float>(pixel.x, pixel.y, pixel.z)
            colorCounts[color, default: 0] += 1
        }

        // Sort by frequency and vibrancy
        let sortedColors = colorCounts.sorted { lhs, rhs in
            let lhsVibrancy = ColorSpaceConverter.calculateVibrancy(lhs.key)
            let rhsVibrancy = ColorSpaceConverter.calculateVibrancy(rhs.key)
            let lhsScore = lhsVibrancy * Double(lhs.value)
            let rhsScore = rhsVibrancy * Double(rhs.value)
            return lhsScore > rhsScore
        }

        let totalPixels = histogramData.count
        return Array(sortedColors.prefix(maxColors)).map { color, count in
            ExtractedColor(
                color: NSColor(
                    red: CGFloat(color.x),
                    green: CGFloat(color.y),
                    blue: CGFloat(color.z),
                    alpha: 1.0),
                population: Double(count) / Double(totalPixels),
                confidence: ColorSpaceConverter.calculateVibrancy(color))
        }
    }
}
