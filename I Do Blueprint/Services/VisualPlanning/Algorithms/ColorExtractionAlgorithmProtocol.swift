//
//  ColorExtractionAlgorithmProtocol.swift
//  I Do Blueprint
//
//  Protocol for color extraction algorithm implementations
//

import CoreImage
import Foundation

/// Protocol that all color extraction algorithms must implement
protocol ColorExtractionAlgorithmProtocol {
    /// Extract colors from a CIImage using the algorithm's specific approach
    /// - Parameters:
    ///   - ciImage: The Core Image to process
    ///   - options: Extraction options (max colors, quality threshold, etc.)
    ///   - progressHandler: Callback for progress updates (0.0 to 1.0)
    /// - Returns: Tuple of extracted colors and metadata
    func extractColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> ([ExtractedColor], ExtractionMetadata)
}
