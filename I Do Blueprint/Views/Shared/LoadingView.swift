//
//  LoadingView.swift
//  My Wedding Planning App
//
//  Reusable loading view with Lottie animation
//

import Lottie
import SwiftUI

/// Beautiful loading view with Lottie animation
struct LoadingView: View {
    let message: String
    let size: CGSize

    init(message: String = "Loading...", size: CGSize = CGSize(width: 150, height: 150)) {
        self.message = message
        self.size = size
    }

    var body: some View {
        VStack(spacing: 16) {
            LottieAnimationView(
                type: .loading,
                loopMode: .loop,
                size: size)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

/// Inline loading indicator for smaller spaces
struct InlineLoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        HStack(spacing: 12) {
            LottieAnimationView(
                type: .loading,
                loopMode: .loop,
                size: CGSize(width: 30, height: 30))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingView(message: "Loading guests...")

        InlineLoadingView(message: "Saving...")
    }
    .padding()
}
