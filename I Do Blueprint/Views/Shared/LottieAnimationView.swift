//
//  LottieAnimationView.swift
//  My Wedding Planning App
//
//  Created by Claude Code
//

import Lottie
import SwiftUI

/// A reusable Lottie animation view with common wedding planning animations
struct LottieAnimationView: View {
    let animationType: AnimationType
    let loopMode: LottieLoopMode
    let size: CGSize

    enum AnimationType {
        case confetti
        case success
        case loading
        case heart

        var animationName: String {
            switch self {
            case .confetti: "Celebrations Begin"
            case .success: "Check Mark"
            case .loading: "Loading animation"
            case .heart: "Heart"
            }
        }
    }

    init(
        type: AnimationType,
        loopMode: LottieLoopMode = .playOnce,
        size: CGSize = CGSize(width: 200, height: 200)) {
        animationType = type
        self.loopMode = loopMode
        self.size = size
    }

    var body: some View {
        LottieView(animation: .named(animationType.animationName))
            .playing(loopMode: loopMode)
            .animationSpeed(1.0)
            .frame(width: size.width, height: size.height)
    }
}

/// Confetti overlay that can be triggered
struct ConfettiOverlay: View {
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            if isShowing {
                LottieAnimationView(
                    type: .confetti,
                    loopMode: .playOnce,
                    size: CGSize(width: 400, height: 400))
                    .allowsHitTesting(false)
                    .onAppear {
                        // Auto-hide after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            isShowing = false
                        }
                    }
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}

/// Success checkmark animation
struct SuccessAnimationView: View {
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            if isShowing {
                VStack(spacing: 16) {
                    LottieAnimationView(
                        type: .success,
                        loopMode: .playOnce,
                        size: CGSize(width: 150, height: 150))

                    Text("Success!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(Spacing.xxxl)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(radius: 20))
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isShowing)
    }
}

#Preview {
    VStack(spacing: 40) {
        LottieAnimationView(type: .confetti)
        LottieAnimationView(type: .success)
        LottieAnimationView(type: .loading, loopMode: .loop)
    }
    .padding()
}
