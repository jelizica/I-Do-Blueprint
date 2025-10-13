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
    // MARK: - Navigation State

    @Published var selectedTab: AppTab = .dashboard
    @Published var activeSheet: Sheet?
    @Published var activeFullScreenCover: FullScreenCover?

    // MARK: - Shared Store Instances

    let vendorStore: VendorStoreV2
    let guestStore: GuestStoreV2
    let taskStore: TaskStoreV2
    let notesStore: NotesStoreV2

    // MARK: - Initialization

    init(
        vendorStore: VendorStoreV2? = nil,
        guestStore: GuestStoreV2? = nil,
        taskStore: TaskStoreV2? = nil,
        notesStore: NotesStoreV2? = nil
    ) {
        self.vendorStore = vendorStore ?? VendorStoreV2()
        self.guestStore = guestStore ?? GuestStoreV2()
        self.taskStore = taskStore ?? TaskStoreV2()
        self.notesStore = notesStore ?? NotesStoreV2()
    }

    // MARK: - Tab Definition

    enum AppTab: String, Hashable, CaseIterable {
        case dashboard
        case guests
        case vendors
        case budget
        case visualPlanning
        case timeline
        case notes
        case documents
        case settings

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .guests: return "Guests"
            case .vendors: return "Vendors"
            case .budget: return "Budget"
            case .visualPlanning: return "Visual Planning"
            case .timeline: return "Timeline"
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
            case .notes: return "note.text"
            case .documents: return "doc.fill"
            case .settings: return "gearshape.fill"
            }
        }

        @ViewBuilder
        var view: some View {
            switch self {
            case .dashboard:
                DashboardViewV2()
            case .guests:
                GuestListViewV2()
            case .vendors:
                VendorListViewV2()
            case .budget:
                BudgetMainView()
            case .visualPlanning:
                VisualPlanningMainView()
            case .timeline:
                TimelineViewV2()
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

        var id: String {
            switch self {
            case .addVendor: return "addVendor"
            case .editVendor(let vendor): return "editVendor-\(vendor.id)"
            case .addGuest: return "addGuest"
            case .editGuest(let guest): return "editGuest-\(guest.id)"
            case .addTask: return "addTask"
            case .editTask(let task): return "editTask-\(task.id)"
            case .addNote: return "addNote"
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
                EditGuestSheetV2(guest: guest, guestStore: coordinator.guestStore, onSave: { _ in })
            case .addTask:
                TaskModal(task: nil, onSave: { _ in }, onCancel: {})
            case .editTask(let task):
                TaskModal(task: task, onSave: { _ in }, onCancel: {})
            case .addNote:
                NoteModal(note: nil, onSave: { _ in }, onCancel: {})
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
}
