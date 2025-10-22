//
//  AppStores.swift
//  I Do Blueprint
//
//  Singleton store instances to prevent memory explosion from duplicate stores
//

import Combine
import Foundation
import SwiftUI

/// Singleton container for all app stores
/// Prevents creating duplicate store instances that each load full datasets
@MainActor
final class AppStores: ObservableObject {
    static let shared = AppStores()
    
    // Store instances - NOT @Published to avoid triggering changes during access
    // Each store is already an ObservableObject, so views will update when store data changes
    private var _budget: BudgetStoreV2?
    private var _guest: GuestStoreV2?
    private var _vendor: VendorStoreV2?
    private var _document: DocumentStoreV2?
    private var _task: TaskStoreV2?
    private var _timeline: TimelineStoreV2?
    private var _notes: NotesStoreV2?
    private var _visualPlanning: VisualPlanningStoreV2?
    private var _settings: SettingsStoreV2?
    
    private let logger = AppLogger.general
    
    // Lazy accessors - create on first access
    var budget: BudgetStoreV2 {
        if _budget == nil {
            logger.debug("Creating BudgetStoreV2")
            _budget = BudgetStoreV2()
        }
        return _budget!
    }
    
    var guest: GuestStoreV2 {
        if _guest == nil {
            logger.debug("Creating GuestStoreV2")
            _guest = GuestStoreV2()
        }
        return _guest!
    }
    
    var vendor: VendorStoreV2 {
        if _vendor == nil {
            logger.debug("Creating VendorStoreV2")
            _vendor = VendorStoreV2()
        }
        return _vendor!
    }
    
    var document: DocumentStoreV2 {
        if _document == nil {
            logger.debug("Creating DocumentStoreV2")
            _document = DocumentStoreV2()
        }
        return _document!
    }
    
    var task: TaskStoreV2 {
        if _task == nil {
            logger.debug("Creating TaskStoreV2")
            _task = TaskStoreV2()
        }
        return _task!
    }
    
    var timeline: TimelineStoreV2 {
        if _timeline == nil {
            logger.debug("Creating TimelineStoreV2")
            _timeline = TimelineStoreV2()
        }
        return _timeline!
    }
    
    var notes: NotesStoreV2 {
        if _notes == nil {
            logger.debug("Creating NotesStoreV2")
            _notes = NotesStoreV2()
        }
        return _notes!
    }
    
    var visualPlanning: VisualPlanningStoreV2 {
        if _visualPlanning == nil {
            logger.debug("Creating VisualPlanningStoreV2")
            _visualPlanning = VisualPlanningStoreV2()
        }
        return _visualPlanning!
    }
    
    var settings: SettingsStoreV2 {
        if _settings == nil {
            logger.debug("Creating SettingsStoreV2")
            _settings = SettingsStoreV2()
        }
        return _settings!
    }
    
    private init() {
        logger.info("🏪 AppStores singleton initialized")
        
        // ✅ Only create settings store (needed immediately for app configuration)
        _ = self.settings
        
        // ✅ Other stores created on-demand via lazy accessors
        logger.info("✅ AppStores ready (lazy loading enabled)")
        
        // Start memory monitoring in debug builds
        #if DEBUG
        startMemoryMonitoring()
        #endif
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    // MARK: - Memory Management
    
    /// Clear all store data and release stores (for logout)
    func clearAll() async {
        logger.info("Clearing all store data and releasing stores")
        
        // Clear repository caches first
        await RepositoryCache.shared.clearAll()
        
        // Release all stores except settings
        _budget = nil
        _guest = nil
        _vendor = nil
        _document = nil
        _task = nil
        _timeline = nil
        _notes = nil
        _visualPlanning = nil
        // Keep settings store as it's needed for app configuration
        
        logger.info("All stores cleared (settings retained)")
    }
    
    /// Get list of currently loaded stores (for debugging)
    func loadedStores() -> [String] {
        var loaded: [String] = []
        if _budget != nil { loaded.append("Budget") }
        if _guest != nil { loaded.append("Guest") }
        if _vendor != nil { loaded.append("Vendor") }
        if _document != nil { loaded.append("Document") }
        if _task != nil { loaded.append("Task") }
        if _timeline != nil { loaded.append("Timeline") }
        if _notes != nil { loaded.append("Notes") }
        if _visualPlanning != nil { loaded.append("VisualPlanning") }
        if _settings != nil { loaded.append("Settings") }
        return loaded
    }
    
    /// Get memory statistics (for debugging)
    func getMemoryStats() -> String {
        let loaded = loadedStores()
        let memoryMB = getMemoryUsage() / 1_000_000
        return """
        AppStores Memory Stats:
        - Loaded Stores: \(loaded.joined(separator: ", "))
        - Total Loaded: \(loaded.count)/9
        - Memory Usage: \(memoryMB) MB
        """
    }
    
    /// Handle memory pressure by releasing unused stores
    func handleMemoryPressure() async {
        logger.warning("Memory pressure detected - releasing unused stores")
        
        // Release visual planning store if loaded (typically large memory footprint)
        if _visualPlanning != nil {
            _visualPlanning = nil
            logger.info("Released VisualPlanningStoreV2")
        }
        
        // Clear repository caches
        await RepositoryCache.shared.clearAll()
        
        logger.info("Memory pressure handled")
    }
    
    /// Monitor memory usage and handle pressure automatically (DEBUG only)
    private func startMemoryMonitoring() {
        Task { @MainActor in
            var lastMemory: UInt64 = 0
            let threshold: UInt64 = 500_000_000 // 500MB
            
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                let memory = self.getMemoryUsage()
                let memoryMB = memory / 1_000_000
                
                // Log significant changes
                if memory > lastMemory + threshold {
                    self.logger.warning("Memory increased by \((memory - lastMemory) / 1_000_000) MB")
                    self.logger.info("Loaded stores: \(self.loadedStores().joined(separator: ", "))")
                }
                
                // Handle high memory
                if memoryMB > 1000 {
                    self.logger.error("High memory usage: \(memoryMB) MB")
                    Task {
                        await self.handleMemoryPressure()
                    }
                }
                
                lastMemory = memory
            }
        }
    }
}

/// Environment key for AppStores
struct AppStoresKey: EnvironmentKey {
    static let defaultValue = AppStores.shared
}

extension EnvironmentValues {
    var appStores: AppStores {
        get { self[AppStoresKey.self] }
        set { self[AppStoresKey.self] = newValue }
    }
}

// NOTE: These extensions allow views to access stores via environment
// Stores are created lazily on first access to minimize memory usage
extension EnvironmentValues {
    var budgetStore: BudgetStoreV2 {
        appStores.budget
    }
    
    var guestStore: GuestStoreV2 {
        appStores.guest
    }
    
    var vendorStore: VendorStoreV2 {
        appStores.vendor
    }
    
    var documentStore: DocumentStoreV2 {
        appStores.document
    }
    
    var taskStore: TaskStoreV2 {
        appStores.task
    }
    
    var timelineStore: TimelineStoreV2 {
        appStores.timeline
    }
    
    var notesStore: NotesStoreV2 {
        appStores.notes
    }
    
    var visualPlanningStore: VisualPlanningStoreV2 {
        appStores.visualPlanning
    }
}
