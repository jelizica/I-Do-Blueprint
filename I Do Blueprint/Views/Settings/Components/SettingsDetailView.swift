//
//  SettingsDetailView.swift
//  I Do Blueprint
//
//  Detail content view for settings sections
//  NOTE: This file is deprecated. Use SettingsView.swift instead.
//

import SwiftUI

struct SettingsDetailView: View {
    let selectedSection: SettingsSection
    let selectedSubsection: AnySubsection
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
                message: error.localizedDescription,
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
        switch selectedSubsection {
        // Global
        case .global(.overview):
            GlobalSettingsView(viewModel: store)
        case .global(.weddingEvents):
            WeddingEventsView()
            
        // Account
        case .account(.profile):
            AccountSettingsView()
        case .account(.collaboration):
            CollaborationSettingsView()
        case .account(.dataPrivacy):
            DangerZoneView(viewModel: store)
            
        // Budget & Vendors
        case .budgetVendors(.budgetConfiguration):
            BudgetConfigSettingsView(viewModel: store)
        case .budgetVendors(.budgetCategories):
            BudgetCategoriesSettingsView()
        case .budgetVendors(.vendorManagement):
            VendorsSettingsView(viewModel: store)
        case .budgetVendors(.vendorCategories):
            VendorCategoriesSettingsView(viewModel: store)
            
        // Guests & Tasks
        case .guestsTasks(.guestPreferences):
            GuestsSettingsView(viewModel: store)
        case .guestsTasks(.taskPreferences):
            TasksSettingsView(viewModel: store)
        case .guestsTasks(.teamMembers):
            Text("Team Members - Coming Soon")
            
        // Appearance
        case .appearance(.theme):
            ThemeSettingsView(viewModel: store)
        case .appearance(.notifications):
            NotificationsSettingsView(viewModel: store)
            
        // Data & Content
        case .dataContent(.documents):
            DocumentsSettingsView(viewModel: store)
        case .dataContent(.importantLinks):
            LinksSettingsView(viewModel: store)
            
        // Developer
        case .developer(.apiKeys):
            APIKeysSettingsView()
        case .developer(.featureFlags):
            FeatureFlagsSettingsView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        "\(selectedSection.rawValue) - \(selectedSubsection.rawValue)"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsDetailView(
            selectedSection: .global,
            selectedSubsection: .global(.overview),
            store: SettingsStoreV2()
        )
    }
    .frame(width: 700, height: 600)
}
