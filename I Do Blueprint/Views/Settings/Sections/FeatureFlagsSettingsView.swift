//
//  FeatureFlagsSettingsView.swift
//  I Do Blueprint
//
//  Admin view for managing feature flags
//

import SwiftUI

struct FeatureFlagsSettingsView: View {
    @State private var featureStatus: [String: Bool] = [:]
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section {
                Text("Feature Flags")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enable or disable features for testing. Changes take effect immediately.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Store Architecture") {
                FeatureFlagToggle(
                    title: "Budget Store V2",
                    description: "Use new repository-based budget store",
                    isEnabled: featureStatus["BudgetStoreV2"] ?? false,
                    onToggle: { enabled in
                        if enabled {
                            FeatureFlags.enableBudgetStoreV2()
                        } else {
                            FeatureFlags.disableBudgetStoreV2()
                        }
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Guest Store V2",
                    description: "Use new repository-based guest store",
                    isEnabled: featureStatus["GuestStoreV2"] ?? false,
                    onToggle: { enabled in
                        if enabled {
                            FeatureFlags.enableGuestStoreV2()
                        } else {
                            FeatureFlags.disableGuestStoreV2()
                        }
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Vendor Store V2",
                    description: "Use new repository-based vendor store",
                    isEnabled: featureStatus["VendorStoreV2"] ?? false,
                    onToggle: { enabled in
                        if enabled {
                            FeatureFlags.enableVendorStoreV2()
                        } else {
                            FeatureFlags.disableVendorStoreV2()
                        }
                        refreshStatus()
                    }
                )
            }

            Section("Completed Features ✅") {
                FeatureFlagToggle(
                    title: "Timeline Milestones",
                    description: "View all milestones feature",
                    isEnabled: featureStatus["TimelineMilestones"] ?? true,
                    onToggle: { enabled in
                        FeatureFlags.setTimelineMilestones(enabled: enabled)
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Advanced Budget Export",
                    description: "PDF/CSV export with detailed reports",
                    isEnabled: featureStatus["AdvancedBudgetExport"] ?? true,
                    onToggle: { enabled in
                        FeatureFlags.setAdvancedBudgetExport(enabled: enabled)
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Visual Planning Paste",
                    description: "Copy/paste elements in mood boards",
                    isEnabled: featureStatus["VisualPlanningPaste"] ?? true,
                    onToggle: { enabled in
                        FeatureFlags.setVisualPlanningPaste(enabled: enabled)
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Image Picker",
                    description: "Add images to mood boards",
                    isEnabled: featureStatus["ImagePicker"] ?? true,
                    onToggle: { enabled in
                        FeatureFlags.setImagePicker(enabled: enabled)
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Template Application",
                    description: "Apply mood board templates",
                    isEnabled: featureStatus["TemplateApplication"] ?? true,
                    onToggle: { enabled in
                        FeatureFlags.setTemplateApplication(enabled: enabled)
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Expense Details",
                    description: "View detailed expense information",
                    isEnabled: featureStatus["ExpenseDetails"] ?? true,
                    onToggle: { enabled in
                        FeatureFlags.setExpenseDetails(enabled: enabled)
                        refreshStatus()
                    }
                )

                FeatureFlagToggle(
                    title: "Budget Analytics Actions",
                    description: "Insight actions in budget analytics",
                    isEnabled: featureStatus["BudgetAnalyticsActions"] ?? true,
                    onToggle: { enabled in
                        FeatureFlags.setBudgetAnalyticsActions(enabled: enabled)
                        refreshStatus()
                    }
                )
            }

            Section {
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset All Feature Flags")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            refreshStatus()
        }
        .alert("Reset All Feature Flags?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                FeatureFlags.resetAll()
                refreshStatus()
            }
        } message: {
            Text("This will reset all feature flags to their default values. The app may need to be restarted for changes to take effect.")
        }
    }

    private func refreshStatus() {
        featureStatus = FeatureFlags.status()
    }
}

struct FeatureFlagToggle: View {
    let title: String
    let description: String
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            )) {
                Text(title)
                    .font(.body)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    FeatureFlagsSettingsView()
}
