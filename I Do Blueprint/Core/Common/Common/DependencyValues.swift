import Dependencies
import Foundation

// MARK: - Dependency Keys

/// Dependency key for BudgetRepository
private enum BudgetRepositoryKey: DependencyKey {
    static let liveValue: any BudgetRepositoryProtocol = LiveBudgetRepository()
    static let testValue: any BudgetRepositoryProtocol = MockBudgetRepository()
    static let previewValue: any BudgetRepositoryProtocol = MockBudgetRepository()
}

/// Dependency key for GuestRepository
private enum GuestRepositoryKey: DependencyKey {
    static let liveValue: any GuestRepositoryProtocol = LiveGuestRepository()
    static let testValue: any GuestRepositoryProtocol = MockGuestRepository()
    static let previewValue: any GuestRepositoryProtocol = MockGuestRepository()
}

/// Dependency key for VendorRepository
private enum VendorRepositoryKey: DependencyKey {
    static let liveValue: any VendorRepositoryProtocol = LiveVendorRepository()
    static let testValue: any VendorRepositoryProtocol = MockVendorRepository()
    static let previewValue: any VendorRepositoryProtocol = MockVendorRepository()
}

/// Dependency key for DocumentRepository
private enum DocumentRepositoryKey: DependencyKey {
    static let liveValue: any DocumentRepositoryProtocol = LiveDocumentRepository()
    static let testValue: any DocumentRepositoryProtocol = MockDocumentRepository()
    static let previewValue: any DocumentRepositoryProtocol = MockDocumentRepository()
}

/// Dependency key for TaskRepository
private enum TaskRepositoryKey: DependencyKey {
    static let liveValue: any TaskRepositoryProtocol = LiveTaskRepository()
    static let testValue: any TaskRepositoryProtocol = MockTaskRepository()
    static let previewValue: any TaskRepositoryProtocol = MockTaskRepository()
}

/// Dependency key for TimelineRepository
private enum TimelineRepositoryKey: DependencyKey {
    static let liveValue: any TimelineRepositoryProtocol = LiveTimelineRepository()
    static let testValue: any TimelineRepositoryProtocol = MockTimelineRepository()
    static let previewValue: any TimelineRepositoryProtocol = MockTimelineRepository()
}

/// Dependency key for VisualPlanningRepository
private enum VisualPlanningRepositoryKey: DependencyKey {
    static let liveValue: any VisualPlanningRepositoryProtocol = LiveVisualPlanningRepository()
    static let testValue: any VisualPlanningRepositoryProtocol = MockVisualPlanningRepository()
    static let previewValue: any VisualPlanningRepositoryProtocol = MockVisualPlanningRepository()
}

/// Dependency key for SettingsRepository
private enum SettingsRepositoryKey: DependencyKey {
    static let liveValue: any SettingsRepositoryProtocol = LiveSettingsRepository()
    static let testValue: any SettingsRepositoryProtocol = MockSettingsRepository()
    static let previewValue: any SettingsRepositoryProtocol = MockSettingsRepository()
}

/// Dependency key for NotesRepository
private enum NotesRepositoryKey: DependencyKey {
    static let liveValue: any NotesRepositoryProtocol = LiveNotesRepository()
    static let testValue: any NotesRepositoryProtocol = MockNotesRepository()
    static let previewValue: any NotesRepositoryProtocol = MockNotesRepository()
}

/// Dependency key for AlertPresenter
private enum AlertPresenterKey: DependencyKey {
    @MainActor
    static let liveValue: any AlertPresenterProtocol = AlertPresenter.shared

    @MainActor
    static let testValue: any AlertPresenterProtocol = MockAlertPresenter()

    @MainActor
    static let previewValue: any AlertPresenterProtocol = MockAlertPresenter()
}

// MARK: - Dependency Extensions

extension DependencyValues {
    /// Access the budget repository dependency
    /// - In production: Returns LiveBudgetRepository with Supabase
    /// - In tests: Returns MockBudgetRepository with in-memory storage
    /// - In previews: Returns MockBudgetRepository with sample data
    var budgetRepository: any BudgetRepositoryProtocol {
        get { self[BudgetRepositoryKey.self] }
        set { self[BudgetRepositoryKey.self] = newValue }
    }

    /// Access the guest repository dependency
    /// - In production: Returns LiveGuestRepository with Supabase
    /// - In tests: Returns MockGuestRepository with in-memory storage
    /// - In previews: Returns MockGuestRepository with sample data
    var guestRepository: any GuestRepositoryProtocol {
        get { self[GuestRepositoryKey.self] }
        set { self[GuestRepositoryKey.self] = newValue }
    }

    /// Access the vendor repository dependency
    /// - In production: Returns LiveVendorRepository with Supabase
    /// - In tests: Returns MockVendorRepository with in-memory storage
    /// - In previews: Returns MockVendorRepository with sample data
    var vendorRepository: any VendorRepositoryProtocol {
        get { self[VendorRepositoryKey.self] }
        set { self[VendorRepositoryKey.self] = newValue }
    }

    /// Access the document repository dependency
    /// - In production: Returns LiveDocumentRepository with Supabase
    /// - In tests: Returns MockDocumentRepository with in-memory storage
    /// - In previews: Returns MockDocumentRepository with sample data
    var documentRepository: any DocumentRepositoryProtocol {
        get { self[DocumentRepositoryKey.self] }
        set { self[DocumentRepositoryKey.self] = newValue }
    }

    /// Access the task repository dependency
    /// - In production: Returns LiveTaskRepository with Supabase
    /// - In tests: Returns MockTaskRepository with in-memory storage
    /// - In previews: Returns MockTaskRepository with sample data
    var taskRepository: any TaskRepositoryProtocol {
        get { self[TaskRepositoryKey.self] }
        set { self[TaskRepositoryKey.self] = newValue }
    }

    /// Access the timeline repository dependency
    /// - In production: Returns LiveTimelineRepository with Supabase
    /// - In tests: Returns MockTimelineRepository with in-memory storage
    /// - In previews: Returns MockTimelineRepository with sample data
    var timelineRepository: any TimelineRepositoryProtocol {
        get { self[TimelineRepositoryKey.self] }
        set { self[TimelineRepositoryKey.self] = newValue }
    }

    /// Access the visual planning repository dependency
    /// - In production: Returns LiveVisualPlanningRepository with Supabase
    /// - In tests: Returns MockVisualPlanningRepository with in-memory storage
    /// - In previews: Returns MockVisualPlanningRepository with sample data
    var visualPlanningRepository: any VisualPlanningRepositoryProtocol {
        get { self[VisualPlanningRepositoryKey.self] }
        set { self[VisualPlanningRepositoryKey.self] = newValue }
    }

    /// Access the settings repository dependency
    /// - In production: Returns LiveSettingsRepository with Supabase
    /// - In tests: Returns MockSettingsRepository with in-memory storage
    /// - In previews: Returns MockSettingsRepository with sample data
    var settingsRepository: any SettingsRepositoryProtocol {
        get { self[SettingsRepositoryKey.self] }
        set { self[SettingsRepositoryKey.self] = newValue }
    }

    /// Access the notes repository dependency
    /// - In production: Returns LiveNotesRepository with Supabase
    /// - In tests: Returns MockNotesRepository with in-memory storage
    /// - In previews: Returns MockNotesRepository with sample data
    var notesRepository: any NotesRepositoryProtocol {
        get { self[NotesRepositoryKey.self] }
        set { self[NotesRepositoryKey.self] = newValue }
    }

    /// Access the alert presenter dependency
    /// - In production: Returns AlertPresenter.shared
    /// - In tests: Returns MockAlertPresenter for non-blocking tests
    /// - In previews: Returns MockAlertPresenter
    var alertPresenter: any AlertPresenterProtocol {
        get { self[AlertPresenterKey.self] }
        set { self[AlertPresenterKey.self] = newValue }
    }
}

// MARK: - Usage Examples

/*

 // In a ViewModel:
 @Dependency(\.budgetRepository) var repository

 // In tests:
 await withDependencies {
     let mockRepo = MockBudgetRepository()
     mockRepo.categories = [.mock(name: "Venue", amount: 10000)]
     $0.budgetRepository = mockRepo
 } operation: {
     let store = BudgetStoreV2()
     await store.loadBudgetData()
     XCTAssertEqual(store.categories.count, 1)
 }

 // Override in previews:
 #Preview {
     withDependencies {
         let mockRepo = MockBudgetRepository()
         mockRepo.budgetSummary = .preview
         mockRepo.categories = [.preview1, .preview2]
         $0.budgetRepository = mockRepo
     } operation: {
         BudgetView()
     }
 }

 */
