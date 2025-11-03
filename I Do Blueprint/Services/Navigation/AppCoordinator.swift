//
//  AppCoordinator.swift
//  I Do Blueprint
//
//  Created by Claude on 1/9/25.
//  Navigation coordinator for sidebar-based navigation
//

import SwiftUI
import Combine
import AppKit

@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Singleton

    static let shared = AppCoordinator()

    // MARK: - Navigation State

    @Published var selectedTab: AppTab = .dashboard
    @Published var activeSheet: Sheet?
    @Published var activeFullScreenCover: FullScreenCover?

    // MARK: - Shared Store Instances (from AppStores singleton)

    let appStores: AppStores

    var vendorStore: VendorStoreV2 { appStores.vendor }
    var guestStore: GuestStoreV2 { appStores.guest }
    var taskStore: TaskStoreV2 { appStores.task }
    var notesStore: NotesStoreV2 { appStores.notes }

    // MARK: - Initialization

    private init(appStores: AppStores = .shared) {
        self.appStores = appStores
    }

    // MARK: - Tab Definition

    enum AppTab: String, Hashable, CaseIterable {
        case dashboard = "dashboard"
        case guests = "guests"
        case vendors = "vendors"
        case budget = "budget"
        case visualPlanning = "visualPlanning"
        case timeline = "timeline"
        case collaboration = "collaboration"
        case notes = "notes"
        case documents = "documents"
        case settings = "settings"

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .guests: return "Guests"
            case .vendors: return "Vendors"
            case .budget: return "Budget"
            case .visualPlanning: return "Visual Planning"
            case .timeline: return "Timeline"
            case .collaboration: return "Collaboration"
            case .notes: return "Notes"
            case .documents: return "Documents"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .guests: return "person.3.fill"
            case .vendors: return "building.2.fill"
            case .budget: return "dollarsign.circle.fill"
            case .visualPlanning: return "paintpalette.fill"
            case .timeline: return "calendar"
            case .collaboration: return "person.2.fill"
            case .notes: return "note.text"
            case .documents: return "doc.fill"
            case .settings: return "gearshape.fill"
            }
        }

        @ViewBuilder
        var view: some View {
            switch self {
            case .dashboard:
                DashboardViewV4()
            case .guests:
                GuestManagementViewV4()
            case .vendors:
                VendorManagementViewV3()
            case .budget:
                BudgetMainView()
            case .visualPlanning:
                VisualPlanningMainView()
            case .timeline:
                TimelineViewV2()
            case .collaboration:
                CollaborationMainView()
            case .notes:
                NotesView()
            case .documents:
                DocumentsView()
            case .settings:
                SettingsView()
            }
        }
    }

    // MARK: - Sheet Definition

    enum Sheet: Identifiable {
        case addVendor
        case editVendor(Vendor)
        case addGuest
        case editGuest(Guest)
        case addTask
        case editTask(WeddingTask)
        case addNote
        case acceptInvitation(token: String, details: InvitationDetails?)

        var id: String {
            switch self {
            case .addVendor: return "addVendor"
            case .editVendor(let vendor): return "editVendor-\(vendor.id)"
            case .addGuest: return "addGuest"
            case .editGuest(let guest): return "editGuest-\(guest.id)"
            case .addTask: return "addTask"
            case .editTask(let task): return "editTask-\(task.id)"
            case .addNote: return "addNote"
            case .acceptInvitation(let token, _): return "acceptInvitation-\(token)"
            }
        }

        @ViewBuilder
        func view(coordinator: AppCoordinator) -> some View {
            switch self {
            case .addVendor:
                AddVendorView { _ in }
            case .editVendor(let vendor):
                EditVendorSheetV2(vendor: vendor, vendorStore: coordinator.vendorStore, onSave: { _ in })
            case .addGuest:
                AddGuestView { _ in }
            case .editGuest(let guest):
                GuestDetailViewV4(guestId: guest.id, guestStore: coordinator.guestStore)
            case .addTask:
                TaskModal(task: nil, onSave: { _ in }, onCancel: {})
            case .editTask(let task):
                TaskModal(task: task, onSave: { _ in }, onCancel: {})
            case .addNote:
                NoteModal(note: nil, onSave: { _ in }, onCancel: {})
            case .acceptInvitation(let token, let details):
                AcceptInvitationView(token: token, coordinator: coordinator, details: details)
            }
        }
    }

    // MARK: - Full Screen Covers

    enum FullScreenCover: Identifiable {
        case onboarding

        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            }
        }

        @ViewBuilder
        var view: some View {
            switch self {
            case .onboarding:
                Text("Onboarding") // Placeholder
            }
        }
    }

    // MARK: - Public API

    func navigate(to tab: AppTab) {
        selectedTab = tab
    }

    func present(_ sheet: Sheet) {
        activeSheet = sheet
    }

    func dismiss() {
        activeSheet = nil
        activeFullScreenCover = nil
    }

    // MARK: - Alert Presentation (Async API)

    func showExportSuccess(fileURL: URL) async {
        let response = await AlertPresenter.shared.showAlert(
            title: "Export Successful",
            message: "Your file has been saved successfully.",
            style: .informational,
            buttons: ["Open File", "OK"]
        )
        if response == "Open File" {
            NSWorkspace.shared.open(fileURL)
        }
    }

    func showExportError(_ error: Error) async {
        _ = await AlertPresenter.shared.showAlert(
            title: "Export Failed",
            message: error.localizedDescription,
            style: .warning,
            buttons: ["OK"]
        )
    }

    func showDeleteConfirmation(item: String) async -> Bool {
        let response = await AlertPresenter.shared.showAlert(
            title: "Delete \(item)?",
            message: "This action cannot be undone.",
            style: .warning,
            buttons: ["Delete", "Cancel"]
        )
        return response == "Delete"
    }

    func showError(title: String = "Error", message: String) async {
        _ = await AlertPresenter.shared.showAlert(
            title: title,
            message: message,
            style: .warning,
            buttons: ["OK"]
        )
    }

    func showInfo(title: String, message: String) async {
        _ = await AlertPresenter.shared.showAlert(
            title: title,
            message: message,
            style: .informational,
            buttons: ["OK"]
        )
    }

    // MARK: - Deep Link Handling

    /// Handle collaboration invitation deep links
    /// - Parameter token: The invitation token from the deep link
    func handleInvitationDeepLink(token: String) {
        let logger = AppLogger.auth
        logger.info("Handling invitation deep link with token")

        Task { @MainActor in
            do {
                // Prefetch invitation details
                let details = try await InvitationService.shared.fetchInvitation(token: token)

                // Navigate to collaboration tab and present with preloaded details
                selectedTab = .collaboration
                present(.acceptInvitation(token: token, details: details))
                logger.debug("Presented AcceptInvitationView with preloaded details")
            } catch {
                // Show a lightweight error without presenting the sheet
                await AlertPresenter.shared.showAlert(
                    title: "Invitation Error",
                    message: error.localizedDescription,
                    style: .warning,
                    buttons: ["OK"]
                )
                logger.error("Failed to prefetch invitation details", error: error)
            }
        }
    }
}
