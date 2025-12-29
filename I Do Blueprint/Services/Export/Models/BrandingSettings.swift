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
    var primaryColor: Color = .blue
    var secondaryColor: Color = .gray
    var backgroundColor: Color = .white
    var textColor: Color = .black
    var fontFamily: String = "System"
    var watermarkText: String = ""
    var watermarkOpacity: Double = 0.1
    var includeWatermark: Bool = false
    var footerText: String = ""
    var contactInfo: ContactInfo = .init()
}

// MARK: - Contact Info

struct ContactInfo: Codable {
    var email: String = ""
    var phone: String = ""
    var website: String = ""
    var address: String = ""
}
