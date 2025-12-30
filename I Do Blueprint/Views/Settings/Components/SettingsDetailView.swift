//
//  SettingsDetailView.swift
//  I Do Blueprint
//
//  Detail content view for settings sections
//

import SwiftUI

struct SettingsDetailView: View {
    let selectedSection: SettingsSection
    let selectedGlobalSubsection: GlobalSubsection
    @ObservedObject var store: SettingsStoreV2
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Error/Success Messages
                statusMessages
                
                // Section Content
                sectionContent
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(navigationTitle)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var statusMessages: some View {
        if let error = store.error {
            ErrorBannerView(
                message: error.localizedDescription ?? "An error occurred",
                onDismiss: {
                    store.clearError()
                }
            )
        }
        
        if let success = store.successMessage {
            InfoCard(
                icon: "checkmark.circle.fill",
                title: "Success",
                content: success,
                color: .green,
                action: {
                    store.clearSuccessMessage()
                }
            )
        }
    }
    
    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .global:
            globalSectionContent
        case .theme:
            ThemeSettingsView(viewModel: store)
        case .budget:
            BudgetConfigSettingsView(viewModel: store)
        case .tasks:
            TasksSettingsView(viewModel: store)
        case .vendors:
            VendorsSettingsView(viewModel: store)
        case .vendorCategories:
            VendorCategoriesSettingsView(viewModel: store)
        case .guests:
            GuestsSettingsView(viewModel: store)
        case .documents:
            DocumentsSettingsView(viewModel: store)
        case .collaboration:
            CollaborationSettingsView()
        case .notifications:
            NotificationsSettingsView(viewModel: store)
        case .links:
            LinksSettingsView(viewModel: store)
        case .apiKeys:
            APIKeysSettingsView()
        case .account:
            AccountSettingsView()
        case .featureFlags:
            FeatureFlagsSettingsView()
        case .danger:
            DangerZoneView(viewModel: store)
        }
    }
    
    @ViewBuilder
    private var globalSectionContent: some View {
        switch selectedGlobalSubsection {
        case .overview:
            GlobalSettingsView(viewModel: store)
        case .weddingEvents:
            WeddingEventsView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        if selectedSection == .global {
            return "Global - \(selectedGlobalSubsection.rawValue)"
        } else {
            return selectedSection.rawValue
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsDetailView(
            selectedSection: .global,
            selectedGlobalSubsection: .overview,
            store: SettingsStoreV2()
        )
    }
    .frame(width: 700, height: 600)
}
