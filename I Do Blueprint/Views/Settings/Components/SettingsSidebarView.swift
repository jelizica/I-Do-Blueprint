//
//  SettingsSidebarView.swift
//  I Do Blueprint
//
//  Sidebar navigation for settings sections
//  NOTE: This file is deprecated. Use SettingsView.swift instead.
//

import SwiftUI

struct SettingsSidebarView: View {
    @Binding var selectedSection: SettingsSection
    @Binding var selectedSubsection: AnySubsection
    @Binding var expandedSections: Set<SettingsSection>
    let onDeveloperTap: () -> Void
    
    var body: some View {
        List(selection: $selectedSection) {
            ForEach(SettingsSection.allCases) { section in
                subsectionGroup(for: section)
            }
        }
        .navigationTitle("Settings")
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        .onTapGesture(count: 5) {
            onDeveloperTap()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func subsectionGroup(for section: SettingsSection) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedSections.contains(section) },
                set: { isExpanded in
                    if isExpanded {
                        expandedSections.insert(section)
                    } else {
                        expandedSections.remove(section)
                    }
                }
            )
        ) {
            subsectionButtons(for: section)
        } label: {
            sectionLabel(for: section)
        }
    }
    
    @ViewBuilder
    private func subsectionButtons(for section: SettingsSection) -> some View {
        switch section {
        case .global:
            ForEach(GlobalSubsection.allCases) { subsection in
                subsectionButton(.global(subsection), for: section)
            }
        case .account:
            ForEach(AccountSubsection.allCases) { subsection in
                subsectionButton(.account(subsection), for: section)
            }
        case .budgetVendors:
            ForEach(BudgetVendorsSubsection.allCases) { subsection in
                subsectionButton(.budgetVendors(subsection), for: section)
            }
        case .guestsTasks:
            ForEach(GuestsTasksSubsection.allCases) { subsection in
                subsectionButton(.guestsTasks(subsection), for: section)
            }
        case .appearance:
            ForEach(AppearanceSubsection.allCases) { subsection in
                subsectionButton(.appearance(subsection), for: section)
            }
        case .dataContent:
            ForEach(DataContentSubsection.allCases) { subsection in
                subsectionButton(.dataContent(subsection), for: section)
            }
        case .developer:
            ForEach(DeveloperSubsection.allCases) { subsection in
                subsectionButton(.developer(subsection), for: section)
            }
        }
    }
    
    @ViewBuilder
    private func sectionLabel(for section: SettingsSection) -> some View {
        Label {
            Text(section.rawValue)
        } icon: {
            Image(systemName: section.icon)
                .foregroundColor(section.color)
        }
    }
    
    @ViewBuilder
    private func subsectionButton(_ subsection: AnySubsection, for section: SettingsSection) -> some View {
        Button(action: {
            selectedSection = section
            selectedSubsection = subsection
        }) {
            Label {
                Text(subsection.rawValue)
            } icon: {
                Image(systemName: subsection.icon)
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(.plain)
        .padding(.leading, 20)
        .background(
            (selectedSection == section && selectedSubsection == subsection)
                ? Color.accentColor.opacity(0.1)
                : Color.clear
        )
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        SettingsSidebarView(
            selectedSection: .constant(.global),
            selectedSubsection: .constant(.global(.overview)),
            expandedSections: .constant([.global]),
            onDeveloperTap: {}
        )
    } detail: {
        Text("Detail View")
    }
    .frame(width: 900, height: 600)
}
