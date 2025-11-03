//
//  ColorExtractionService.swift
//  My Wedding Planning App
//
//  Color extraction service using Core Image and native algorithms
//

import Accelerate
import AppKit
import Combine
import CoreImage
import Foundation
import SwiftUI
import Vision

@MainActor
class ColorExtractionService: ObservableObject {
    @Published var isExtracting = false
    @Published var progress: Double = 0
    @Published var lastError: String?

    private let ciContext = CIContext()

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
        guard let ciImage = convertToCIImage(image) else {
            throw ColorExtractionError.imageConversionFailed
        }

        progress = 0.2

        let colors: [ExtractedColor]
        let metadata: ExtractionMetadata

        switch algorithm {
        case .vibrant:
            (colors, metadata) = try await extractVibrantColors(from: ciImage, options: options)
        case .quantization:
            (colors, metadata) = try await extractQuantizedColors(from: ciImage, options: options)
        case .clustering:
            (colors, metadata) = try await extractClusteredColors(from: ciImage, options: options)
        case .dominant:
            (colors, metadata) = try await extractDominantColors(from: ciImage, options: options)
        }

        progress = 0.8

        // Calculate quality score
        let qualityScore = calculateQualityScore(for: colors, metadata: metadata)

        progress = 0.9

        // Generate accessibility information if requested
        var accessibilityInfo: AccessibilityInfo?
        if options.includeAccessibility {
            accessibilityInfo = generateAccessibilityInfo(for: colors)
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

    // MARK: - Algorithm Implementations

    private func extractVibrantColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions) async throws -> ([ExtractedColor], ExtractionMetadata) {
        progress = 0.3

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

        progress = 0.5

        // Extract histogram data
        let histogramData = try extractHistogramData(from: histogramImage)

        progress = 0.7

        // Analyze histogram for vibrant colors
        let colors = analyzeHistogramForVibrantColors(histogramData, maxColors: options.maxColors)

        let metadata = ExtractionMetadata(
            algorithm: .vibrant,
            imageSize: ciImage.extent.size,
            colorCount: colors.count,
            parameters: ["vibrant_threshold": 0.6, "saturation_weight": 2.0])

        return (colors, metadata)
    }

    private func extractQuantizedColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions) async throws -> ([ExtractedColor], ExtractionMetadata) {
        progress = 0.3

        // Use CIColorPosterize for quantization
        guard let posterizeFilter = CIFilter(name: "CIColorPosterize") else {
            throw ColorExtractionError.filterCreationFailed
        }

        posterizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        posterizeFilter.setValue(options.maxColors, forKey: "inputLevels")

        guard let posterizedImage = posterizeFilter.outputImage else {
            throw ColorExtractionError.processingFailed
        }

        progress = 0.6

        // Extract unique colors from posterized image
        let colors = try extractUniqueColors(from: posterizedImage, maxColors: options.maxColors)

        progress = 0.8

        let metadata = ExtractionMetadata(
            algorithm: .quantization,
            imageSize: ciImage.extent.size,
            colorCount: colors.count,
            parameters: ["quantization_levels": options.maxColors])

        return (colors, metadata)
    }

    private func extractClusteredColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions) async throws -> ([ExtractedColor], ExtractionMetadata) {
        progress = 0.3

        // Sample pixels from the image
        let sampledPixels = try samplePixels(from: ciImage, sampleCount: 10000)

        progress = 0.5

        // Perform k-means clustering
        let clusters = performKMeansClustering(on: sampledPixels, k: options.maxColors)

        progress = 0.7

        // Convert clusters to ExtractedColor objects
        let colors = clusters.enumerated().map { _, cluster in
            ExtractedColor(
                color: NSColor(
                    red: CGFloat(cluster.centroid.r),
                    green: CGFloat(cluster.centroid.g),
                    blue: CGFloat(cluster.centroid.b),
                    alpha: 1.0),
                population: Double(cluster.points.count) / Double(sampledPixels.count),
                confidence: cluster.inertia > 0 ? 1.0 - (Double(cluster.inertia) / 100.0) : 1.0)
        }

        let metadata = ExtractionMetadata(
            algorithm: .clustering,
            imageSize: ciImage.extent.size,
            colorCount: colors.count,
            parameters: ["k_clusters": options.maxColors, "sample_size": sampledPixels.count])

        return (colors, metadata)
    }

    private func extractDominantColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions) async throws -> ([ExtractedColor], ExtractionMetadata) {
        progress = 0.3

        // Use Vision framework for more sophisticated analysis
        let colors = try await analyzeDominantColors(ciImage: ciImage, maxColors: options.maxColors)

        progress = 0.8

        let metadata = ExtractionMetadata(
            algorithm: .dominant,
            imageSize: ciImage.extent.size,
            colorCount: colors.count,
            parameters: ["vision_analysis": true])

        return (colors, metadata)
    }

    // MARK: - Helper Functions

    private func convertToCIImage(_ nsImage: NSImage) -> CIImage? {
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        let ciImage = CIImage(bitmapImageRep: bitmap)
        return ciImage
    }

    private func extractHistogramData(from histogramImage: CIImage) throws -> [SIMD4<Float>] {
        let width = Int(histogramImage.extent.width)
        let height = Int(histogramImage.extent.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var pixelData = [SIMD4<Float>](repeating: SIMD4<Float>(0, 0, 0, 0), count: width * height)

        ciContext.render(
            histogramImage,
            toBitmap: &pixelData,
            rowBytes: width * MemoryLayout<SIMD4<Float>>.stride,
            bounds: histogramImage.extent,
            format: .RGBAf,
            colorSpace: colorSpace)

        return pixelData
    }

    private func analyzeHistogramForVibrantColors(
        _ histogramData: [SIMD4<Float>],
        maxColors: Int) -> [ExtractedColor] {
        var colorCounts: [SIMD3<Float>: Int] = [:]

        // Count color occurrences
        for pixel in histogramData {
            let color = SIMD3<Float>(pixel.x, pixel.y, pixel.z)
            colorCounts[color, default: 0] += 1
        }

        // Sort by frequency and vibrancy
        let sortedColors = colorCounts.sorted { lhs, rhs in
            let lhsVibrancy = calculateVibrancy(lhs.key)
            let rhsVibrancy = calculateVibrancy(rhs.key)
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
                confidence: calculateVibrancy(color))
        }
    }

    private func calculateVibrancy(_ color: SIMD3<Float>) -> Double {
        let max = Swift.max(color.x, Swift.max(color.y, color.z))
        let min = Swift.min(color.x, Swift.min(color.y, color.z))
        let saturation = max > 0 ? (max - min) / max : 0
        return Double(saturation)
    }

    private func extractUniqueColors(from ciImage: CIImage, maxColors: Int) throws -> [ExtractedColor] {
        // Sample colors from the posterized image
        let sampledPixels = try samplePixels(from: ciImage, sampleCount: min(maxColors * 100, 5000))

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

    private func samplePixels(from ciImage: CIImage, sampleCount: Int) throws -> [SIMD3<Float>] {
        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        // Calculate sampling step
        let totalPixels = width * height
        let step = max(1, totalPixels / sampleCount)

        var pixels: [SIMD3<Float>] = []
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Create a smaller image for sampling
        let scale = min(1.0, sqrt(Double(sampleCount) / Double(totalPixels)))
        let scaledWidth = Int(Double(width) * scale)
        let scaledHeight = Int(Double(height) * scale)

        guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
            throw ColorExtractionError.filterCreationFailed
        }

        scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)

        guard let scaledImage = scaleFilter.outputImage else {
            throw ColorExtractionError.processingFailed
        }

        var pixelData = [SIMD4<Float>](repeating: SIMD4<Float>(0, 0, 0, 0), count: scaledWidth * scaledHeight)

        ciContext.render(
            scaledImage,
            toBitmap: &pixelData,
            rowBytes: scaledWidth * MemoryLayout<SIMD4<Float>>.stride,
            bounds: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight),
            format: .RGBAf,
            colorSpace: colorSpace)

        for pixel in pixelData {
            pixels.append(SIMD3<Float>(pixel.x, pixel.y, pixel.z))
        }

        return pixels
    }

    private func performKMeansClustering(on pixels: [SIMD3<Float>], k: Int) -> [ColorCluster] {
        guard !pixels.isEmpty, k > 0 else { return [] }

        // Initialize centroids randomly
        var centroids = (0 ..< k).map { _ in
            pixels.randomElement() ?? SIMD3<Float>(0.5, 0.5, 0.5)
        }

        var clusters = [ColorCluster]()
        let maxIterations = 50
        var assignments = Array(repeating: [SIMD3<Float>](), count: k)

        for _ in 0 ..< maxIterations {
            // Assign points to nearest centroid
            assignments = Array(repeating: [SIMD3<Float>](), count: k)

            for pixel in pixels {
                var minDistance = Float.infinity
                var nearestCluster = 0

                for (index, centroid) in centroids.enumerated() {
                    let distance = simd_distance(pixel, centroid)
                    if distance < minDistance {
                        minDistance = distance
                        nearestCluster = index
                    }
                }

                assignments[nearestCluster].append(pixel)
            }

            // Update centroids
            var newCentroids = [SIMD3<Float>]()
            var converged = true

            for assignment in assignments {
                if assignment.isEmpty {
                    // Keep old centroid if no points assigned
                    newCentroids.append(centroids[newCentroids.count])
                } else {
                    let sum = assignment.reduce(SIMD3<Float>(0, 0, 0), +)
                    let newCentroid = sum / Float(assignment.count)
                    newCentroids.append(newCentroid)

                    let oldCentroid = centroids[newCentroids.count - 1]
                    if simd_distance(newCentroid, oldCentroid) > 0.001 {
                        converged = false
                    }
                }
            }

            centroids = newCentroids

            if converged {
                break
            }
        }

        // Create clusters with inertia calculation
        for (index, assignment) in assignments.enumerated() {
            guard !assignment.isEmpty else { continue }

            let centroid = centroids[index]
            let inertia = assignment.reduce(0) { sum, point in
                sum + simd_distance_squared(point, centroid)
            } / Float(assignment.count)

            clusters.append(ColorCluster(
                centroid: centroid,
                points: assignment,
                inertia: inertia))
        }

        return clusters.sorted { $0.points.count > $1.points.count }
    }

    private func analyzeDominantColors(ciImage: CIImage, maxColors: Int) async throws -> [ExtractedColor] {
        // This would typically use Vision framework for more sophisticated analysis
        // For now, we'll use a simplified approach
        let sampledPixels = try samplePixels(from: ciImage, sampleCount: 5000)
        let clusters = performKMeansClustering(on: sampledPixels, k: maxColors)

        return clusters.map { cluster in
            ExtractedColor(
                color: NSColor(
                    red: CGFloat(cluster.centroid.r),
                    green: CGFloat(cluster.centroid.g),
                    blue: CGFloat(cluster.centroid.b),
                    alpha: 1.0),
                population: Double(cluster.points.count) / Double(sampledPixels.count),
                confidence: cluster.inertia > 0 ? max(0.1, 1.0 - Double(cluster.inertia)) : 1.0)
        }
    }

    private func calculateQualityScore(for colors: [ExtractedColor], metadata _: ExtractionMetadata) -> Double {
        guard !colors.isEmpty else { return 0 }

        // Calculate diversity score
        let diversityScore = calculateColorDiversity(colors)

        // Calculate confidence score
        let avgConfidence = colors.map(\.confidence).reduce(0, +) / Double(colors.count)

        // Calculate population distribution score
        let populationScore = calculatePopulationDistribution(colors)

        // Weighted average
        return diversityScore * 0.4 + avgConfidence * 0.4 + populationScore * 0.2
    }

    private func calculateColorDiversity(_ colors: [ExtractedColor]) -> Double {
        guard colors.count > 1 else { return 0 }

        var totalDistance = 0.0
        var comparisons = 0

        for i in 0 ..< colors.count {
            for j in (i + 1) ..< colors.count {
                let color1 = colors[i].color
                let color2 = colors[j].color

                let distance = calculateColorDistance(color1, color2)
                totalDistance += distance
                comparisons += 1
            }
        }

        return comparisons > 0 ? min(1.0, totalDistance / Double(comparisons)) : 0
    }

    private func calculateColorDistance(_ color1: NSColor, _ color2: NSColor) -> Double {
        guard let rgb1 = color1.usingColorSpace(.deviceRGB),
              let rgb2 = color2.usingColorSpace(.deviceRGB) else { return 0 }

        let dr = rgb1.redComponent - rgb2.redComponent
        let dg = rgb1.greenComponent - rgb2.greenComponent
        let db = rgb1.blueComponent - rgb2.blueComponent

        return sqrt(dr * dr + dg * dg + db * db)
    }

    private func calculatePopulationDistribution(_ colors: [ExtractedColor]) -> Double {
        let populations = colors.map(\.population).sorted(by: >)
        guard !populations.isEmpty else { return 0 }

        // Ideal distribution would be more even
        let entropy = populations.reduce(0) { entropy, population in
            population > 0 ? entropy - population * log2(population) : entropy
        }

        let maxEntropy = log2(Double(populations.count))
        return maxEntropy > 0 ? entropy / maxEntropy : 0
    }

    private func generateAccessibilityInfo(for colors: [ExtractedColor]) -> AccessibilityInfo {
        var contrastPairs: [ContrastPair] = []

        for i in 0 ..< colors.count {
            for j in (i + 1) ..< colors.count {
                let ratio = calculateContrastRatio(colors[i].color, colors[j].color)
                contrastPairs.append(ContrastPair(
                    color1: colors[i].color,
                    color2: colors[j].color,
                    ratio: ratio,
                    wcagAA: ratio >= 4.5,
                    wcagAAA: ratio >= 7.0))
            }
        }

        let overallCompliance = contrastPairs.contains { $0.wcagAA }
        let recommendations = generateAccessibilityRecommendations(for: contrastPairs)

        return AccessibilityInfo(
            contrastPairs: contrastPairs,
            overallCompliance: overallCompliance,
            recommendations: recommendations)
    }

    private func calculateContrastRatio(_ color1: NSColor, _ color2: NSColor) -> Double {
        let luminance1 = calculateRelativeLuminance(color1)
        let luminance2 = calculateRelativeLuminance(color2)

        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    private func calculateRelativeLuminance(_ color: NSColor) -> Double {
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

    private func generateAccessibilityRecommendations(for contrastPairs: [ContrastPair]) -> [String] {
        var recommendations: [String] = []

        let failingPairs = contrastPairs.filter { !$0.wcagAA }
        if !failingPairs.isEmpty {
            recommendations
                .append(
                    "Consider adjusting colors for better contrast - \(failingPairs.count) color pairs don't meet WCAG AA standards")
        }

        let aaaCompliantPairs = contrastPairs.filter(\.wcagAAA)
        if aaaCompliantPairs.count == contrastPairs.count {
            recommendations.append("Excellent! All color combinations meet WCAG AAA standards")
        }

        return recommendations
    }
}

// MARK: - Supporting Types

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

struct ColorExtractionResult {
    let colors: [ExtractedColor]
    let algorithm: ColorExtractionAlgorithm
    let qualityScore: Double
    let processingTimeMs: Double
    let metadata: ExtractionMetadata
    let accessibilityInfo: AccessibilityInfo?
}

struct ExtractionMetadata {
    let algorithm: ColorExtractionAlgorithm
    let imageSize: CGSize
    let colorCount: Int
    let parameters: [String: Any]
}

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

struct ColorCluster {
    let centroid: SIMD3<Float>
    let points: [SIMD3<Float>]
    let inertia: Float
}

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

extension SIMD3 where Scalar == Float {
    var r: Float { x }
    var g: Float { y }
    var b: Float { z }
}
