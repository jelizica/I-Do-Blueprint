//
//  PostOnboardingLoader.swift
//  I Do Blueprint
//
//  Sequences post-onboarding store loads with progress updates.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PostOnboardingLoader: ObservableObject {
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var currentMessage: String = "Preparing..."
    @Published private(set) var isFinished: Bool = false

    private var isCancelled = false

    func start(appStores: AppStores, settingsStore: SettingsStoreV2, onComplete: (() -> Void)? = nil) async {
        isCancelled = false
        isFinished = false
        progress = 0
        currentMessage = "Finalizing setup..."

        let steps: [(String, () async -> Void)] = [
            ("Loading settings...", { await settingsStore.loadSettings(force: true) }),
            ("Loading guests...", { await appStores.guest.loadGuestData() }),
            ("Loading vendors...", { await appStores.vendor.loadVendors() }),
            ("Loading tasks...", { await appStores.task.loadTasks() }),
            ("Loading budget...", { await appStores.budget.loadBudgetData() })
        ]

        let total = Double(steps.count)
        var index = 0.0

        for (message, action) in steps {
            if isCancelled { break }
            currentMessage = message
            await Task.yield()
            await action()
            index += 1
            progress = min(1.0, index / total)
            await Task.yield()
        }

        isFinished = true
        onComplete?()
    }

    func cancel() {
        // Only hides overlay; underlying store loads are short-lived and will complete.
        isCancelled = true
    }
}
