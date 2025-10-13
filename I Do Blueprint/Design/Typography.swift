//
//  Typography.swift
//  My Wedding Planning App
//
//  Seating Chart Redesign Typography System
//

import SwiftUI

extension Font {
    // MARK: - Display Fonts (Large Headings)

    static let seatingDisplay = Font.system(size: 32, weight: .bold, design: .rounded)
    static let seatingDisplayLarge = Font.system(size: 40, weight: .bold, design: .rounded)

    // MARK: - Heading Fonts

    static let seatingH1 = Font.system(size: 28, weight: .bold)
    static let seatingH2 = Font.system(size: 24, weight: .semibold)
    static let seatingH3 = Font.system(size: 20, weight: .semibold)
    static let seatingH4 = Font.system(size: 18, weight: .medium)

    // MARK: - Body Fonts

    static let seatingBody = Font.system(size: 15, weight: .regular)
    static let seatingBodyMedium = Font.system(size: 15, weight: .medium)
    static let seatingBodyBold = Font.system(size: 15, weight: .semibold)

    // MARK: - Caption Fonts

    static let seatingCaption = Font.system(size: 13, weight: .regular)
    static let seatingCaptionMedium = Font.system(size: 13, weight: .medium)
    static let seatingCaptionBold = Font.system(size: 13, weight: .semibold)

    // MARK: - Label Fonts

    static let seatingLabel = Font.system(size: 11, weight: .medium)
    static let seatingLabelBold = Font.system(size: 11, weight: .bold)
    static let seatingLabelUppercase = Font.system(size: 10, weight: .bold).uppercaseSmallCaps()

    // MARK: - Table Number Fonts

    static let tableNumber = Font.system(size: 22, weight: .bold, design: .rounded)
    static let tableNumberLarge = Font.system(size: 28, weight: .bold, design: .rounded)

    // MARK: - Stage Label Fonts

    static let stageLabel = Font.system(size: 16, weight: .bold).uppercaseSmallCaps()
    static let stageLabelLarge = Font.system(size: 20, weight: .bold).uppercaseSmallCaps()
}

// MARK: - Text Style Modifiers

extension View {
    func seatingDisplayStyle() -> some View {
        self.font(.seatingDisplay)
            .foregroundColor(.seatingDeepNavy)
    }

    func seatingH1Style() -> some View {
        self.font(.seatingH1)
            .foregroundColor(.primary)
    }

    func seatingH2Style() -> some View {
        self.font(.seatingH2)
            .foregroundColor(.primary)
    }

    func seatingH3Style() -> some View {
        self.font(.seatingH3)
            .foregroundColor(.primary)
    }

    func seatingBodyStyle() -> some View {
        self.font(.seatingBody)
            .foregroundColor(.primary)
    }

    func seatingCaptionStyle() -> some View {
        self.font(.seatingCaption)
            .foregroundColor(.secondary)
    }

    func seatingLabelStyle() -> some View {
        self.font(.seatingLabelUppercase)
            .foregroundColor(.secondary)
            .tracking(0.5)
    }

    func stageLabelStyle(color: Color = .seatingAccentTeal) -> some View {
        self.font(.stageLabel)
            .foregroundColor(color)
            .tracking(1.0)
    }
}
