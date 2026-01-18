//
//  BudgetDevelopmentUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified responsive header for Budget Development page
//  Follows compact 56px bar pattern from BudgetOverviewUnifiedHeader
//  with glassmorphism styling
//

import SwiftUI

struct BudgetDevelopmentUnifiedHeader: View {
    let windowSize: WindowSize

    // Configuration bindings
    @Binding var selectedScenario: String
    @Binding var budgetName: String
    @Binding var selectedTaxRateId: Int64?
    @Binding var saving: Bool
    @Binding var uploading: Bool

    // Data
    let savedScenarios: [SavedScenario]
    let currentScenarioId: String?
    let taxRates: [TaxInfo]
    let isGoogleAuthenticated: Bool

    // Actions
    let onExportJSON: () -> Void
    let onExportCSV: () -> Void
    let onExportToGoogleDrive: () async -> Void
    let onExportToGoogleSheets: () async -> Void
    let onSignInToGoogle: () async -> Void
    let onSignOutFromGoogle: () -> Void
    let onSaveScenario: () async -> Void
    let onUploadScenario: () async -> Void
    let onLoadScenario: (String) async -> Void
    let onSetPrimaryScenario: (String) async -> Void
    let onShowRenameDialog: (String, String) -> Void
    let onShowDuplicateDialog: (String, String) -> Void
    let onShowDeleteDialog: (String, String) -> Void
    let onShowTaxRateDialog: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool { colorScheme == .dark }

    /// Current scenario display name
    private var currentScenarioName: String {
        if selectedScenario == "new" {
            return budgetName.isEmpty ? "New Scenario" : budgetName
        }
        return savedScenarios.first { $0.id == selectedScenario }?.scenarioName ?? "Select Scenario"
    }

    /// Current tax rate display
    private var currentTaxRateDisplay: String {
        guard let taxId = selectedTaxRateId,
              let rate = taxRates.first(where: { $0.id == taxId }) else {
            return "No Tax"
        }
        return "\(rate.region) (\(String(format: "%.1f", rate.taxRate * 100))%)"
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Left: Title section with icon badge
            HStack(spacing: Spacing.md) {
                // Title section with icon badge
                HStack(spacing: Spacing.sm) {
                    // Icon badge
                    Circle()
                        .fill(AppColors.Budget.allocated)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .shadow(color: AppColors.Budget.allocated.opacity(0.3), radius: 3, x: 0, y: 1)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text("Budget")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SemanticColors.textPrimary)

                        Text("Development")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Right: Scenario badge + Tax badge + ellipsis
            HStack(spacing: Spacing.md) {
                // Scenario context badge (regular mode)
                if windowSize != .compact {
                    scenarioBadge
                }

                // Tax rate badge (regular mode)
                if windowSize != .compact {
                    taxRateBadge
                }

                ellipsisMenu
            }
        }
        .frame(height: 56)
        .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(
            ZStack {
                // Base blur layer - glassmorphism
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Semi-transparent overlay
                Rectangle()
                    .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.3))

                // Subtle top glow
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
        .overlay(
            Divider()
                .foregroundColor(SemanticColors.borderLight),
            alignment: .bottom
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Scenario Badge

    private var scenarioBadge: some View {
        Menu {
            // Create new scenario option
            Button {
                selectedScenario = "new"
                Task { await onLoadScenario("new") }
            } label: {
                Label("Create New Scenario", systemImage: "plus")
                if selectedScenario == "new" {
                    Image(systemName: "checkmark")
                }
            }

            if !savedScenarios.isEmpty {
                Divider()

                // Existing scenarios
                ForEach(savedScenarios, id: \.id) { scenario in
                    Button {
                        selectedScenario = scenario.id
                        Task { await onLoadScenario(scenario.id) }
                    } label: {
                        HStack {
                            if scenario.isPrimary {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(scenario.scenarioName)
                            if scenario.id == selectedScenario {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                // Scenario management submenu
                if selectedScenario != "new" {
                    Divider()

                    Section("Manage Scenario") {
                        Button("Set as Primary") {
                            Task { await onSetPrimaryScenario(selectedScenario) }
                        }
                        .disabled(savedScenarios.first { $0.id == selectedScenario }?.isPrimary == true)

                        Button("Rename") {
                            if let scenario = savedScenarios.first(where: { $0.id == selectedScenario }) {
                                onShowRenameDialog(scenario.id, scenario.scenarioName)
                            }
                        }

                        Button("Duplicate") {
                            if let scenario = savedScenarios.first(where: { $0.id == selectedScenario }) {
                                onShowDuplicateDialog(scenario.id, "\(scenario.scenarioName) (Copy)")
                            }
                        }

                        Divider()

                        Button("Delete", role: .destructive) {
                            if let scenario = savedScenarios.first(where: { $0.id == selectedScenario }) {
                                onShowDeleteDialog(scenario.id, scenario.scenarioName)
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: selectedScenario == "new" ? "plus.circle.fill" : "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(selectedScenario == "new" ? AppColors.primary : .yellow)

                Text(currentScenarioName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(isDarkMode ? Color.white.opacity(0.05) : SemanticColors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Select or manage budget scenario")
    }

    // MARK: - Tax Rate Badge

    private var taxRateBadge: some View {
        Menu {
            ForEach(taxRates, id: \.id) { rate in
                Button {
                    selectedTaxRateId = rate.id
                } label: {
                    HStack {
                        Text("\(rate.region) (\(String(format: "%.2f", rate.taxRate * 100))%)")
                        if rate.id == selectedTaxRateId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                onShowTaxRateDialog()
            } label: {
                Label("Add Custom Rate", systemImage: "plus")
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "percent")
                    .font(.system(size: 11))
                    .foregroundColor(SemanticColors.textTertiary)

                Text(currentTaxRateDisplay)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(isDarkMode ? Color.white.opacity(0.05) : SemanticColors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Select default tax rate")
    }
    
    // MARK: - Ellipsis Menu

    private var ellipsisMenu: some View {
        Menu {
            // Save/Upload actions
            Button(action: { Task { await onSaveScenario() } }) {
                Label(saving ? "Saving..." : "Save Scenario", systemImage: "square.and.arrow.down.fill")
            }
            .disabled(saving)

            Button(action: { Task { await onUploadScenario() } }) {
                Label(uploading ? "Uploading..." : "Upload to Cloud", systemImage: "icloud.and.arrow.up")
            }
            .disabled(uploading || currentScenarioId == nil)

            Divider()

            // Export submenu
            Menu("Export") {
                Section(header: Text("Local Export")) {
                    Button(action: onExportJSON) {
                        Label("Export as JSON", systemImage: "doc.text")
                    }
                    Button(action: onExportCSV) {
                        Label("Export as CSV", systemImage: "tablecells")
                    }
                }

                Section(header: Text("Google Export")) {
                    if isGoogleAuthenticated {
                        Button(action: { Task { await onExportToGoogleDrive() } }) {
                            Label("Upload to Google Drive", systemImage: "folder")
                        }
                        Button(action: { Task { await onExportToGoogleSheets() } }) {
                            Label("Create Google Sheet", systemImage: "doc.on.doc")
                        }
                        Divider()
                        Button(action: onSignOutFromGoogle) {
                            Label("Sign Out from Google", systemImage: "person.crop.circle.badge.xmark")
                        }
                    } else {
                        Button(action: { Task { await onSignInToGoogle() } }) {
                            Label("Sign in to Google", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }
                }
            }

            // Compact mode: include scenario and tax rate selection
            if windowSize == .compact {
                Divider()

                Section("Scenario") {
                    Button {
                        selectedScenario = "new"
                        Task { await onLoadScenario("new") }
                    } label: {
                        Label("Create New Scenario", systemImage: "plus")
                        if selectedScenario == "new" {
                            Image(systemName: "checkmark")
                        }
                    }

                    ForEach(savedScenarios, id: \.id) { scenario in
                        Button {
                            selectedScenario = scenario.id
                            Task { await onLoadScenario(scenario.id) }
                        } label: {
                            HStack {
                                if scenario.isPrimary {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                Text(scenario.scenarioName)
                                if scenario.id == selectedScenario {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section("Tax Rate") {
                    ForEach(taxRates, id: \.id) { rate in
                        Button {
                            selectedTaxRateId = rate.id
                        } label: {
                            HStack {
                                Text("\(rate.region) (\(String(format: "%.1f", rate.taxRate * 100))%)")
                                if rate.id == selectedTaxRateId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Button {
                        onShowTaxRateDialog()
                    } label: {
                        Label("Add Custom Rate", systemImage: "plus")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help("More actions")
    }
}
