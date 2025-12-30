//
//  Gradients.swift
//  I Do Blueprint
//
//  Gradient definitions for the application
//

import SwiftUI

// MARK: - Gradients

enum AppGradients {
    /// App-wide background gradient used on the dashboard background
    static let appBackground = LinearGradient(
        colors: [
            Color.fromHex("F8F9FA"),
            Color.fromHex("E9ECEF")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Dashboard header gradient: light purple → eucalyptus green
    static let dashboardHeader = LinearGradient(
        colors: [
            Color.fromHex("EAE2FF"), // light purple
            Color.fromHex("5A9070")  // eucalyptus green (from AppColors.Dashboard.eventAction)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
