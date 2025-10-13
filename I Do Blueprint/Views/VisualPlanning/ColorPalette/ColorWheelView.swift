//
//  ColorWheelView.swift
//  My Wedding Planning App
//
//  Interactive color wheel for precise color selection
//

import SwiftUI

struct ColorWheelView: View {
    @Binding var selectedColor: Color
    @State private var dragLocation = CGPoint.zero
    @State private var wheelCenter = CGPoint.zero
    @State private var brightness: Double = 1.0
    @State private var saturation: Double = 1.0

    private let wheelSize: CGFloat = 200

    var body: some View {
        VStack(spacing: 16) {
            // Color wheel
            ZStack {
                // Render HSB color wheel using Canvas for performance
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 5

                    // Draw color wheel by plotting points in polar coordinates
                    for angle in stride(from: 0, to: 360, by: 2) {
                        for radiusStep in stride(from: 0, to: radius, by: 2) {
                            // Map position to HSB color values
                            let hue = Double(angle) / 360.0
                            let saturation = Double(radiusStep) / Double(radius)
                            let color = Color(hue: hue, saturation: saturation, brightness: brightness)

                            // Convert polar to cartesian for drawing
                            let x = center.x + cos(Double(angle) * .pi / 180) * radiusStep
                            let y = center.y + sin(Double(angle) * .pi / 180) * radiusStep

                            context.fill(
                                Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                                with: .color(color))
                        }
                    }
                }
                .frame(width: wheelSize, height: wheelSize)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2))

                // Selection indicator
                Circle()
                    .fill(selectedColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .shadow(color: .black.opacity(0.3), radius: 2))
                    .position(getSelectedPosition())
            }
            .frame(width: wheelSize, height: wheelSize)
            .onAppear {
                wheelCenter = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
                updatePositionFromColor()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragLocation = value.location
                        updateColorFromPosition(value.location)
                    })

            // Brightness slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Brightness")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Slider(value: $brightness, in: 0.1 ... 1.0)
                    .onChange(of: brightness) { _, _ in
                        updateSelectedColor()
                    }
            }

            // Color preview and info
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1))

                Text(selectedColor.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func getSelectedPosition() -> CGPoint {
        // Convert HSB color to polar coordinates for positioning on wheel
        let hsbColor = selectedColor.hsbComponents
        let angle = hsbColor.hue * 2 * .pi
        let radius = hsbColor.saturation * (wheelSize / 2 - 10)

        // Convert polar to cartesian coordinates
        return CGPoint(
            x: wheelCenter.x + cos(angle) * radius,
            y: wheelCenter.y + sin(angle) * radius)
    }

    private func updatePositionFromColor() {
        let hsbColor = selectedColor.hsbComponents
        brightness = hsbColor.brightness
        saturation = hsbColor.saturation

        let angle = hsbColor.hue * 2 * .pi
        let radius = hsbColor.saturation * (wheelSize / 2 - 10)

        dragLocation = CGPoint(
            x: wheelCenter.x + cos(angle) * radius,
            y: wheelCenter.y + sin(angle) * radius)
    }

    private func updateColorFromPosition(_ position: CGPoint) {
        // Calculate distance from wheel center
        let deltaX = position.x - wheelCenter.x
        let deltaY = position.y - wheelCenter.y
        let radius = sqrt(deltaX * deltaX + deltaY * deltaY)
        let maxRadius = wheelSize / 2 - 10

        // Ignore positions outside the wheel boundary
        guard radius <= maxRadius else { return }

        // Convert cartesian coordinates to HSB values
        let angle = atan2(deltaY, deltaX)
        let hue = (angle < 0 ? angle + 2 * .pi : angle) / (2 * .pi) // Normalize to 0-1
        let saturation = min(radius / maxRadius, 1.0)

        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func updateSelectedColor() {
        let hsbColor = selectedColor.hsbComponents
        selectedColor = Color(hue: hsbColor.hue, saturation: hsbColor.saturation, brightness: brightness)
    }
}

// MARK: - Color Extensions

extension Color {
    var hsbComponents: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        let nsColor = NSColor(self)

        // Convert to RGB colorspace first to avoid crashes with dynamic/catalog colors
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            // Fallback to default values if conversion fails
            return (hue: 0, saturation: 0, brightness: 1, alpha: 1)
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        rgbColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return (
            hue: Double(hue),
            saturation: Double(saturation),
            brightness: Double(brightness),
            alpha: Double(alpha))
    }
}

#Preview {
    @State var selectedColor = Color.blue

    return ColorWheelView(selectedColor: $selectedColor)
        .padding()
}
