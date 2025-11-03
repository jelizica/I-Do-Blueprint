//
//  MultiAvatarService.swift
//  I Do Blueprint
//
//  Actor-based service for generating guest avatars using Multiavatar API
//

import Foundation
import AppKit

/// Service for generating guest avatars using Multiavatar API
/// Generates unique, multicultural avatars from any string identifier
actor MultiAvatarService {
    static let shared = MultiAvatarService()

    private let baseURL = "https://api.multiavatar.com"
    private let cache = NSCache<NSString, NSImage>()
    private let logger = AppLogger.network

    private init() {
        // Configure cache limits
        cache.countLimit = 100 // Max 100 avatars in memory
        cache.totalCostLimit = 5_000_000 // ~5MB
    }

    // MARK: - Public Types

    enum AvatarFormat {
        case svg
        case png
    }

    enum AvatarError: Error, LocalizedError {
        case invalidURL
        case networkError(underlying: Error)
        case invalidImageData
        case apiRateLimitExceeded

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid avatar URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidImageData:
                return "Failed to decode avatar image"
            case .apiRateLimitExceeded:
                return "Avatar API rate limit exceeded"
            }
        }
    }

    // MARK: - Public Interface

    /// Generate avatar for a guest using their identifier
    /// - Parameters:
    ///   - identifier: Unique identifier (typically guest UUID)
    ///   - format: Image format (PNG or SVG)
    ///   - size: Desired image size
    /// - Returns: NSImage of the avatar
    /// - Throws: AvatarError if fetch fails
    func fetchAvatar(
        for identifier: String,
        format: AvatarFormat = .png,
        size: CGSize = CGSize(width: 100, height: 100)
    ) async throws -> NSImage {
        // Check cache first
        let cacheKey = "\(identifier)_\(format)_\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            logger.info("Cache hit: avatar for \(identifier)")
            return cached
        }

        logger.info("Cache miss: fetching avatar for \(identifier)")

        // Fetch from API
        let image = try await fetchFromAPI(identifier: identifier, format: format)

        // Resize if needed
        let resized = resize(image: image, to: size)

        // Cache the result
        cache.setObject(resized, forKey: cacheKey)

        return resized
    }

    /// Get avatar URL without fetching
    /// - Parameters:
    ///   - identifier: Unique identifier
    ///   - format: Image format
    /// - Returns: URL for the avatar
    func avatarURL(for identifier: String, format: AvatarFormat = .png) -> URL? {
        let encodedId = identifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? identifier
        let formatSuffix = format == .png ? ".png" : ".svg"
        return URL(string: "\(baseURL)/\(encodedId)\(formatSuffix)")
    }

    /// Clear all cached avatars
    func clearCache() {
        cache.removeAllObjects()
        logger.info("Avatar cache cleared")
    }

    // MARK: - Private Helpers

    private func fetchFromAPI(identifier: String, format: AvatarFormat) async throws -> NSImage {
        guard let url = avatarURL(for: identifier, format: format) else {
            throw AvatarError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Check for rate limiting
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    logger.warning("Avatar API rate limit exceeded")
                    throw AvatarError.apiRateLimitExceeded
                }

                if httpResponse.statusCode >= 400 {
                    logger.error("Avatar API returned error: \(httpResponse.statusCode)")
                    throw AvatarError.networkError(underlying: NSError(
                        domain: "MultiAvatarService",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                    ))
                }
            }

            guard let image = NSImage(data: data) else {
                throw AvatarError.invalidImageData
            }

            logger.info("Fetched avatar for: \(identifier)")
            return image

        } catch let error as AvatarError {
            logger.error("Avatar fetch failed", error: error)
            Task { @MainActor in
                SentryService.shared.captureError(error, context: [
                    "identifier": identifier,
                    "format": "\(format)"
                ])
            }
            throw error
        } catch {
            logger.error("Network error fetching avatar", error: error)
            let avatarError = AvatarError.networkError(underlying: error)
            Task { @MainActor in
                SentryService.shared.captureError(avatarError, context: [
                    "identifier": identifier
                ])
            }
            throw avatarError
        }
    }

    private func resize(image: NSImage, to size: CGSize) -> NSImage {
        let resized = NSImage(size: size)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        resized.unlockFocus()
        return resized
    }
}
