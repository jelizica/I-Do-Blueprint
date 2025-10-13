//
//  SVGImageLoader.swift
//  My Wedding Planning App
//
//  Custom SVG image loader for DiceBear avatars
//  AsyncImage doesn't support SVG on macOS, so we need a custom loader
//

import SwiftUI
import AppKit
import Combine

/// Observable object that loads and caches SVG images from URLs
@MainActor
class SVGImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false
    @Published var error: Error?

    private static var cache: [URL: NSImage] = [:]
    private let logger = AppLogger.ui

    func load(from url: URL) {
        // Check cache first
        if let cachedImage = Self.cache[url] {
            self.image = cachedImage
            return
        }

        isLoading = true
        error = nil

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                // Convert SVG data to NSImage
                if let svgImage = NSImage(data: data) {
                    Self.cache[url] = svgImage
                    await MainActor.run {
                        self.image = svgImage
                        self.isLoading = false
                    }
                } else {
                    throw NSError(domain: "SVGImageLoader", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to create image from SVG data"
                    ])
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    #if DEBUG
                    logger.error("SVG loading failed from URL: \(url.absoluteString)", error: error)
                    #endif
                }
            }
        }
    }
}

/// SwiftUI view that displays an SVG image loaded from a URL
struct SVGImage: View {
    let url: URL?
    @StateObject private var loader = SVGImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
            } else if loader.isLoading {
                ProgressView()
            } else {
                // Error or no URL
                Color.clear
            }
        }
        .onAppear {
            if let url = url {
                loader.load(from: url)
            }
        }
    }
}

/// Avatar view with SVG support, fallback, and proper styling
struct SVGAvatarView<Fallback: View>: View {
    let url: URL?
    let size: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    @Binding var isHovering: Bool
    let fallbackView: Fallback
    let guestName: String

    @StateObject private var loader = SVGImageLoader()
    private let logger = AppLogger.ui

    var body: some View {
        Group {
            if let image = loader.image {
                // Successfully loaded DiceBear avatar
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    }
                    .shadow(
                        color: isHovering ? .black.opacity(0.2) : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            } else if loader.isLoading {
                // Loading state
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
            } else {
                // Error or no URL - show fallback
                fallbackView
                    .onAppear {
                        if let error = loader.error {
                            #if DEBUG
                            if let url = url {
                                logger.warning("DiceBear avatar failed to load for \(guestName) from URL: \(url.absoluteString) - \(error.localizedDescription)")
                            } else {
                                logger.warning("DiceBear avatar failed to load for \(guestName): \(error.localizedDescription)")
                            }
                            #endif
                        }
                    }
            }
        }
        .onAppear {
            if let url = url {
                loader.load(from: url)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
