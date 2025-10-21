//
//  SingletonTypeTests.swift
//  I Do BlueprintTests
//
//  Unit tests to verify singleton declarations are correctly typed
//  Prevents copy-paste errors where static let shared points to wrong class
//

import XCTest
@testable import I_Do_Blueprint

/// Tests to ensure all singleton instances match their declared class type
/// This prevents the anti-pattern where `static let shared = WrongClass()`
final class SingletonTypeTests: XCTestCase {
    
    // MARK: - Analytics Services
    
    func test_performanceOptimizationService_singleton_correctType() {
        let service = PerformanceOptimizationService.shared
        XCTAssertTrue(type(of: service) == PerformanceOptimizationService.self,
                     "PerformanceOptimizationService.shared should be of type PerformanceOptimizationService")
    }
    
    func test_analyticsService_singleton_correctType() {
        let service = AnalyticsService.shared
        XCTAssertTrue(type(of: service) == AnalyticsService.self,
                     "AnalyticsService.shared should be of type AnalyticsService")
    }
    
    func test_errorTracker_singleton_correctType() {
        let tracker = ErrorTracker.shared
        XCTAssertTrue(type(of: tracker) == ErrorTracker.self,
                     "ErrorTracker.shared should be of type ErrorTracker")
    }
    
    // MARK: - Export Services
    
    func test_budgetExportService_singleton_correctType() {
        let service = BudgetExportService.shared
        XCTAssertTrue(type(of: service) == BudgetExportService.self,
                     "BudgetExportService.shared should be of type BudgetExportService")
    }
    
    func test_vendorExportService_singleton_correctType() {
        let service = VendorExportService.shared
        XCTAssertTrue(type(of: service) == VendorExportService.self,
                     "VendorExportService.shared should be of type VendorExportService")
    }
    
    func test_advancedExportTemplateService_singleton_correctType() {
        let service = AdvancedExportTemplateService.shared
        XCTAssertTrue(type(of: service) == AdvancedExportTemplateService.self,
                     "AdvancedExportTemplateService.shared should be of type AdvancedExportTemplateService")
    }
    
    // MARK: - Storage & Data Services
    
    func test_supabaseManager_singleton_correctType() {
        let manager = SupabaseManager.shared
        XCTAssertTrue(type(of: manager) == SupabaseManager.self,
                     "SupabaseManager.shared should be of type SupabaseManager")
    }
    
    func test_repositoryCacheRegistry_singleton_correctType() async {
        let registry = RepositoryCacheRegistry.shared
        // For actors, we need to check the type differently
        let typeName = String(describing: type(of: registry))
        XCTAssertEqual(typeName, "RepositoryCacheRegistry",
                      "RepositoryCacheRegistry.shared should be of type RepositoryCacheRegistry")
    }
    
    // MARK: - Integration Services
    
    func test_externalIntegrationsService_singleton_correctType() {
        let service = ExternalIntegrationsService.shared
        XCTAssertTrue(type(of: service) == ExternalIntegrationsService.self,
                     "ExternalIntegrationsService.shared should be of type ExternalIntegrationsService")
    }
    
    // MARK: - Auth Services
    
    func test_sessionManager_singleton_correctType() {
        let manager = SessionManager.shared
        XCTAssertTrue(type(of: manager) == SessionManager.self,
                     "SessionManager.shared should be of type SessionManager")
    }
    
    func test_authContext_singleton_correctType() {
        let context = AuthContext.shared
        XCTAssertTrue(type(of: context) == AuthContext.self,
                     "AuthContext.shared should be of type AuthContext")
    }
    
    // MARK: - UI Services
    
    func test_alertPresenter_singleton_correctType() {
        let presenter = AlertPresenter.shared
        XCTAssertTrue(type(of: presenter) == AlertPresenter.self,
                     "AlertPresenter.shared should be of type AlertPresenter")
    }
    
    // MARK: - Utility Services
    
    func test_safeImageLoader_singleton_correctType() {
        let loader = SafeImageLoader.shared
        XCTAssertTrue(type(of: loader) == SafeImageLoader.self,
                     "SafeImageLoader.shared should be of type SafeImageLoader")
    }
    
    // MARK: - Singleton Identity Tests
    
    func test_performanceOptimizationService_singleton_identity() {
        let instance1 = PerformanceOptimizationService.shared
        let instance2 = PerformanceOptimizationService.shared
        XCTAssertTrue(instance1 === instance2,
                     "PerformanceOptimizationService.shared should return the same instance")
    }
    
    func test_budgetExportService_singleton_identity() {
        let instance1 = BudgetExportService.shared
        let instance2 = BudgetExportService.shared
        XCTAssertTrue(instance1 === instance2,
                     "BudgetExportService.shared should return the same instance")
    }
    
    func test_sessionManager_singleton_identity() {
        let instance1 = SessionManager.shared
        let instance2 = SessionManager.shared
        XCTAssertTrue(instance1 === instance2,
                     "SessionManager.shared should return the same instance")
    }
    
    func test_alertPresenter_singleton_identity() {
        let instance1 = AlertPresenter.shared
        let instance2 = AlertPresenter.shared
        XCTAssertTrue(instance1 === instance2,
                     "AlertPresenter.shared should return the same instance")
    }
    
    // MARK: - Protocol Conformance Tests
    
    func test_alertPresenter_conformsToProtocol() {
        let presenter = AlertPresenter.shared
        XCTAssertTrue(presenter is AlertPresenterProtocol,
                     "AlertPresenter should conform to AlertPresenterProtocol")
    }
    
    func test_observableObjects_conformance() {
        // Test that services marked as ObservableObject actually conform
        XCTAssertTrue(PerformanceOptimizationService.shared is ObservableObject)
        XCTAssertTrue(AnalyticsService.shared is ObservableObject)
        XCTAssertTrue(AdvancedExportTemplateService.shared is ObservableObject)
        XCTAssertTrue(SupabaseManager.shared is ObservableObject)
        XCTAssertTrue(ExternalIntegrationsService.shared is ObservableObject)
        XCTAssertTrue(SessionManager.shared is ObservableObject)
        XCTAssertTrue(AlertPresenter.shared is ObservableObject)
        XCTAssertTrue(AuthContext.shared is ObservableObject)
    }
    
    // MARK: - MainActor Isolation Tests
    
    @MainActor
    func test_mainActorServices_accessible() {
        // These services should be accessible from MainActor context
        _ = PerformanceOptimizationService.shared
        _ = BudgetExportService.shared
        _ = VendorExportService.shared
        _ = AdvancedExportTemplateService.shared
        _ = SupabaseManager.shared
        _ = ExternalIntegrationsService.shared
        _ = SessionManager.shared
        _ = AlertPresenter.shared
        _ = AuthContext.shared
        _ = SafeImageLoader.shared
        
        // If we get here without compiler errors, the test passes
        XCTAssertTrue(true, "All MainActor services are accessible")
    }
}
