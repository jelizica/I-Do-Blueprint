//
//  FeaturePreferencesView.swift
//  I Do Blueprint
//
//  Feature preferences configuration for onboarding
//

import SwiftUI

struct FeaturePreferencesView: View {
    @Environment(\.onboardingStore) private var store

    // Tasks preferences
    @State private var tasksDefaultView: String = "kanban"
    @State private var tasksShowCompleted: Bool = false
    @State private var tasksNotificationsEnabled: Bool = true

    // Vendors preferences
    @State private var vendorsDefaultView: String = "grid"
    @State private var vendorsShowPaymentStatus: Bool = true
    @State private var vendorsAutoReminders: Bool = true

    // Guests preferences
    @State private var guestsDefaultView: String = "list"
    @State private var guestsShowMealPreferences: Bool = true
    @State private var guestsRSVPReminders: Bool = true

    // Documents preferences
    @State private var documentsAutoOrganize: Bool = true
    @State private var documentsCloudBackup: Bool = true
    @State private var documentsRetentionDays: String = "365"

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                headerSection
                formSection
            }
        }
        .background(AppColors.background)
        .onAppear {
            loadExistingPreferences()
        }
        .onDisappear {
            savePreferences()
        }
    }

    // MARK: - View Sections

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Feature Preferences")
                .font(Typography.title1)
                .foregroundColor(AppColors.textPrimary)

            Text("Customize how you want to use each feature")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)

            Text("You can change these later in Settings")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, Spacing.xl)
    }

    private var formSection: some View {
        VStack(spacing: Spacing.lg) {
            tasksSection
            Divider().padding(.vertical, Spacing.sm)
            vendorsSection
            Divider().padding(.vertical, Spacing.sm)
            guestsSection
            Divider().padding(.vertical, Spacing.sm)
            documentsSection
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Tasks")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Default View")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)

                Picker("Default View", selection: $tasksDefaultView) {
                    Text("Kanban Board").tag("kanban")
                    Text("List View").tag("list")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Tasks default view")
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)

            SettingsToggle(
                title: "Show Completed Tasks",
                description: "Display completed tasks in your task list",
                isOn: $tasksShowCompleted
            )

            SettingsToggle(
                title: "Task Notifications",
                description: "Get notified about upcoming task deadlines",
                isOn: $tasksNotificationsEnabled
            )
        }
    }

    private var vendorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Vendors")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Default View")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)

                Picker("Default View", selection: $vendorsDefaultView) {
                    Text("Grid View").tag("grid")
                    Text("List View").tag("list")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Vendors default view")
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)

            SettingsToggle(
                title: "Show Payment Status",
                description: "Display payment status badges on vendor cards",
                isOn: $vendorsShowPaymentStatus
            )

            SettingsToggle(
                title: "Auto Payment Reminders",
                description: "Automatically remind you of upcoming vendor payments",
                isOn: $vendorsAutoReminders
            )
        }
    }

    private var guestsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Guests")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Default View")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)

                Picker("Default View", selection: $guestsDefaultView) {
                    Text("List View").tag("list")
                    Text("Grid View").tag("grid")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Guests default view")
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)

            SettingsToggle(
                title: "Show Meal Preferences",
                description: "Display meal preference information for guests",
                isOn: $guestsShowMealPreferences
            )

            SettingsToggle(
                title: "RSVP Reminders",
                description: "Send reminders to guests who haven't RSVP'd",
                isOn: $guestsRSVPReminders
            )
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Documents")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            SettingsToggle(
                title: "Auto-Organize Documents",
                description: "Automatically organize documents by category",
                isOn: $documentsAutoOrganize
            )

            SettingsToggle(
                title: "Cloud Backup",
                description: "Automatically backup documents to cloud storage",
                isOn: $documentsCloudBackup
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Document Retention")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)

                HStack {
                    TextField("Days", text: $documentsRetentionDays)
                        .textFieldStyle(.plain)
                        .font(Typography.bodyRegular)
                        .padding(Spacing.md)
                        .background(AppColors.background)
                        .cornerRadius(4)
                        .frame(width: 100)

                    Text("days")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()
                }

                Text("How long to keep documents after the wedding")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
        }
    }

    // MARK: - Helper Methods

    private func loadExistingPreferences() {
        guard let featurePrefs = store.defaultSettings.featurePreferences else { return }

        // Tasks
        tasksDefaultView = featurePrefs.tasks.defaultView
        tasksShowCompleted = featurePrefs.tasks.showCompleted
        tasksNotificationsEnabled = featurePrefs.tasks.notificationsEnabled

        // Vendors
        vendorsDefaultView = featurePrefs.vendors.defaultView
        vendorsShowPaymentStatus = featurePrefs.vendors.showPaymentStatus
        vendorsAutoReminders = featurePrefs.vendors.autoReminders

        // Guests
        guestsDefaultView = featurePrefs.guests.defaultView
        guestsShowMealPreferences = featurePrefs.guests.showMealPreferences
        guestsRSVPReminders = featurePrefs.guests.rsvpReminders

        // Documents
        documentsAutoOrganize = featurePrefs.documents.autoOrganize
        documentsCloudBackup = featurePrefs.documents.cloudBackup
        documentsRetentionDays = "\(featurePrefs.documents.retentionDays)"
    }

    private func savePreferences() {
        let featurePrefs = FeaturePreferences(
            tasks: TasksSettings(
                defaultView: tasksDefaultView,
                showCompleted: tasksShowCompleted,
                notificationsEnabled: tasksNotificationsEnabled,
                customResponsibleParties: []
            ),
            vendors: VendorsSettings(
                defaultView: vendorsDefaultView,
                showPaymentStatus: vendorsShowPaymentStatus,
                autoReminders: vendorsAutoReminders,
                hiddenStandardCategories: []
            ),
            guests: GuestsSettings(
                defaultView: guestsDefaultView,
                showMealPreferences: guestsShowMealPreferences,
                rsvpReminders: guestsRSVPReminders,
                customMealOptions: ["Chicken", "Beef", "Fish", "Vegetarian", "Vegan"]
            ),
            documents: DocumentsSettings(
                autoOrganize: documentsAutoOrganize,
                cloudBackup: documentsCloudBackup,
                retentionDays: Int(documentsRetentionDays) ?? 365,
                vendorBehavior: .default
            )
        )

        var settings = store.defaultSettings
        settings.featurePreferences = featurePrefs

        Task {
            await store.saveDefaultSettings(settings)
        }
    }
}

// MARK: - Preview

#Preview("Feature Preferences View") {
    FeaturePreferencesView()
}
