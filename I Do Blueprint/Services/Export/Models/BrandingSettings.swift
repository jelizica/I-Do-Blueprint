//
//  BrandingSettings.swift
//  I Do Blueprint
//
//  Data models for branding and customization settings
//

import Foundation
import SwiftUI

// MARK: - Branding Settings

struct BrandingSettings: Codable {
    var companyName: String = ""
    var companyLogo: String? // Base64 encoded image
    private var primaryColorHex: String = "#007AFF" // .blue
    private var secondaryColorHex: String = "#8E8E93" // .gray
    private var backgroundColorHex: String = "#FFFFFF" // .white
    private var textColorHex: String = "#000000" // .black
    var fontFamily: String = "System"
    var watermarkText: String = ""
    var watermarkOpacity: Double = 0.1
    var includeWatermark: Bool = false
    var footerText: String = ""
    var contactInfo: ContactInfo = .init()

    // MARK: - Color Computed Properties

    var primaryColor: Color {
        get { Color.fromHex(primaryColorHex) }
        set { primaryColorHex = newValue.hexString }
    }

    var secondaryColor: Color {
        get { Color.fromHex(secondaryColorHex) }
        set { secondaryColorHex = newValue.hexString }
    }

    var backgroundColor: Color {
        get { Color.fromHex(backgroundColorHex) }
        set { backgroundColorHex = newValue.hexString }
    }

    var textColor: Color {
        get { Color.fromHex(textColorHex) }
        set { textColorHex = newValue.hexString }
    }

    enum CodingKeys: String, CodingKey {
        case companyName
        case companyLogo
        case primaryColorHex = "primaryColor"
        case secondaryColorHex = "secondaryColor"
        case backgroundColorHex = "backgroundColor"
        case textColorHex = "textColor"
        case fontFamily
        case watermarkText
        case watermarkOpacity
        case includeWatermark
        case footerText
        case contactInfo
    }
}

// MARK: - Contact Info

struct ContactInfo: Codable {
    var email: String = ""
    var phone: String = ""
    var website: String = ""
    var address: String = ""
}
