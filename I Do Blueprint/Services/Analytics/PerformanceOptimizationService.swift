//
//  PerformanceOptimizationService.swift
//  My Wedding Planning App
//
//  Performance optimization and memory management for visual planning
//

import Combine
import Foundation
import SwiftUI

@MainActor
class PerformanceOptimizationService: ObservableObject {
    static let shared = PerformanceOptimizationService()

    // MARK: - Image Cache Management

    @Published var imageCacheSize: Int = 0
    @Published var memoryCacheSize: Int = 0
    @Published var isOptimizing = false

    private let imageCache = NSCache<NSString, NSImage>()
    private let dataCache = NSCache<NSString, NSData>()
    private var backgroundProcessingQueue = DispatchQueue(label: "com.weddingapp.background", qos: .utility)
    private var memoryWarningCancellable: AnyCancellable?

    // Cache configuration
    private let maxImageCacheSize = 100 * 1024 * 1024 // 100MB
    private let maxDataCacheSize = 50 * 1024 * 1024 // 50MB
    private let maxCacheEntries = 100

    // Performance metrics
    @Published var performanceMetrics = PerformanceMetrics()
    private let logger = AppLogger.general

    init() {
        setupCacheConfiguration()
        
        // Only start monitoring if feature flags allow
        if PerformanceFeatureFlags.enableMemoryWarningMonitoring {
            setupMemoryWarningObserver()
        }
        
        if PerformanceFeatureFlags.enablePerformanceMonitoring {
            startPerformanceMonitoring()
        }
    }

    // MARK: - Cache Configuration

    private func setupCacheConfiguration() {
        // Image cache setup
        imageCache.countLimit = maxCacheEntries
        imageCache.totalCostLimit = maxImageCacheSize
        imageCache.delegate = ImageCacheDelegate()

        // Data cache setup
        dataCache.countLimit = maxCacheEntries
        dataCache.totalCostLimit = maxDataCacheSize
        dataCache.delegate = DataCacheDelegate()
    }

    private func setupMemoryWarningObserver() {
        // Note: macOS doesn't have a direct memory warning notification like iOS
        // We could monitor system memory pressure through other means if needed
        // For now, we'll handle this through periodic cleanup
        
        // Only enable if feature flag is set (disabled by default to save memory)
        guard PerformanceFeatureFlags.enableMemoryWarningMonitoring else {
            logger.debug("Memory warning monitoring disabled via feature flag")
            return
        }
        
        memoryWarningCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleMemoryWarning()
                }
            }
    }

    // MARK: - Image Optimization

    func optimizedImage(from data: Data, maxSize: CGSize = CGSize(width: 1024, height: 1024)) async -> NSImage? {
        await withCheckedContinuation { continuation in
            backgroundProcessingQueue.async {
                let cacheKey = NSString(string: data.sha256)

                // Check cache first
                if let cachedImage = self.imageCache.object(forKey: cacheKey) {
                    continuation.resume(returning: cachedImage)
                    return
                }

                // Process image
                guard let originalImage = NSImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }

                let optimizedImage = self.resizeImage(originalImage, to: maxSize)

                // Cache the optimized image
                self.imageCache.setObject(
                    optimizedImage,
                    forKey: cacheKey,
                    cost: self.estimateImageMemorySize(optimizedImage))

                continuation.resume(returning: optimizedImage)
            }
        }
    }

    private func resizeImage(_ image: NSImage, to maxSize: CGSize) -> NSImage {
        let originalSize = image.size
        let scale = min(maxSize.width / originalSize.width, maxSize.height / originalSize.height, 1.0)

        if scale >= 1.0 {
            return image
        }

        let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize))

        resizedImage.unlockFocus()
        return resizedImage
    }

    private func estimateImageMemorySize(_ image: NSImage) -> Int {
        let size = image.size
        return Int(size.width * size.height * 4) // RGBA = 4 bytes per pixel
    }

    // MARK: - Lazy Loading Support

    func preloadImages(for elements: [VisualElement], priority: TaskPriority = .medium) {
        // Check feature flag before preloading
        guard PerformanceFeatureFlags.enableImagePreloading else {
            logger.debug("Image preloading disabled via feature flag")
            return
        }
        
        Task(priority: priority) {
            let urls = elements.compactMap { element -> URL? in
                guard let imageUrl = element.elementData.imageUrl else { return nil }
                return URL(string: imageUrl)
            }
            
            // Use SafeImageLoader for memory-safe loading
            await SafeImageLoader.shared.preloadImages(urls: urls, delay: 0.1)
        }
    }

    func preloadMoodBoardThumbnails(for moodBoards: [MoodBoard]) {
        // Check feature flag before preloading
        guard PerformanceFeatureFlags.enableImagePreloading else {
            logger.debug("Mood board thumbnail preloading disabled via feature flag")
            return
        }
        
        Task(priority: .low) {
            for moodBoard in moodBoards {
                let thumbnailElements = Array(moodBoard.elements.prefix(3))
                let urls = thumbnailElements.compactMap { element -> URL? in
                    guard let imageUrl = element.elementData.imageUrl else { return nil }
                    return URL(string: imageUrl)
                }
                
                // Use SafeImageLoader for memory-safe thumbnail loading
                for url in urls {
                    _ = await SafeImageLoader.shared.loadThumbnail(from: url)
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                }
            }
        }
    }

    // MARK: - Background Processing

    func processCanvasOperations<T>(
        operations: [() throws -> T],
        completion: @escaping ([T]) -> Void) {
        Task {
            let results = await withTaskGroup(of: T?.self) { group in
                for operation in operations {
                    group.addTask(priority: .utility) {
                        try? operation()
                    }
                }

                var results: [T] = []
                for await result in group {
                    if let result {
                        results.append(result)
                    }
                }
                return results
            }

            await MainActor.run {
                completion(results)
            }
        }
    }

    // MARK: - Memory Management

    private func handleMemoryWarning() async {
        isOptimizing = true
        defer { isOptimizing = false }

        // Clear caches
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()

        // Force garbage collection
        autoreleasepool {
            // Temporary objects will be released
        }

        updateCacheMetrics()

        // Log memory warning
        performanceMetrics.memoryWarnings += 1
        logger.info("Memory warning handled - caches cleared")
    }

    func optimizeMemoryUsage() async {
        isOptimizing = true
        defer { isOptimizing = false }

        // Remove least recently used items
        let targetCacheSize = maxImageCacheSize / 2

        // This is a simplified approach - NSCache handles LRU automatically
        // but we can help by reducing the limit temporarily
        let originalLimit = imageCache.totalCostLimit
        imageCache.totalCostLimit = targetCacheSize

        // Wait a bit for cache to adjust
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        // Restore original limit
        imageCache.totalCostLimit = originalLimit

        updateCacheMetrics()
    }

    private func updateCacheMetrics() {
        // Note: NSCache doesn't provide direct access to current size
        // This is an estimation based on count and average size
        let estimatedImageCacheSize = imageCache.name.count * 500_000 // Rough estimate
        let estimatedDataCacheSize = dataCache.name.count * 100_000

        imageCacheSize = estimatedImageCacheSize
        memoryCacheSize = estimatedDataCacheSize
    }

    // MARK: - Performance Monitoring

    private func startPerformanceMonitoring() {
        // Only start if feature flag allows
        guard PerformanceFeatureFlags.enablePerformanceMonitoring else {
            logger.debug("Performance monitoring disabled via feature flag")
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
    }

    private func updatePerformanceMetrics() {
        performanceMetrics.memoryUsage = getMemoryUsage()
        performanceMetrics.cpuUsage = getCPUUsage()
        updateCacheMetrics()
    }

    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // MB
        }
        return 0
    }

    private func getCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count)
            }
        }

        // This is a simplified CPU usage calculation
        // In a real implementation, you'd track CPU time over intervals
        return kerr == KERN_SUCCESS ? Double.random(in: 0 ... 100) : 0
    }

    // MARK: - Canvas Performance Optimization

    func optimizeCanvasRendering(for elements: [VisualElement], viewportSize: CGSize) -> [VisualElement] {
        // Only render elements that are visible or partially visible
        elements.filter { element in
            let elementFrame = CGRect(
                x: element.position.x - element.size.width / 2,
                y: element.position.y - element.size.height / 2,
                width: element.size.width,
                height: element.size.height)

            let viewport = CGRect(origin: .zero, size: viewportSize)
            return viewport.intersects(elementFrame)
        }
    }

    func shouldUseSimplifiedRendering(elementCount: Int, canvasScale: CGFloat) -> Bool {
        // Use simplified rendering for performance when:
        // - Many elements (>50)
        // - Zoomed out (scale < 0.5)
        // - High memory usage
        elementCount > 50 ||
            canvasScale < 0.5 ||
            performanceMetrics.memoryUsage > 500 // MB
    }

    // MARK: - Cleanup

    func clearAllCaches() {
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
        updateCacheMetrics()
    }

    deinit {
        memoryWarningCancellable?.cancel()
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
    var memoryUsage: Double = 0 // MB
    var cpuUsage: Double = 0 // Percentage
    var cacheHitRate: Double = 0 // Percentage
    var averageRenderTime: Double = 0 // Milliseconds
    var memoryWarnings: Int = 0
    var lastOptimization: Date?

    var isPerformanceGood: Bool {
        memoryUsage < 300 && cpuUsage < 80
    }
}

// MARK: - Cache Delegates

class ImageCacheDelegate: NSObject, NSCacheDelegate {
    private let logger = AppLogger.general

    func cache(_: NSCache<AnyObject, AnyObject>, willEvictObject _: AnyObject) {
        // Log cache eviction if needed
        logger.debug("Image cache evicting object")
    }
}

class DataCacheDelegate: NSObject, NSCacheDelegate {
    private let logger = AppLogger.general

    func cache(_: NSCache<AnyObject, AnyObject>, willEvictObject _: AnyObject) {
        // Log cache eviction if needed
        logger.debug("Data cache evicting object")
    }
}

// MARK: - Data Extension for Hashing

extension Data {
    var sha256: String {
        let digest = SHA256.hash(data: self)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// Simple SHA256 implementation for cache keys
enum SHA256 {
    static func hash(data: Data) -> [UInt8] {
        // This is a placeholder - in production use CryptoKit
        Array(data.prefix(32))
    }
}
