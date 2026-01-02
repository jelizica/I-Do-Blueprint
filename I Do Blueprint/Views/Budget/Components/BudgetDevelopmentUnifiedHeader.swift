//
//  BudgetDevelopmentUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified header for Budget Development page that combines:
//  - "Budget" title with "Budget Development" subtitle
//  - Ellipsis menu (left of nav dropdown)
//  - Navigation dropdown
//  - Configuration form fields
//

import SwiftUI

struct BudgetDevelopmentUnifiedHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage
    
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

    var body: some View {
        VStack(spacing: windowSize == .compact ? Spacing.md : Spacing.lg) {
            // Unified title row
            titleRow
            
            // Configuration form fields
            if windowSize == .compact {
                compactFormFields
            } else {
                regularFormFields
            }
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Title Row
    
    private var titleRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget")
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)

                // Subtitle: "Budget Development" (less bold)
                Text("Budget Development")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Actions: ellipsis menu + nav dropdown
            HStack(spacing: Spacing.sm) {
                // Ellipsis menu (left of nav dropdown)
                ellipsisMenu
                
                // Navigation dropdown
                budgetPageDropdown
            }
        }
    }
    
    // MARK: - Ellipsis Menu
    
    private var ellipsisMenu: some View {
        Menu {
            Button(action: { Task { await onSaveScenario() } }) {
                Label(saving ? "Saving..." : "Save", systemImage: "square.and.arrow.down.fill")
            }
            .disabled(saving)
            
            Button(action: { Task { await onUploadScenario() } }) {
                Label(uploading ? "Uploading..." : "Upload", systemImage: "square.and.arrow.up")
            }
            .disabled(uploading || currentScenarioId == nil)
            
            Divider()
            
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
                            Label("Upload to Google Drive", systemImage: "icloud.and.arrow.up")
                        }
                        Button(action: { Task { await onExportToGoogleSheets() } }) {
                            Label("Create Google Sheet", systemImage: "doc.on.doc")
                        }
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
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(AppColors.textPrimary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation Dropdown
    
    private var budgetPageDropdown: some View {
        Menu {
            // Dashboard (always first, outside sections)
            Button {
                currentPage = .hub
            } label: {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
                if currentPage == .hub {
                    Image(systemName: "checkmark")
                }
            }
            .keyboardShortcut("1", modifiers: [.command])

            Divider()

            // All sections with all pages visible
            ForEach(BudgetGroup.allCases) { group in
                Section(group.rawValue) {
                    ForEach(group.pages) { page in
                        Button {
                            currentPage = page
                        } label: {
                            Label(page.rawValue, systemImage: page.icon)
                            if currentPage == page {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: currentPage.icon)
                    .font(.system(size: windowSize == .compact ? 20 : 16))
                if windowSize != .compact {
                    Text(currentPage.rawValue)
                        .font(.headline)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(width: windowSize == .compact ? 44 : nil, height: 44)
        }
        .buttonStyle(.plain)
        .help("Navigate budget pages")
    }
    
    // MARK: - Form Fields (Compact)
    
    @ViewBuilder
    private var compactFormFields: some View {
        VStack(spacing: Spacing.md) {
            // Scenario selector (full width)
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget Scenario")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Picker("Scenario", selection: $selectedScenario) {
                        Text("Create New Scenario").tag("new")
                        ForEach(savedScenarios, id: \.id) { scenario in
                            HStack {
                                if scenario.isPrimary {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                Text(scenario.scenarioName)
                            }
                            .tag(scenario.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedScenario) {
                        Task { await onLoadScenario(selectedScenario) }
                    }
                    
                    if selectedScenario != "new" {
                        scenarioActionsMenu
                    }
                }
            }
            
            // Scenario name (only for new)
            if selectedScenario == "new" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scenario Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Enter scenario name", text: $budgetName)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Tax rate selector (full width)
            VStack(alignment: .leading, spacing: 4) {
                Text("Default Tax Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Picker("Tax Rate", selection: $selectedTaxRateId) {
                        ForEach(taxRates, id: \.id) { rate in
                            Text("\(rate.region) (\(String(format: "%.2f", rate.taxRate * 100))%)")
                                .tag(rate.id as Int64?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button("Add") { onShowTaxRateDialog() }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Form Fields (Regular)
    
    @ViewBuilder
    private var regularFormFields: some View {
        VStack(spacing: Spacing.md) {
            // Actions row (Export, Save, Upload buttons)
            HStack {
                Spacer()
                regularActionsRow
            }
            
            // Form fields row
            HStack(spacing: 16) {
                // Scenario selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Scenario")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Picker("Scenario", selection: $selectedScenario) {
                            Text("Create New Scenario").tag("new")
                            ForEach(savedScenarios, id: \.id) { scenario in
                                HStack {
                                    if scenario.isPrimary {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    Text(scenario.scenarioName)
                                }
                                .tag(scenario.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedScenario) {
                            Task { await onLoadScenario(selectedScenario) }
                        }

                        if selectedScenario != "new" {
                            scenarioActionsMenu
                        }
                    }
                }

                // Scenario name (for new scenarios)
                if selectedScenario == "new" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scenario Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Enter scenario name", text: $budgetName)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                // Tax rate selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Tax Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Picker("Tax Rate", selection: $selectedTaxRateId) {
                            ForEach(taxRates, id: \.id) { rate in
                                Text("\(rate.region) (\(String(format: "%.2f", rate.taxRate * 100))%)")
                                    .tag(rate.id as Int64?)
                            }
                        }
                        .pickerStyle(.menu)

                        Button("Add Rate") {
                            onShowTaxRateDialog()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
    
    // MARK: - Regular Actions Row
    
    @ViewBuilder
    private var regularActionsRow: some View {
        HStack(spacing: 8) {
            Menu {
                Section(header: Text("Local Export")) {
                    Button(action: onExportJSON) {
                        Label("Export as JSON", systemImage: "doc.text")
                    }
                    Button(action: onExportCSV) {
                        Label("Export as CSV (Excel)", systemImage: "tablecells")
                    }
                }

                Section(header: Text("Google Export")) {
                    if isGoogleAuthenticated {
                        Button(action: { Task { await onExportToGoogleDrive() } }) {
                            Label("Upload to Google Drive", systemImage: "icloud.and.arrow.up")
                        }
                        Button(action: { Task { await onExportToGoogleSheets() } }) {
                            Label("Create Google Sheet", systemImage: "doc.on.doc")
                        }
                        Button(action: onSignOutFromGoogle) {
                            Label("Sign Out from Google", systemImage: "person.crop.circle.badge.xmark")
                        }
                    } else {
                        Button(action: { Task { await onSignInToGoogle() } }) {
                            Label("Sign in to Google", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Export")
                }
            }
            .buttonStyle(.bordered)

            Button(action: { Task { await onSaveScenario() } }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text(saving ? "Saving..." : "Save")
                }
            }
            .buttonStyle(.bordered)
            .disabled(saving)

            Button(action: { Task { await onUploadScenario() } }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text(uploading ? "Uploading..." : "Upload")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(uploading || currentScenarioId == nil)
        }
    }
    
    // MARK: - Scenario Actions Menu
    
    @ViewBuilder
    private var scenarioActionsMenu: some View {
        Menu {
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
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
