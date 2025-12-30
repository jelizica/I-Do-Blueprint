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

        progressHandler(1.0)
        return (colors, metadata)
    }
    
    // MARK: - Private Helpers
    
    private func analyzeHistogramForVibrantColors(
        _ histogramData: [SIMD4<Float>],
        maxColors: Int
    ) -> [ExtractedColor] {
        // CIAreaHistogram returns 256 bins where:
        // - Bin index (0-255) represents the color intensity value
        // - RGBA values in each bin represent pixel counts for that intensity

        guard histogramData.count == 256 else {
            return []
        }

        // Calculate total pixel count from any channel (all channels should sum to same total)
        let totalPixelCount = histogramData.reduce(0.0) { $0 + $1.x }
        guard totalPixelCount > 0 else { return [] }

        // Build a 3D color histogram by quantizing RGB values to reduce memory
        // Quantize each channel to 32 levels (divide by 8) for 32×32×32 = 32,768 possible colors
        let quantizationFactor = 8
        var colorHistogram: [SIMD3<UInt8>: Float] = [:]

        // Extract channel histograms (bin index -> pixel count)
        let redHistogram = histogramData.map { $0.x }
        let greenHistogram = histogramData.map { $0.y }
        let blueHistogram = histogramData.map { $0.z }

        // Build 3D histogram by combining actual RGB occurrences
        // For each intensity combination, estimate co-occurrence frequency
        for redIntensity in 0..<256 where redHistogram[redIntensity] > 0 {
            for greenIntensity in 0..<256 where greenHistogram[greenIntensity] > 0 {
                for blueIntensity in 0..<256 where blueHistogram[blueIntensity] > 0 {
                    // Quantize to reduce color space
                    let quantizedR = UInt8((redIntensity / quantizationFactor) * quantizationFactor)
                    let quantizedG = UInt8((greenIntensity / quantizationFactor) * quantizationFactor)
                    let quantizedB = UInt8((blueIntensity / quantizationFactor) * quantizationFactor)
                    let quantizedColor = SIMD3<UInt8>(quantizedR, quantizedG, quantizedB)

                    // Use geometric mean as better estimate than min() for co-occurrence
                    // This better represents the likelihood that these intensities appear together
                    let estimatedCount = pow(
                        redHistogram[redIntensity] * greenHistogram[greenIntensity] * blueHistogram[blueIntensity],
                        1.0/3.0
                    )

                    colorHistogram[quantizedColor, default: 0] += estimatedCount
                }
            }
        }

        // Convert histogram to color candidates
        var colorCandidates: [(color: SIMD3<Float>, count: Float)] = []

        for (quantizedColor, count) in colorHistogram {
            // Normalize quantized values (0-255) to (0.0-1.0)
            let color = SIMD3<Float>(
                Float(quantizedColor.x) / 255.0,
                Float(quantizedColor.y) / 255.0,
                Float(quantizedColor.z) / 255.0
            )

            // Only include colors with meaningful presence
            if count > totalPixelCount * 0.001 {
                colorCandidates.append((color: color, count: count))
            }
        }

        // Sort by vibrancy score weighted by population
        let sortedColors = colorCandidates.sorted { lhs, rhs in
            let lhsVibrancy = ColorSpaceConverter.calculateVibrancy(lhs.color)
            let rhsVibrancy = ColorSpaceConverter.calculateVibrancy(rhs.color)
            let lhsScore = lhsVibrancy * Double(lhs.count)
            let rhsScore = rhsVibrancy * Double(rhs.count)
            return lhsScore > rhsScore
        }

        // Return top N most vibrant colors
        return Array(sortedColors.prefix(maxColors)).map { item in
            ExtractedColor(
                color: NSColor(
                    red: CGFloat(item.color.x),
                    green: CGFloat(item.color.y),
                    blue: CGFloat(item.color.z),
                    alpha: 1.0
                ),
                population: Double(item.count) / Double(totalPixelCount),
                confidence: ColorSpaceConverter.calculateVibrancy(item.color)
            )
        }
    }

    /// Finds the most common intensity values in a channel histogram
    /// - Parameters:
    ///   - channelHistogram: Array of 256 bins with pixel counts
    ///   - topN: Number of dominant intensities to return
    /// - Returns: Array of (intensity, count) tuples sorted by count descending
    private func findDominantIntensities(
        _ channelHistogram: [Float],
        topN: Int
    ) -> [(intensity: Int, count: Float)] {
        let indexed = channelHistogram.enumerated().map { (intensity: $0, count: $1) }
        let sorted = indexed.sorted { $0.count > $1.count }
        let dominant = Array(sorted.prefix(topN)).filter { $0.count > 0 }
        return dominant
    }
}
