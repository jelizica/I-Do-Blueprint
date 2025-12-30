//
//  Animations.swift
//  I Do Blueprint
//
//  Animation styles for consistent motion and transitions
//

import SwiftUI

// MARK: - Animation

public enum AnimationStyle {
    public static let fast = Animation.easeInOut(duration: 0.15)
    public static let medium = Animation.easeInOut(duration: 0.25)
    public static let slow = Animation.easeInOut(duration: 0.35)
    public static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
