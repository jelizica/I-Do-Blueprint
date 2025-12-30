//
//  SettingsSidebarView.swift
//  I Do Blueprint
//
//  Sidebar navigation for settings sections
//

import SwiftUI

struct SettingsSidebarView: View {
    @Binding var selectedSection: SettingsSection
    @Binding var selectedGlobalSubsection: GlobalSubsection
    @Binding var expandedSections: Set<SettingsSection>
    let onDeveloperTap: () -> Void
    
    var body: some View {
        List(selection: $selectedSection) {
            ForEach(SettingsSection.allCases) { section in
                if section.hasSubsections {
                    subsectionGroup(for: section)
                } else {
                    sectionLink(for: section)
                }
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
            ForEach(GlobalSubsection.allCases) { subsection in
                subsectionButton(for: section, subsection: subsection)
            }
        } label: {
            sectionLabel(for: section)
        }
    }
    
    @ViewBuilder
    private func sectionLink(for section: SettingsSection) -> some View {
        NavigationLink(value: section) {
            sectionLabel(for: section)
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
    private func subsectionButton(for section: SettingsSection, subsection: GlobalSubsection) -> some View {
        Button(action: {
            selectedSection = section
            selectedGlobalSubsection = subsection
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
            selectedSection == section && selectedGlobalSubsection == subsection
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
            selectedGlobalSubsection: .constant(.overview),
            expandedSections: .constant([.global]),
            onDeveloperTap: {}
        )
    } detail: {
        Text("Detail View")
    }
    .frame(width: 900, height: 600)
}
