//
//  QuantizationAlgorithm.swift
//  I Do Blueprint
//
//  Color quantization algorithm using CIColorPosterize
//

import AppKit
import CoreImage
import Foundation

/// Actor-based quantization algorithm
actor QuantizationAlgorithm: ColorExtractionAlgorithmProtocol {
    
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

        // Use CIColorPosterize for quantization
        guard let posterizeFilter = CIFilter(name: "CIColorPosterize") else {
            throw ColorExtractionError.filterCreationFailed
        }

        posterizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        posterizeFilter.setValue(options.maxColors, forKey: "inputLevels")

        guard let posterizedImage = posterizeFilter.outputImage else {
            throw ColorExtractionError.processingFailed
        }

        progressHandler(0.6)

        // Extract unique colors from posterized image
        let colors = try await extractUniqueColors(from: posterizedImage, maxColors: options.maxColors)

        progressHandler(0.8)

        let metadata = ExtractionMetadata(
            algorithm: .quantization,
            imageSize: ciImage.extent.size,
            colorCount: colors.count,
            parameters: ["quantization_levels": options.maxColors])

        return (colors, metadata)
    }
    
    // MARK: - Private Helpers
    
    private func extractUniqueColors(from ciImage: CIImage, maxColors: Int) async throws -> [ExtractedColor] {
        // Sample colors from the posterized image
        let sampledPixels = try await imageProcessor.samplePixels(
            from: ciImage,
            sampleCount: min(maxColors * 100, 5000)
        )

        var colorCounts: [SIMD3<Float>: Int] = [:]
        for pixel in sampledPixels {
            colorCounts[pixel, default: 0] += 1
        }

        let sortedColors = colorCounts.sorted { $0.value > $1.value }
        let totalPixels = sampledPixels.count

        return Array(sortedColors.prefix(maxColors)).map { color, count in
            ExtractedColor(
                color: NSColor(
                    red: CGFloat(color.x),
                    green: CGFloat(color.y),
                    blue: CGFloat(color.z),
                    alpha: 1.0),
                population: Double(count) / Double(totalPixels),
                confidence: 0.8 // Fixed confidence for quantized colors
            )
        }
    }
}
