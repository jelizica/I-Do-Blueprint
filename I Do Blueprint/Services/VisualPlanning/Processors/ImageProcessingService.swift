//
//  ImageProcessingService.swift
//  I Do Blueprint
//
//  Image processing and pixel sampling service
//

import AppKit
import CoreImage
import Foundation

/// Protocol for image processing operations
protocol ImageProcessingProtocol {
    func convertToCIImage(_ nsImage: NSImage) -> CIImage?
    func extractHistogramData(from histogramImage: CIImage) throws -> [SIMD4<Float>]
    func samplePixels(from ciImage: CIImage, sampleCount: Int) throws -> [SIMD3<Float>]
}

/// Actor responsible for thread-safe image processing operations
actor ImageProcessingService: ImageProcessingProtocol {
    
    // Shared CIContext for optimal performance (Apple best practice)
    private let ciContext = CIContext()
    
    // MARK: - Image Conversion
    
    func convertToCIImage(_ nsImage: NSImage) -> CIImage? {
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        let ciImage = CIImage(bitmapImageRep: bitmap)
        return ciImage
    }
    
    // MARK: - Histogram Extraction
    
    func extractHistogramData(from histogramImage: CIImage) throws -> [SIMD4<Float>] {
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
    
    // MARK: - Pixel Sampling
    
    func samplePixels(from ciImage: CIImage, sampleCount: Int) throws -> [SIMD3<Float>] {
        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        // Calculate sampling step
        let totalPixels = width * height
        let step = max(1, totalPixels / sampleCount)

        var pixels: [SIMD3<Float>] = []
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Create a smaller image for sampling (memory optimization)
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

        // Extract RGB components (drop alpha)
        for pixel in pixelData {
            pixels.append(SIMD3<Float>(pixel.x, pixel.y, pixel.z))
        }

        return pixels
    }
}
