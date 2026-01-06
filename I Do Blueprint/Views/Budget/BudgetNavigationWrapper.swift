//
//  BudgetNavigationWrapper.swift
//  I Do Blueprint
//
//  Created by Qodo Gen on 1/6/26.
//  Wrapper view that handles budget navigation from AppCoordinator
//

import SwiftUI

/// Wrapper view that handles navigation to different budget pages
/// Routes to the appropriate budget page based on coordinator.budgetPage
struct BudgetNavigationWrapper: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var currentPage: BudgetPage = .budgetOverview
    
    var body: some View {
        currentPage.view(currentPage: $currentPage)
            .task {
                await budgetStore.loadBudgetData()
            }
            .onAppear {
                // Handle initial navigation from coordinator (e.g., from sidebar)
                if let page = coordinator.budgetPage {
                    currentPage = page
                    coordinator.budgetPage = nil
                }
            }
            .onChange(of: coordinator.budgetPage) { newPage in
                if let page = newPage {
                    currentPage = page
                    // Clear the navigation request after handling
                    coordinator.budgetPage = nil
                }
            }
    }
}

#Preview {
    BudgetNavigationWrapper()
        .environmentObject(AppCoordinator.shared)
        .environmentObject(BudgetStoreV2())
        .frame(width: 1000, height: 800)
}
