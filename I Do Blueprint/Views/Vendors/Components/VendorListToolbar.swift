//
//  VendorListToolbar.swift
//  My Wedding Planning App
//
//  Toolbar component for vendor list with export and add actions
//  Created by Claude Code on 1/9/25.
//

import SwiftUI

struct VendorListToolbar: ToolbarContent {
    let exportableCount: Int
    let isExporting: Bool
    let onExport: (VendorExportFormat) async -> Void
    let onImport: () -> Void
    let onAdd: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            HStack(spacing: Spacing.sm) {
                // Export menu
                Menu {
                    Text("\(exportableCount) vendors marked for export")
                        .foregroundColor(.secondary)

                    Divider()

                    ForEach(VendorExportFormat.allCases, id: \.self) { format in
                        Button {
                            Task {
                                await onExport(format)
                            }
                        } label: {
                            Label(format.rawValue, systemImage: format.iconName)
                        }
                        .disabled(exportableCount == 0)
                        .accessibilityLabel("Export to \(format.rawValue)")
                        .accessibilityHint(exportableCount == 0 ? "No vendors marked for export" : "Exports \(exportableCount) vendors")
                    }

                    Divider()

                    Button("Manage Export Flags...") {
                        // Informational button - handled in detail view
                    }
                    .disabled(true)
                    .accessibilityLabel("Manage Export Flags")
                    .accessibilityHint("Configure which vendors to include in exports")
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isExporting)
                .help("Export vendor contact information")
                .accessibilityLabel("Export Vendors")
                .accessibilityValue("\(exportableCount) vendors available")

                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                        .accessibilityLabel("Exporting vendors")
                }
                
                // Import button
                Button {
                    onImport()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                    }
                }
                .buttonStyle(.bordered)
                .help("Import vendors from CSV file")
                .accessibilityLabel("Import Vendors")
                .accessibilityHint("Opens CSV import dialog")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                onAdd()
            } label: {
                Label("Add Vendor", systemImage: "plus.circle.fill")
            }
            .keyboardShortcut("n", modifiers: .command)
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add New Vendor")
            .accessibilityHint("Opens form to add a new vendor")
        }
    }
}
