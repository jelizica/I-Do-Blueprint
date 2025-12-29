//
//  ColorExtractionService.swift
//  My Wedding Planning App
//
//  Color extraction service using Core Image and native algorithms
//  Refactored to façade pattern - delegates to specialized services
//

import Accelerate
import AppKit
import Combine
import CoreImage
import Foundation
import SwiftUI
import Vision

// Import extracted models
// Models are now in Services/VisualPlanning/Models/
// - ColorExtractionModels.swift: ExtractedColor, ColorExtractionResult, ColorExtractionOptions, ExtractionMetadata, ColorExtractionAlgorithm
// - ColorAlgorithmModels.swift: ColorCluster, ContrastPair, AccessibilityInfo, ColorExtractionError

@MainActor
class ColorExtractionService: ObservableObject {
    @Published var isExtracting = false
    @Published var progress: Double = 0
    @Published var lastError: String?

    // Composed services
    private let imageProcessor = ImageProcessingService()
    private let vibrantAlgorithm: VibrantColorAlgorithm
    private let quantizationAlgorithm: QuantizationAlgorithm
    private let clusteringAlgorithm: ClusteringAlgorithm
    private let dominantAlgorithm: DominantColorAlgorithm
    
    init() {
        // Initialize algorithms with shared image processor
        self.vibrantAlgorithm = VibrantColorAlgorithm(imageProcessor: imageProcessor)
        self.quantizationAlgorithm = QuantizationAlgorithm(imageProcessor: imageProcessor)
        self.clusteringAlgorithm = ClusteringAlgorithm(imageProcessor: imageProcessor)
        self.dominantAlgorithm = DominantColorAlgorithm(imageProcessor: imageProcessor)
    }

    // MARK: - Public Interface

    /// Extract colors from an image using the specified algorithm
    func extractColors(
        from image: NSImage,
        algorithm: ColorExtractionAlgorithm = .vibrant,
        options: ColorExtractionOptions = ColorExtractionOptions()) async throws -> ColorExtractionResult {
        isExtracting = true
        progress = 0
        lastError = nil

        defer {
            isExtracting = false
            progress = 0
        }

        do {
            let result = try await performExtraction(
                image: image,
                algorithm: algorithm,
                options: options)
            return result
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    /// Extract colors from image data
    func extractColors(
        from imageData: Data,
        algorithm: ColorExtractionAlgorithm = .vibrant,
        options: ColorExtractionOptions = ColorExtractionOptions()) async throws -> ColorExtractionResult {
        guard let image = NSImage(data: imageData) else {
            throw ColorExtractionError.invalidImageData
        }
        return try await extractColors(from: image, algorithm: algorithm, options: options)
    }

    /// Extract colors from image URL
    func extractColors(
        from url: URL,
        algorithm: ColorExtractionAlgorithm = .vibrant,
        options: ColorExtractionOptions = ColorExtractionOptions()) async throws -> ColorExtractionResult {
        let imageData = try Data(contentsOf: url)
        return try await extractColors(from: imageData, algorithm: algorithm, options: options)
    }

    /// Compare multiple extraction algorithms
    func compareAlgorithms(
        for image: NSImage,
        algorithms: [ColorExtractionAlgorithm] = ColorExtractionAlgorithm.allCases,
        options: ColorExtractionOptions = ColorExtractionOptions()) async throws
        -> [ColorExtractionAlgorithm: ColorExtractionResult] {
        var results: [ColorExtractionAlgorithm: ColorExtractionResult] = [:]

        for (index, algorithm) in algorithms.enumerated() {
            progress = Double(index) / Double(algorithms.count)
            results[algorithm] = try await extractColors(from: image, algorithm: algorithm, options: options)
        }

        return results
    }

    // MARK: - Core Extraction Logic

    private func performExtraction(
        image: NSImage,
        algorithm: ColorExtractionAlgorithm,
        options: ColorExtractionOptions) async throws -> ColorExtractionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Convert NSImage to CIImage for processing
        guard let ciImage = await imageProcessor.convertToCIImage(image) else {
            throw ColorExtractionError.imageConversionFailed
        }

        progress = 0.2

        // Delegate to algorithm-specific implementations
        let colors: [ExtractedColor]
        let metadata: ExtractionMetadata
        
        let progressHandler: (Double) -> Void = { [weak self] algorithmProgress in
            Task { @MainActor in
                self?.progress = 0.2 + (algorithmProgress * 0.6) // Map 0-1 to 0.2-0.8
            }
        }

        switch algorithm {
        case .vibrant:
            (colors, metadata) = try await vibrantAlgorithm.extractColors(
                from: ciImage,
                options: options,
                progressHandler: progressHandler
            )
        case .quantization:
            (colors, metadata) = try await quantizationAlgorithm.extractColors(
                from: ciImage,
                options: options,
                progressHandler: progressHandler
            )
        case .clustering:
            (colors, metadata) = try await clusteringAlgorithm.extractColors(
                from: ciImage,
                options: options,
                progressHandler: progressHandler
            )
        case .dominant:
            (colors, metadata) = try await dominantAlgorithm.extractColors(
                from: ciImage,
                options: options,
                progressHandler: progressHandler
            )
        }

        progress = 0.8

        // Calculate quality score using analyzer
        let qualityScore = ColorQualityAnalyzer.calculateQualityScore(for: colors, metadata: metadata)

        progress = 0.9

        // Generate accessibility information if requested
        var accessibilityInfo: AccessibilityInfo?
        if options.includeAccessibility {
            accessibilityInfo = ColorAccessibilityAnalyzer.generateAccessibilityInfo(for: colors)
        }

        progress = 1.0

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        return ColorExtractionResult(
            colors: colors,
            algorithm: algorithm,
            qualityScore: qualityScore,
            processingTimeMs: processingTime * 1000,
            metadata: metadata,
            accessibilityInfo: accessibilityInfo)
    }
}

// MARK: - Extracted Components
// All algorithm implementations, helper functions, and supporting types have been extracted to:
// - Algorithms/: VibrantColorAlgorithm, QuantizationAlgorithm, ClusteringAlgorithm, DominantColorAlgorithm
// - Processors/: ImageProcessingService, ColorSpaceConverter
// - Analysis/: ColorQualityAnalyzer, ColorAccessibilityAnalyzer
// - Models/: ColorExtractionModels, ColorAlgorithmModels
