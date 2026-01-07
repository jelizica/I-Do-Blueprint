//
//  DashboardsNavigationWrapper.swift
//  I Do Blueprint
//
//  Created by Claude on 1/6/26.
//  Wrapper view that handles dashboards navigation from AppCoordinator
//

import SwiftUI

/// Wrapper view that handles navigation to different dashboard pages
/// Routes to the appropriate dashboard page based on coordinator.dashboardPage
struct DashboardsNavigationWrapper: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var currentPage: DashboardPage = .general

    /// Allow direct initialization with a specific page
    init(selectedPage: DashboardPage = .general) {
        _currentPage = State(initialValue: selectedPage)
    }

    var body: some View {
        dashboardContent
            .onAppear {
                // Handle initial navigation from coordinator (e.g., from sidebar)
                if let page = coordinator.dashboardPage {
                    currentPage = page
                    coordinator.dashboardPage = nil
                }
                // Reload budget data every time the dashboard appears
                Task {
                    await budgetStore.loadBudgetData()
                }
            }
            .onChange(of: coordinator.dashboardPage) { newPage in
                if let page = newPage {
                    currentPage = page
                    // Clear the navigation request after handling
                    coordinator.dashboardPage = nil
                }
            }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        switch currentPage {
        case .general:
            GeneralDashboardViewV1()
                .environmentObject(settingsStore)
        case .financial:
            // Create a binding for navigation back to budget pages if needed
            let budgetBinding = Binding<BudgetPage>(
                get: { .dashboardV1 },
                set: { newPage in
                    coordinator.navigateToBudget(page: newPage)
                }
            )
            BudgetDashboardViewV1(currentPage: budgetBinding)
        }
    }
}

#Preview {
    DashboardsNavigationWrapper()
        .environmentObject(AppCoordinator.shared)
        .environmentObject(AppStores.shared.budget)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1200, height: 900)
}
