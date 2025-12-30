//
//  SettingsLoadingService.swift
//  I Do Blueprint
//
//  Handles settings loading with timeout and retry logic
//

import Foundation
import Sentry

actor SettingsLoadingService {
    private let repository: any SettingsRepositoryProtocol
    
    init(repository: any SettingsRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadSettings() async throws -> CoupleSettings {
        try await repository.fetchSettings()
    }
    
    func loadCategoriesWithRetry() async -> [CustomVendorCategory] {
        let startTime = Date()
        
        do {
            let categories = try await withTimeout(seconds: 10) {
                try await self.repository.fetchCustomVendorCategories()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            await MainActor.run {
                AppLogger.ui.info("SettingsLoadingService: Categories loaded (\(categories.count)) in \(String(format: "%.2f", duration))s")
            }
            
            await PerformanceMonitor.shared.recordOperation("settings.categories.loaded", duration: duration)
            
            await MainActor.run {
                SentryService.shared.addBreadcrumb(
                    message: categories.isEmpty ? "settings.categories.none" : "settings.categories.loaded",
                    category: "settings",
                    data: categories.isEmpty ? ["duration_ms": Int(duration * 1000)] : ["count": categories.count, "duration_ms": Int(duration * 1000)]
                )
            }
            
            return categories
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            await MainActor.run {
                AppLogger.ui.warning("SettingsLoadingService: Categories timeout/failure after \(String(format: "%.2f", duration))s")
                
                SentryService.shared.addBreadcrumb(
                    message: "settings.categories.timeout",
                    category: "settings",
                    data: ["duration_ms": Int(duration * 1000)]
                )
            }
            
            // Retry once after a short delay
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                let retried = try await repository.fetchCustomVendorCategories()
                let totalDuration = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    AppLogger.ui.info("SettingsLoadingService: Categories loaded on retry (\(retried.count)) in \(String(format: "%.2f", totalDuration))s")
                    
                    SentryService.shared.addBreadcrumb(
                        message: retried.isEmpty ? "settings.categories.none" : "settings.categories.retry_success",
                        category: "settings",
                        data: retried.isEmpty ? ["duration_ms": Int(totalDuration * 1000)] : ["count": retried.count, "duration_ms": Int(totalDuration * 1000)]
                    )
                }
                
                return retried
            } catch {
                await MainActor.run {
                    AppLogger.ui.error("SettingsLoadingService: Categories retry failed", error: error)
                    
                    SentryService.shared.captureMessage(
                        "settings.categories.retry_failed",
                        context: ["error": String(describing: error)],
                        level: .warning
                    )
                }
                
                return []
            }
        }
    }
    
    // MARK: - Timeout Helper
    
    private struct LoadingTimeout: Error {}
    
    private func withTimeout<T>(seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
                throw LoadingTimeout()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
