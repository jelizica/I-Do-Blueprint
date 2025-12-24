//
//  Color+Hex.swift
//  I Do Blueprint
//
//  Created on 2025-12-24.
//

import SwiftUI

extension Color {
    /// Creates a Color from a hex string
    /// - Parameter hex: The hex string (e.g., "#FF5733" or "FF5733")
    /// - Returns: A Color instance, or nil if the hex string is invalid
    static func fromHexString(_ hex: String) -> Color? {
        return Color(hex: hex)
    }
}
