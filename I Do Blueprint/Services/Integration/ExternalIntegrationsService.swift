//
//  ExternalIntegrationsService.swift
//  My Wedding Planning App
//
//  External service integrations for visual planning (Pinterest, Unsplash, vendor APIs)
//

import Combine
import Foundation
import SwiftUI

@MainActor
class ExternalIntegrationsService: ObservableObject {
    static let shared = ExternalIntegrationsService()

    @Published var isConnecting = false
    @Published var connectionStatus: [ServiceType: ConnectionStatus] = [:]
    @Published var lastSyncDate: [ServiceType: Date] = [:]

    private let urlSession = URLSession.shared
    private let performanceService = PerformanceOptimizationService.shared
    private let logger = AppLogger.general
    private let apiKeyManager = SecureAPIKeyManager.shared

    init() {
        initializeConnections()
    }

    // MARK: - Service Management

    private func initializeConnections() {
        for service in ServiceType.allCases {
            connectionStatus[service] = .disconnected
        }
    }

    func connectToService(_ service: ServiceType) async throws {
        isConnecting = true
        connectionStatus[service] = .connecting

        defer { isConnecting = false }

        do {
            switch service {
            case .unsplash:
                try await connectToUnsplash()
            case .pinterest:
                try await connectToPinterest()
            case .vendorMarketplace:
                try await connectToVendorMarketplace()
            case .cloudStorage:
                try await connectToCloudStorage()
            }

            connectionStatus[service] = .connected
            lastSyncDate[service] = Date()
        } catch {
            connectionStatus[service] = .error(error.localizedDescription)
            throw error
        }
    }

    // MARK: - API Key Access (Secure)

    private func getUnsplashAPIKey() -> String? {
        apiKeyManager.getAPIKey(for: .unsplash)
    }

    private func getPinterestAPIKey() -> String? {
        apiKeyManager.getAPIKey(for: .pinterest)
    }

    private func getVendorAPIKey() -> String? {
        apiKeyManager.getAPIKey(for: .vendor)
    }

    // MARK: - Unsplash Integration

    private func connectToUnsplash() async throws {
        guard let apiKey = getUnsplashAPIKey() else {
            throw IntegrationError.apiKeyNotConfigured(service: "Unsplash")
        }

        let testURL = URL(string: "https://api.unsplash.com/me")!
        var request = URLRequest(url: testURL)
        request.setValue("Client-ID \(apiKey)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IntegrationError.connectionFailed("Unsplash authentication failed")
        }
    }

    func searchUnsplashImages(query: String, orientation: ImageOrientation = .any) async throws -> [InspirationImage] {
        guard let apiKey = getUnsplashAPIKey() else {
            throw IntegrationError.apiKeyNotConfigured(service: "Unsplash")
        }

        guard connectionStatus[.unsplash] == .connected else {
            throw IntegrationError.notConnected("Unsplash")
        }

        var urlComponents = URLComponents(string: "https://api.unsplash.com/search/photos")!
        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "20"),
            URLQueryItem(name: "orientation", value: orientation.rawValue)
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Client-ID \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await urlSession.data(for: request)
        let response = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)

        response.results.map { photo in
            InspirationImage(
                id: photo.id,
                url: photo.urls.regular,
                thumbnailUrl: photo.urls.thumb,
                width: photo.width,
                height: photo.height,
                description: photo.description ?? query,
                source: .unsplash,
                photographer: photo.user.name,
                tags: photo.tags?.map(\.title) ?? [])
        }
    }

    func downloadUnsplashImage(image: InspirationImage) async throws -> Data {
        guard let url = URL(string: image.url) else {
            throw IntegrationError.invalidURL
        }

        let (data, _) = try await urlSession.data(from: url)

        // Optimize the downloaded image
        if let optimizedImage = await performanceService.optimizedImage(from: data) {
            return optimizedImage.tiffRepresentation ?? data
        }

        return data
    }

    // MARK: - Pinterest Integration

    private func connectToPinterest() async throws {
        guard let _ = getPinterestAPIKey() else {
            throw IntegrationError.apiKeyNotConfigured(service: "Pinterest")
        }

        // Pinterest OAuth flow would be implemented here
        // For now, simulating connection
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }

    func searchPinterestBoards(query: String) async throws -> [PinterestBoard] {
        guard let _ = getPinterestAPIKey() else {
            throw IntegrationError.apiKeyNotConfigured(service: "Pinterest")
        }

        guard connectionStatus[.pinterest] == .connected else {
            throw IntegrationError.notConnected("Pinterest")
        }

        // Simplified Pinterest API call - in production this would use real Pinterest API
        let mockBoards = [
            PinterestBoard(
                id: "1",
                name: "Wedding Inspiration",
                description: "Beautiful wedding ideas",
                imageCount: 150,
                thumbnailUrl: "https://example.com/thumb1.jpg"),
            PinterestBoard(
                id: "2",
                name: "Color Palettes",
                description: "Wedding color schemes",
                imageCount: 75,
                thumbnailUrl: "https://example.com/thumb2.jpg")
        ]

        mockBoards.filter { board in
            board.name.localizedCaseInsensitiveContains(query) ||
                board.description.localizedCaseInsensitiveContains(query)
        }
    }

    func importPinterestBoard(_ board: PinterestBoard) async throws -> MoodBoard {
        // Convert Pinterest board to mood board
        let moodBoard = MoodBoard(
            tenantId: "default", // This would come from user session
            boardName: "Pinterest: \(board.name)",
            boardDescription: board.description,
            styleCategory: .romantic, // Could be detected from content
            canvasSize: CGSize(width: 800, height: 600),
            backgroundColor: .white)

        // In production, this would fetch actual pins and convert to visual elements
        return moodBoard
    }

    // MARK: - Vendor Marketplace Integration

    private func connectToVendorMarketplace() async throws {
        // Connect to vendor APIs (The Knot, WeddingWire, etc.)
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func searchVendorProducts(category: VendorCategory, style: StyleCategory) async throws -> [VendorProduct] {
        guard connectionStatus[.vendorMarketplace] == .connected else {
            throw IntegrationError.notConnected("Vendor Marketplace")
        }

        // Mock vendor products
        let mockProducts = [
            VendorProduct(
                id: "1",
                name: "Elegant Floral Centerpiece",
                vendor: "Bloom & Blossom",
                category: .floral,
                price: 85.00,
                currency: "USD",
                imageUrl: "https://example.com/centerpiece.jpg",
                description: "Beautiful seasonal floral arrangement",
                styleCompatibility: [.romantic, .classic, .garden]),
            VendorProduct(
                id: "2",
                name: "Modern Table Setting",
                vendor: "Contemporary Events",
                category: .tableware,
                price: 12.50,
                currency: "USD",
                imageUrl: "https://example.com/tablesetting.jpg",
                description: "Sleek modern place setting",
                styleCompatibility: [.modern, .minimalist, .industrial])
        ]

        return mockProducts.filter { product in
            product.category == category && product.styleCompatibility.contains(style)
        }
    }

    func getVendorRecommendations(for moodBoard: MoodBoard) async throws -> [VendorRecommendation] {
        // Analyze mood board and suggest relevant vendors
        let style = moodBoard.styleCategory
        let dominantColors = extractDominantColors(from: moodBoard)

        let recommendations = [
            VendorRecommendation(
                vendor: "Elegant Events Co.",
                category: .planning,
                matchScore: 0.95,
                reason: "Specializes in \(style.displayName) style weddings",
                contactInfo: "contact@elegantevents.com",
                website: "https://elegantevents.com"),
            VendorRecommendation(
                vendor: "Bloom Studios",
                category: .floral,
                matchScore: 0.88,
                reason: "Color palette matches your preferences",
                contactInfo: "hello@bloomstudios.com",
                website: "https://bloomstudios.com")
        ]

        return recommendations
    }

    // MARK: - Cloud Storage Integration

    private func connectToCloudStorage() async throws {
        // Connect to iCloud, Google Drive, Dropbox, etc.
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func syncToCloudStorage(moodBoard: MoodBoard) async throws {
        guard connectionStatus[.cloudStorage] == .connected else {
            throw IntegrationError.notConnected("Cloud Storage")
        }

        // Export mood board to cloud storage
        // In production, this would use CloudKit or other cloud APIs
        logger.info("Syncing mood board '\(moodBoard.boardName)' to cloud storage...")
    }

    func importFromCloudStorage() async throws -> [CloudStorageItem] {
        guard connectionStatus[.cloudStorage] == .connected else {
            throw IntegrationError.notConnected("Cloud Storage")
        }

        // Mock cloud storage items
        return [
            CloudStorageItem(
                id: "1",
                name: "Wedding Inspiration.moodboard",
                type: .moodBoard,
                size: 2_500_000,
                modifiedDate: Date().addingTimeInterval(-86400),
                cloudPath: "/Wedding Planning/Visual/"),
            CloudStorageItem(
                id: "2",
                name: "Color Schemes.palette",
                type: .colorPalette,
                size: 15000,
                modifiedDate: Date().addingTimeInterval(-3600),
                cloudPath: "/Wedding Planning/Colors/")
        ]
    }

    // MARK: - Social Media Sharing

    func shareToSocialMedia(moodBoard: MoodBoard, platform: SocialPlatform) async throws {
        // Generate shareable image
        let shareableImage = try await generateShareableImage(for: moodBoard)

        switch platform {
        case .instagram:
            try await shareToInstagram(image: shareableImage, caption: moodBoard.boardName)
        case .pinterest:
            try await shareToPinterest(image: shareableImage, board: moodBoard)
        case .facebook:
            try await shareToFacebook(image: shareableImage, description: moodBoard.boardDescription ?? "")
        }
    }

    private func generateShareableImage(for _: MoodBoard) async throws -> NSImage {
        // Create a shareable version of the mood board with branding
        // This would use ImageRenderer in production
        NSImage(size: CGSize(width: 1080, height: 1080))
    }

    private func shareToInstagram(image _: NSImage, caption: String) async throws {
        // Instagram sharing implementation
        logger.info("Sharing to Instagram: \(caption)")
    }

    private func shareToPinterest(image _: NSImage, board: MoodBoard) async throws {
        // Pinterest sharing implementation
        logger.info("Creating Pinterest pin for: \(board.boardName)")
    }

    private func shareToFacebook(image _: NSImage, description: String) async throws {
        // Facebook sharing implementation
        logger.info("Sharing to Facebook: \(description)")
    }

    // MARK: - Helper Methods

    private func extractDominantColors(from moodBoard: MoodBoard) -> [Color] {
        var colors: [Color] = []

        for element in moodBoard.elements {
            if let color = element.elementData.color {
                colors.append(color)
            }
        }

        // Remove duplicates and limit to top 5
        return Array(Set(colors)).prefix(5).map { $0 }
    }

    func disconnectFromService(_ service: ServiceType) {
        connectionStatus[service] = .disconnected
        lastSyncDate.removeValue(forKey: service)
    }

    func reconnectAllServices() async {
        for service in ServiceType.allCases {
            if connectionStatus[service] != .connected {
                try? await connectToService(service)
            }
        }
    }
}

// MARK: - Data Models

enum ServiceType: String, CaseIterable {
    case unsplash
    case pinterest
    case vendorMarketplace = "vendor_marketplace"
    case cloudStorage = "cloud_storage"

    var displayName: String {
        switch self {
        case .unsplash: "Unsplash"
        case .pinterest: "Pinterest"
        case .vendorMarketplace: "Vendor Marketplace"
        case .cloudStorage: "Cloud Storage"
        }
    }

    var icon: String {
        switch self {
        case .unsplash: "photo.on.rectangle"
        case .pinterest: "pin"
        case .vendorMarketplace: "bag"
        case .cloudStorage: "icloud"
        }
    }
}

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

enum IntegrationError: LocalizedError {
    case apiKeyNotConfigured(service: String)
    case notConnected(String)
    case connectionFailed(String)
    case invalidURL
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured(let service):
            "\(service) API key not configured. Please add your API key in Settings → API Keys."
        case .notConnected(let service):
            "Not connected to \(service)"
        case .connectionFailed(let reason):
            "Connection failed: \(reason)"
        case .invalidURL:
            "Invalid URL"
        case .quotaExceeded:
            "API quota exceeded"
        }
    }
}

// MARK: - External Data Models

struct InspirationImage {
    let id: String
    let url: String
    let thumbnailUrl: String
    let width: Int
    let height: Int
    let description: String
    let source: ImageSource
    let photographer: String?
    let tags: [String]
}

enum ImageSource {
    case unsplash
    case pinterest
    case custom
}

enum ImageOrientation: String {
    case landscape
    case portrait
    case squarish
    case any = ""
}

struct PinterestBoard {
    let id: String
    let name: String
    let description: String
    let imageCount: Int
    let thumbnailUrl: String
}

struct VendorProduct {
    let id: String
    let name: String
    let vendor: String
    let category: VendorCategory
    let price: Double
    let currency: String
    let imageUrl: String
    let description: String
    let styleCompatibility: [StyleCategory]
}

enum VendorCategory: String, CaseIterable {
    case floral
    case catering
    case photography
    case venue
    case music
    case planning
    case tableware
    case decor

    var displayName: String {
        rawValue.capitalized
    }
}

struct VendorRecommendation {
    let vendor: String
    let category: VendorCategory
    let matchScore: Double
    let reason: String
    let contactInfo: String
    let website: String
}

struct CloudStorageItem {
    let id: String
    let name: String
    let type: CloudItemType
    let size: Int
    let modifiedDate: Date
    let cloudPath: String
}

enum CloudItemType {
    case moodBoard
    case colorPalette
    case seatingChart
    case exportedFile
}

enum SocialPlatform: String, CaseIterable {
    case instagram
    case pinterest
    case facebook

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Unsplash API Models

struct UnsplashSearchResponse: Codable {
    let results: [UnsplashPhoto]
}

struct UnsplashPhoto: Codable {
    let id: String
    let width: Int
    let height: Int
    let description: String?
    let urls: UnsplashURLs
    let user: UnsplashUser
    let tags: [UnsplashTag]?
}

struct UnsplashURLs: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct UnsplashUser: Codable {
    let id: String
    let name: String
    let username: String
}

struct UnsplashTag: Codable {
    let title: String
}
