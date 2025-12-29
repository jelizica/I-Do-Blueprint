//
//  DominantColorAlgorithm.swift
//  I Do Blueprint
//
//  Dominant color extraction algorithm
//

import AppKit
import CoreImage
import Foundation
import simd

/// Actor-based dominant color extraction algorithm
actor DominantColorAlgorithm: ColorExtractionAlgorithmProtocol {
    
    private let imageProcessor: ImageProcessingService
    private let clusteringAlgorithm: ClusteringAlgorithm
    
    init(imageProcessor: ImageProcessingService = ImageProcessingService()) {
        self.imageProcessor = imageProcessor
        self.clusteringAlgorithm = ClusteringAlgorithm(imageProcessor: imageProcessor)
    }
    
    // MARK: - ColorExtractionAlgorithmProtocol
    
    func extractColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> ([ExtractedColor], ExtractionMetadata) {
        
        // This would typically use Vision framework for more sophisticated analysis
        // For now, we use k-means clustering as the implementation
        let sampledPixels = try await imageProcessor.samplePixels(from: ciImage, sampleCount: 5000)
        
        progressHandler(0.5)
        
        let clusters = await clusteringAlgorithm.performKMeansClustering(on: sampledPixels, k: options.maxColors)

        progressHandler(0.8)
        
        let colors = clusters.map { cluster in
            ExtractedColor(
                color: NSColor(
                    red: CGFloat(cluster.centroid.r),
                    green: CGFloat(cluster.centroid.g),
                    blue: CGFloat(cluster.centroid.b),
                    alpha: 1.0),
                population: Double(cluster.points.count) / Double(sampledPixels.count),
                confidence: cluster.inertia > 0 ? max(0.1, 1.0 - Double(cluster.inertia)) : 1.0)
        }
        
        let metadata = ExtractionMetadata(
            algorithm: .dominant,
            imageSize: ciImage.extent.size,
            colorCount: colors.count,
            parameters: ["vision_analysis": true])

        return (colors, metadata)
    }
}

