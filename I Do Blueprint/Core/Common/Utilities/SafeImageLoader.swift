//
//  SafeImageLoader.swift
//  I Do Blueprint
//
//  Memory-safe image loading with downsampling and concurrency limits
//

import Foundation
import AppKit
import ImageIO

/// Thread-safe image loader with memory optimization
@MainActor
final class SafeImageLoader {
    static let shared = SafeImageLoader()
    
    private let session: URLSession
    private let semaphore: DispatchSemaphore
    private let logger = AppLogger.general
    
    // Cache for loaded images
    private let imageCache = NSCache<NSString, NSImage>()
    
    private init() {
        // Configure ephemeral session (no disk cache)
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpMaximumConnectionsPerHost = 4
        session = URLSession(configuration: config)
        
        // Limit concurrent image loads based on feature flags
        let maxConcurrent = PerformanceFeatureFlags.maxConcurrentImageLoads
        semaphore = DispatchSemaphore(value: maxConcurrent)
        
        // Configure cache limits
        imageCache.countLimit = 50 // Max 50 images
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB max
        
        logger.debug("SafeImageLoader initialized with max \(maxConcurrent) concurrent loads")
    }
    
    // MARK: - Public API
    
    /// Load and downsample an image from a URL
    /// - Parameters:
    ///   - url: The URL to load from
    ///   - maxSize: Maximum dimensions for the image (default: 1024x1024)
    ///   - useCache: Whether to use the cache (default: true)
    /// - Returns: Downsampled NSImage or nil if loading fails
    func loadImage(from url: URL, maxSize: CGSize = CGSize(width: 1024, height: 1024), useCache: Bool = true) async -> NSImage? {
        // ✅ Validate URL for security first
        do {
            try URLValidator.validate(url)
        } catch {
            logger.warning("Rejected unsafe URL: \(url.absoluteString) - \(error.localizedDescription)")
            return nil
        }
        
        let cacheKey = NSString(string: url.absoluteString)
        
        // Check cache first
        if useCache, let cached = imageCache.object(forKey: cacheKey) {
                        return cached
        }
        
        // Acquire semaphore to limit concurrency
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                self.semaphore.wait()
                defer { self.semaphore.signal() }
                
                // Load and downsample
                if let image = self.loadAndDownsampleSync(url: url, maxSize: maxSize) {
                    // Cache the result
                    if useCache {
                        let cost = self.estimateImageSize(image)
                        self.imageCache.setObject(image, forKey: cacheKey, cost: cost)
                    }
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Load thumbnail version of an image (200x200 max)
    func loadThumbnail(from url: URL) async -> NSImage? {
        await loadImage(from: url, maxSize: CGSize(width: 200, height: 200), useCache: true)
    }
    
    /// Preload multiple images with delay between each
    func preloadImages(urls: [URL], maxSize: CGSize = CGSize(width: 1024, height: 1024), delay: TimeInterval = 0.1) async {
        guard PerformanceFeatureFlags.enableImagePreloading else {
            logger.debug("Image preloading disabled via feature flag")
            return
        }
        
        for url in urls {
            _ = await loadImage(from: url, maxSize: maxSize, useCache: true)
            
            // Add delay to prevent overwhelming the system
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    /// Clear all cached images
    func clearCache() {
        imageCache.removeAllObjects()
        logger.info("Image cache cleared")
    }
    
    // MARK: - Private Implementation
    
    private func loadAndDownsampleSync(url: URL, maxSize: CGSize) -> NSImage? {
        // Try loading from file system first
        if url.isFileURL {
            return downsampleImage(at: url, to: maxSize)
        }
        
        // Load from network
        var data: Data?
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = session.dataTask(with: url) { taskData, response, error in
            if let error = error {
                self.logger.warning("Failed to load image from \(url.lastPathComponent): \(error.localizedDescription)")
            } else if let taskData = taskData {
                data = taskData
            }
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 30)
        
        guard let imageData = data else {
            return nil
        }
        
        // Downsample from data
        return downsampleImage(from: imageData, to: maxSize)
    }
    
    /// Downsample an image from a file URL using ImageIO
    private func downsampleImage(at url: URL, to maxSize: CGSize) -> NSImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxSize.width, maxSize.height)
        ]
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            logger.warning("Failed to downsample image at: \(url.lastPathComponent)")
            return nil
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// Downsample an image from data using ImageIO
    private func downsampleImage(from data: Data, to maxSize: CGSize) -> NSImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxSize.width, maxSize.height)
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            logger.warning("Failed to downsample image from data")
            return nil
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    /// Estimate memory size of an image
    private func estimateImageSize(_ image: NSImage) -> Int {
        let size = image.size
        return Int(size.width * size.height * 4) // RGBA = 4 bytes per pixel
    }
}

// MARK: - Convenience Extensions

extension SafeImageLoader {
    /// Load image from optional URL
    func loadImage(from url: URL?, maxSize: CGSize = CGSize(width: 1024, height: 1024)) async -> NSImage? {
        guard let url = url else { return nil }
        return await loadImage(from: url, maxSize: maxSize)
    }
    
    /// Load image from string URL
    func loadImage(from urlString: String, maxSize: CGSize = CGSize(width: 1024, height: 1024)) async -> NSImage? {
        guard let url = URL(string: urlString) else { return nil }
        return await loadImage(from: url, maxSize: maxSize)
    }
}
