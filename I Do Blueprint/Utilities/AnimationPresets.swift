//
//  AnimationPresets.swift
//  I Do Blueprint
//
//  Reusable animation configurations for micro-interactions
//

import SwiftUI

enum AnimationPresets {
    // MARK: - Spring Animations

    /// Gentle spring for subtle interactions
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Bouncy spring for playful interactions
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Quick spring for responsive feel
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    // MARK: - Ease Animations

    /// Fast easeOut for quick state changes
    static let fastEase = Animation.easeOut(duration: 0.2)

    /// Medium easeInOut for balanced transitions
    static let mediumEase = Animation.easeInOut(duration: 0.3)

    /// Slow easeIn for deliberate transitions
    static let slowEase = Animation.easeIn(duration: 0.4)

    // MARK: - Timing Curves

    /// Smooth cubic bezier for natural motion
    static let smooth = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)

    /// Snappy cubic bezier for energetic feel
    static let snappy = Animation.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.25)

    // MARK: - Success Animations

    /// Celebration animation for completed actions
    static let success = Animation.spring(response: 0.6, dampingFraction: 0.5)

    /// Scale in animation for appearing elements
    static let scaleIn = Animation.spring(response: 0.4, dampingFraction: 0.75)

    // MARK: - Hover Animations

    /// Quick response for hover states
    static let hover = Animation.easeOut(duration: 0.15)
}

// MARK: - View Modifiers

struct ScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(AnimationPresets.quickSpring, value: configuration.isPressed)
    }
}

struct HoverScaleEffect: ViewModifier {
    @State private var isHovering = false
    var scaleAmount: CGFloat = 1.05

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scaleAmount : 1.0)
            .animation(AnimationPresets.hover, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    var minScale: CGFloat = 0.95
    var maxScale: CGFloat = 1.05

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a scale effect on button press
    func scaleButtonStyle(scaleAmount: CGFloat = 0.95) -> some View {
        buttonStyle(ScaleButtonStyle(scaleAmount: scaleAmount))
    }

    /// Adds a subtle scale effect on hover
    func hoverScale(amount: CGFloat = 1.05) -> some View {
        modifier(HoverScaleEffect(scaleAmount: amount))
    }

    /// Adds a continuous pulse animation
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) -> some View {
        modifier(PulseEffect(minScale: minScale, maxScale: maxScale))
    }
}
