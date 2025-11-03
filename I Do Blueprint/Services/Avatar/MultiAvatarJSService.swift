//
//  MultiAvatarJSService.swift
//  I Do Blueprint
//
//  JavaScript-based Multiavatar service using JavaScriptCore
//  Generates avatars offline using the official Multiavatar library
//

import Foundation
import AppKit
import JavaScriptCore

/// Service for generating guest avatars using Multiavatar JavaScript library
/// Runs the official Multiavatar JS code via JavaScriptCore for offline avatar generation
actor MultiAvatarJSService {
    static let shared = MultiAvatarJSService()

    private let cache = NSCache<NSString, NSImage>()
    private let logger = AppLogger.network
    private var jsContext: JSContext?

    private init() {
        // Configure cache limits
        cache.countLimit = 100 // Max 100 avatars in memory
        cache.totalCostLimit = 5_000_000 // ~5MB

        // Initialize JavaScript context
        Task {
            await initializeJavaScript()
        }
    }

    // MARK: - Public Types

    enum AvatarError: Error, LocalizedError {
        case javascriptNotInitialized
        case javascriptExecutionFailed(String)
        case svgConversionFailed
        case invalidImageData

        var errorDescription: String? {
            switch self {
            case .javascriptNotInitialized:
                return "JavaScript engine not initialized"
            case .javascriptExecutionFailed(let message):
                return "JavaScript execution failed: \(message)"
            case .svgConversionFailed:
                return "Failed to convert SVG to image"
            case .invalidImageData:
                return "Failed to decode avatar image"
            }
        }
    }

    // MARK: - Public Interface

    /// Generate avatar for a guest using their identifier
    /// - Parameters:
    ///   - identifier: Unique identifier (typically guest name)
    ///   - size: Desired image size
    /// - Returns: NSImage of the avatar
    /// - Throws: AvatarError if generation fails
    func fetchAvatar(
        for identifier: String,
        size: CGSize = CGSize(width: 100, height: 100)
    ) async throws -> NSImage {
        // Check cache first
        let cacheKey = "\(identifier)_\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            logger.info("Cache hit: avatar for \(identifier)")
            return cached
        }

        logger.info("Cache miss: generating avatar for \(identifier)")

        // Generate SVG from JavaScript
        let svgString = try await generateSVG(for: identifier)

        // Convert SVG to NSImage
        let image = try convertSVGToImage(svgString, size: size)

        // Cache the result
        cache.setObject(image, forKey: cacheKey)

        return image
    }

    /// Clear all cached avatars
    func clearCache() {
        cache.removeAllObjects()
        logger.info("Avatar cache cleared")
    }

    // MARK: - Private Helpers

    private func initializeJavaScript() async {
        logger.info("Initializing Multiavatar JavaScript engine...")

        // Create JavaScript context
        guard let context = JSContext() else {
            logger.error("Failed to create JSContext")
            return
        }

        // Set up error handler
        context.exceptionHandler = { context, exception in
            self.logger.error("JavaScript error: \(exception?.toString() ?? "unknown")")
        }

        // Load multiavatar.js from bundle
        guard let jsPath = Bundle.main.path(forResource: "multiavatar.min", ofType: "js"),
              let jsCode = try? String(contentsOfFile: jsPath, encoding: .utf8) else {
            logger.error("Failed to load multiavatar.min.js from bundle")
            return
        }

        // Execute the JavaScript code
        context.evaluateScript(jsCode)

        // Verify multiavatar function exists
        if context.objectForKeyedSubscript("multiavatar").isUndefined {
            logger.error("multiavatar function not found in JavaScript context")
            return
        }

        self.jsContext = context
        logger.info("Multiavatar JavaScript engine initialized successfully")
    }

    private func generateSVG(for identifier: String) async throws -> String {
        // Wait for JavaScript engine to initialize if needed
        var attempts = 0
        while jsContext == nil && attempts < 50 {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            attempts += 1
        }

        guard let context = jsContext else {
            throw AvatarError.javascriptNotInitialized
        }

        // Call multiavatar function
        guard let multiavatar = context.objectForKeyedSubscript("multiavatar"),
              let result = multiavatar.call(withArguments: [identifier]),
              let svgString = result.toString() else {
            throw AvatarError.javascriptExecutionFailed("Failed to call multiavatar function")
        }

        logger.debug("Generated SVG for \(identifier) (\(svgString.count) bytes)")
        return svgString
    }

    private func convertSVGToImage(_ svgString: String, size: CGSize) throws -> NSImage {
        // Convert SVG string to Data
        guard let svgData = svgString.data(using: .utf8) else {
            throw AvatarError.svgConversionFailed
        }

        // Create NSImage from SVG data
        guard let image = NSImage(data: svgData) else {
            throw AvatarError.invalidImageData
        }

        // Resize to desired size
        let resized = NSImage(size: size)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        resized.unlockFocus()

        return resized
    }
}
