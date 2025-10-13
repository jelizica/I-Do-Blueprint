//
//  CurvedTextView.swift
//  My Wedding Planning App
//
//  Curved text around a circle for dramatic effect in seating charts
//

import SwiftUI

/// Displays text curved along an arc above the avatar
struct CurvedTextView: View {
    let text: String
    let radius: CGFloat
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let color: Color

    init(
        text: String,
        radius: CGFloat,
        fontSize: CGFloat = 10,
        fontWeight: Font.Weight = .medium,
        color: Color = .primary
    ) {
        self.text = text
        self.radius = radius
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
    }

    var body: some View {
        Canvas { context, size in
            let letters = Array(text)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Calculate total arc length needed
            let charCount = CGFloat(letters.count)
            let anglePerChar = .pi / max(charCount * 1.2, 8) // Spread across ~150 degrees

            // Start angle (top of circle, going left)
            let startAngle = -.pi / 2 - (anglePerChar * charCount / 2)

            for (index, letter) in letters.enumerated() {
                let angle = startAngle + anglePerChar * CGFloat(index)

                // Position for this character
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)

                // Rotation for this character (perpendicular to radius)
                let rotation = angle + .pi / 2

                // Draw the character
                var textContext = context
                textContext.translateBy(x: x, y: y)
                textContext.rotate(by: Angle(radians: rotation))

                let charText = Text(String(letter))
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(color)

                textContext.draw(charText, at: .zero, anchor: .center)
            }
        }
        .frame(width: radius * 2.2, height: radius * 2.2)
    }
}

/// Two-line curved text view for first and last names
struct CurvedNamesView: View {
    let firstName: String
    let lastName: String
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            // First name on outer arc
            CurvedTextView(
                text: firstName,
                radius: radius + size * 0.35,
                fontSize: max(8, size * 0.22),
                fontWeight: .semibold,
                color: .primary
            )

            // Last name on inner arc (closer to avatar)
            CurvedTextView(
                text: lastName,
                radius: radius + size * 0.15,
                fontSize: max(7, size * 0.18),
                fontWeight: .regular,
                color: .secondary
            )
        }
        .frame(width: radius * 2.5, height: radius * 2.5)
    }
}
