//
//  DefaultSettingsView.swift
//  I Do Blueprint
//
//  Default settings configuration for onboarding
//

import SwiftUI

struct DefaultSettingsView: View {
    @Environment(\.onboardingStore) private var store

    @State private var selectedCurrency: String = "USD"
    @State private var selectedTimezone: String = TimeZone.current.identifier
    @State private var selectedColorScheme: String = "blush-romance"
    @State private var darkModeEnabled: Bool = false
    @State private var trackPayments: Bool = true
    @State private var enableBudgetAlerts: Bool = true
    @State private var alertThreshold: Double = 0.9
    @State private var emailNotifications: Bool = true
    @State private var pushNotifications: Bool = true
    @State private var taskReminders: Bool = true
    @State private var paymentReminders: Bool = true
    @State private var eventReminders: Bool = true

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CNY", "INR"]
    private let timezones = TimeZone.knownTimeZoneIdentifiers.sorted()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                headerSection
                formSection
            }
        }
        .background(SemanticColors.backgroundPrimary)
        .onAppear {
            loadExistingSettings()
        }
        .onChange(of: selectedCurrency) { _ in saveSettings() }
        .onChange(of: selectedTimezone) { _ in saveSettings() }
        .onChange(of: selectedColorScheme) { _ in saveSettings() }
        .onChange(of: darkModeEnabled) { _ in saveSettings() }
        .onChange(of: trackPayments) { _ in saveSettings() }
        .onChange(of: enableBudgetAlerts) { _ in saveSettings() }
        .onChange(of: alertThreshold) { _ in saveSettings() }
        .onChange(of: emailNotifications) { _ in saveSettings() }
        .onChange(of: pushNotifications) { _ in saveSettings() }
        .onChange(of: taskReminders) { _ in saveSettings() }
        .onChange(of: paymentReminders) { _ in saveSettings() }
        .onChange(of: eventReminders) { _ in saveSettings() }
    }

    // MARK: - View Sections

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Default Settings")
                .font(Typography.title1)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Configure your preferences")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .padding(.top, Spacing.xl)
    }

    private var formSection: some View {
        VStack(spacing: Spacing.lg) {
            themeSection
            Divider().padding(.vertical, Spacing.sm)
            currencySection
            Divider().padding(.vertical, Spacing.sm)
            timezoneSection
            Divider().padding(.vertical, Spacing.sm)
            budgetPreferencesSection
            Divider().padding(.vertical, Spacing.sm)
            notificationPreferencesSection
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Theme Preferences")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Color Scheme")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)

                Picker("Color Scheme", selection: $selectedColorScheme) {
                    Text("Default").tag("default")
                    Text("Blue").tag("blue")
                    Text("Purple").tag("purple")
                    Text("Pink").tag("pink")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Color scheme selection")
                .accessibilityValue(selectedColorScheme)
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(8)

            SettingsToggle(
                title: "Dark Mode",
                description: "Use dark theme throughout the app",
                isOn: $darkModeEnabled
            )
        }
    }

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormSectionHeader(title: "Currency", isRequired: true)

            Picker("Currency", selection: $selectedCurrency) {
                ForEach(currencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .pickerStyle(.menu)
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(8)
            .accessibilityLabel("Currency selection")
            .accessibilityValue(selectedCurrency)
        }
    }

    private var timezoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormSectionHeader(title: "Timezone", isRequired: true)

            Picker("Timezone", selection: $selectedTimezone) {
                ForEach(timezones, id: \.self) { timezone in
                    Text(timezone).tag(timezone)
                }
            }
            .pickerStyle(.menu)
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(8)
            .accessibilityLabel("Timezone selection")
            .accessibilityValue(selectedTimezone)
        }
    }

    private var budgetPreferencesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Budget Preferences")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)

            SettingsToggle(
                title: "Track Payments",
                description: "Monitor payment schedules and due dates",
                isOn: $trackPayments
            )

            SettingsToggle(
                title: "Enable Budget Alerts",
                description: "Get notified when approaching budget limits",
                isOn: $enableBudgetAlerts
            )

            if enableBudgetAlerts {
                alertThresholdSection
            }
        }
    }

    private var alertThresholdSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Alert Threshold")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Text("\(Int(alertThreshold * 100))%")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.primaryAction)
            }

            Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                .tint(SemanticColors.primaryAction)
                .accessibilityLabel("Budget alert threshold")
                .accessibilityValue("\(Int(alertThreshold * 100)) percent")

            Text("Alert when spending reaches \(Int(alertThreshold * 100))% of budget")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(8)
    }

    private var notificationPreferencesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Notification Preferences")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)

            SettingsToggle(
                title: "Email Notifications",
                description: "Receive updates via email",
                isOn: $emailNotifications
            )

            SettingsToggle(
                title: "Push Notifications",
                description: "Receive in-app notifications",
                isOn: $pushNotifications
            )

            Text("Reminder Types")
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(.top, Spacing.sm)

            SettingsToggle(
                title: "Task Reminders",
                description: "Get reminded about upcoming tasks",
                isOn: $taskReminders
            )

            SettingsToggle(
                title: "Payment Reminders",
                description: "Get reminded about payment due dates",
                isOn: $paymentReminders
            )

            SettingsToggle(
                title: "Event Reminders",
                description: "Get reminded about important dates",
                isOn: $eventReminders
            )
        }
    }

    private func loadExistingSettings() {
        let settings = store.defaultSettings
        selectedCurrency = settings.currency
        selectedTimezone = settings.timezone
        selectedColorScheme = settings.themePreferences?.colorScheme ?? "blush-romance"
        darkModeEnabled = settings.themePreferences?.darkMode ?? false

        if let budgetPrefs = settings.budgetPreferences {
            trackPayments = budgetPrefs.trackPayments
            enableBudgetAlerts = budgetPrefs.enableAlerts
            alertThreshold = budgetPrefs.alertThreshold
        }

        if let notifPrefs = settings.notificationPreferences {
            emailNotifications = notifPrefs.emailEnabled
            pushNotifications = notifPrefs.pushEnabled
            taskReminders = notifPrefs.taskReminders
            paymentReminders = notifPrefs.paymentReminders
            eventReminders = notifPrefs.eventReminders
        }
    }

    private func saveSettings() {
        let settings = OnboardingDefaultSettings(
            currency: selectedCurrency,
            timezone: selectedTimezone,
            themePreferences: ThemeSettings(
                colorScheme: selectedColorScheme,
                darkMode: darkModeEnabled
            ),
            budgetPreferences: BudgetPreferences(
                totalBudget: nil,
                trackPayments: trackPayments,
                enableAlerts: enableBudgetAlerts,
                alertThreshold: alertThreshold
            ),
            notificationPreferences: NotificationPreferences(
                emailEnabled: emailNotifications,
                pushEnabled: pushNotifications,
                taskReminders: taskReminders,
                paymentReminders: paymentReminders,
                eventReminders: eventReminders
            )
        )

        Task {
            await store.saveDefaultSettings(settings)
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(description)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(SemanticColors.primaryAction)
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(description)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Default Settings View") {
    DefaultSettingsView()
}

#Preview("Settings Toggle - On") {
    SettingsToggle(
        title: "Email Notifications",
        description: "Receive updates via email",
        isOn: .constant(true)
    )
    .padding()
}

#Preview("Settings Toggle - Off") {
    SettingsToggle(
        title: "Push Notifications",
        description: "Receive in-app notifications",
        isOn: .constant(false)
    )
    .padding()
}
