//
//  ClusteringAlgorithm.swift
//  I Do Blueprint
//
//  K-means clustering algorithm for color extraction
//

import AppKit
import CoreImage
import Foundation
import simd

/// Actor-based k-means clustering algorithm with SIMD optimization
actor ClusteringAlgorithm: ColorExtractionAlgorithmProtocol {
    
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

        // Sample pixels from the image
        let sampledPixels = try await imageProcessor.samplePixels(from: ciImage, sampleCount: 10000)

        progressHandler(0.5)

        // Perform k-means clustering
        let clusters = performKMeansClustering(on: sampledPixels, k: options.maxColors)

        progressHandler(0.7)

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
    
    // MARK: - K-Means Clustering (SIMD-optimized)
    
    func performKMeansClustering(on pixels: [SIMD3<Float>], k: Int) -> [ColorCluster] {
        guard !pixels.isEmpty, k > 0 else { return [] }

        // Initialize centroids randomly
        var centroids = (0 ..< k).map { _ in
            pixels.randomElement() ?? SIMD3<Float>(0.5, 0.5, 0.5)
        }

        var clusters = [ColorCluster]()
        let maxIterations = 50
        var assignments = Array(repeating: [SIMD3<Float>](), count: k)

        for _ in 0 ..< maxIterations {
            // Assign points to nearest centroid (SIMD-optimized distance)
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
}
