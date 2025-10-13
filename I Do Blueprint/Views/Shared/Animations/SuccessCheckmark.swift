//
//  SuccessCheckmark.swift
//  I Do Blueprint
//
//  Animated success checkmark for celebrating completed actions
//

import SwiftUI

struct SuccessCheckmark: View {
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkRotation: Double = -45
    @State private var circleScale: CGFloat = 0
    @State private var showGlow: Bool = false

    var size: CGFloat = 60
    var color: Color = .green

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 20)
                .scaleEffect(showGlow ? 1.2 : 0.8)
                .opacity(showGlow ? 0 : 1)

            // Circle background
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(circleScale)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkmarkScale)
                .rotationEffect(.degrees(checkmarkRotation))
        }
        .onAppear {
            playAnimation()
        }
    }

    private func playAnimation() {
        // Circle appears with bounce
        withAnimation(AnimationPresets.bouncySpring.delay(0.1)) {
            circleScale = 1.0
        }

        // Checkmark appears with rotation and scale
        withAnimation(AnimationPresets.success.delay(0.3)) {
            checkmarkScale = 1.0
            checkmarkRotation = 0
        }

        // Glow pulse
        withAnimation(Animation.easeOut(duration: 0.6).delay(0.4)) {
            showGlow = true
        }

        // Trigger haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticFeedback.success()
        }
    }
}

// MARK: - Success Toast Overlay

struct SuccessToast: View {
    let message: String
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: Spacing.md) {
            SuccessCheckmark(size: 40)

            Text(message)
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.green)
                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            // Slide in from top
            withAnimation(AnimationPresets.bouncySpring) {
                offset = 50
                opacity = 1
            }

            // Slide out after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(AnimationPresets.fastEase) {
                    offset = -100
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Shows a success toast overlay with the given message
    func successToast(isPresented: Binding<Bool>, message: String) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                VStack {
                    SuccessToast(message: message)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                isPresented.wrappedValue = false
                            }
                        }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SuccessCheckmark(size: 80, color: .green)

        SuccessCheckmark(size: 60, color: .blue)

        SuccessCheckmark(size: 40, color: .purple)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
}
