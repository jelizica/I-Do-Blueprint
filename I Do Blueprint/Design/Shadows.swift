//
//  Shadows.swift
//  I Do Blueprint
//
//  Shadow styles for consistent elevation and depth
//

import SwiftUI

// MARK: - Shadows

public enum ShadowStyle {
    case none
    case light
    case medium
    case heavy

    public var radius: CGFloat {
        switch self {
        case .none: return 0
        case .light: return 3
        case .medium: return 6
        case .heavy: return 10
        }
    }

    public var offset: CGSize {
        switch self {
        case .none: return .zero
        case .light: return CGSize(width: 0, height: 2)
        case .medium: return CGSize(width: 0, height: 4)
        case .heavy: return CGSize(width: 0, height: 6)
        }
    }

    public var color: Color {
        switch self {
        case .none: return .clear
        case .light: return AppColors.shadowLight
        case .medium: return AppColors.shadowMedium
        case .heavy: return AppColors.shadowHeavy
        }
    }
}
