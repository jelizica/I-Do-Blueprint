//
//  HapticFeedback.swift
//  I Do Blueprint
//
//  Haptic feedback utilities for macOS
//

import AppKit

enum HapticFeedback {
    // MARK: - Feedback Types

    /// Light impact feedback for subtle interactions
    static func light() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .default
        )
    }

    /// Medium impact feedback for standard interactions
    static func medium() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
    }

    /// Heavy impact feedback for significant actions
    static func heavy() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .default
        )
    }

    /// Success feedback for completed actions
    static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
    }

    /// Warning feedback for cautionary actions
    static func warning() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .default
        )
    }

    /// Error feedback for failed actions
    static func error() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .default
        )
    }

    // MARK: - Contextual Feedback

    /// Button tap feedback
    static func buttonTap() {
        light()
    }

    /// Selection change feedback
    static func selectionChanged() {
        light()
    }

    /// Item added feedback
    static func itemAdded() {
        success()
    }

    /// Item deleted feedback
    static func itemDeleted() {
        medium()
    }

    /// Toggle switched feedback
    static func toggleSwitched() {
        light()
    }
}
