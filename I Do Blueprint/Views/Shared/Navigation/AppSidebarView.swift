//
//  AppSidebarView.swift
//  I Do Blueprint
//
//  Created by Claude on 1/9/25.
//  Sidebar navigation for macOS app
//

import SwiftUI

struct AppSidebarView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        List(selection: $coordinator.selectedTab) {
            // Overview
            Section("Overview") {
                SidebarItem(
                    tab: .dashboard,
                    icon: "house.fill",
                    title: "Dashboard"
                )
            }

            // Planning
            Section("Planning") {
                SidebarItem(tab: .guests, icon: "person.3.fill", title: "Guests")
                SidebarItem(tab: .vendors, icon: "building.2.fill", title: "Vendors")
                SidebarItem(tab: .timeline, icon: "calendar", title: "Timeline")
            }

            // Budget
            Section("Budget & Finances") {
                SidebarItem(tab: .budget, icon: "dollarsign.circle.fill", title: "Budget")
            }

            // Creative
            Section("Creative") {
                SidebarItem(tab: .visualPlanning, icon: "paintpalette.fill", title: "Visual Planning")
            }

            // Documents
            Section("Documents & Notes") {
                SidebarItem(tab: .notes, icon: "note.text", title: "Notes")
                SidebarItem(tab: .documents, icon: "doc.fill", title: "Documents")
            }

            Spacer()
                .frame(height: 20)

            // Settings at bottom
            Section {
                SidebarItem(tab: .settings, icon: "gearshape.fill", title: "Settings")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("I Do Blueprint")
    }
}

struct SidebarItem: View {
    @EnvironmentObject var coordinator: AppCoordinator
    let tab: AppCoordinator.AppTab
    let icon: String
    let title: String

    var isSelected: Bool {
        coordinator.selectedTab == tab
    }

    var body: some View {
        Label(title, systemImage: icon)
            .tag(tab)
    }
}

#Preview {
    NavigationSplitView {
        AppSidebarView()
            .environmentObject(AppCoordinator())
    } detail: {
        Text("Detail View")
    }
}
