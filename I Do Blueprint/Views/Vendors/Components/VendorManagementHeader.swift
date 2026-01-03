//
//  VendorManagementHeader.swift
//  I Do Blueprint
//
//  Header component for Vendor Management with action buttons
//

import SwiftUI

struct VendorManagementHeader: View {
    let windowSize: WindowSize
    @Binding var showingImportSheet: Bool
    @Binding var showingExportOptions: Bool
    @Binding var showingAddVendor: Bool
    @ObservedObject var exportHandler: VendorExportHandler
    let vendors: [Vendor]
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Vendor Management")
                    .font(Typography.displaySmall)
                    .foregroundColor(SemanticColors.textPrimary)

                if windowSize != .compact {
                    Text("Manage and track all your vendors in one place")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: Spacing.sm) {
                if windowSize == .compact {
                    compactActionButtons
                } else {
                    regularActionButtons
                }
            }
        }
        .frame(height: 68)
    }
    
    // MARK: - Compact Action Buttons
    
    private var compactActionButtons: some View {
        HStack(spacing: Spacing.sm) {
            // Import/Export menu (icon only)
            Menu {
                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                }
                
                Button {
                    showingExportOptions = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .help("Import/Export")
            
            // Add Vendor button (icon only)
            Button {
                showingAddVendor = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.primaryAction)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .help("Add Vendor")
        }
        .confirmationDialog("Export Vendors", isPresented: $showingExportOptions) {
            Button("Export to CSV") {
                Task {
                    await exportHandler.exportVendors(vendors, format: .csv)
                }
            }
            Button("Export to Google Sheets") {
                Task {
                    await exportHandler.exportVendors(vendors, format: .googleSheets)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Regular Action Buttons
    
    private var regularActionButtons: some View {
        HStack(spacing: Spacing.md) {
            Button {
                showingImportSheet = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import CSV")
                }
            }
            .buttonStyle(.bordered)
            .help("Import vendors from CSV file")

            Button {
                showingExportOptions = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
            }
            .buttonStyle(.bordered)
            .disabled(vendors.isEmpty)
            .help("Export vendors to CSV or Google Sheets")

            Spacer()

            Button {
                showingAddVendor = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Vendor")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(SemanticColors.primaryAction)
            .help("Add a new vendor")
        }
        .confirmationDialog("Export Vendors", isPresented: $showingExportOptions) {
            Button("Export to CSV") {
                Task {
                    await exportHandler.exportVendors(vendors, format: .csv)
                }
            }
            Button("Export to Google Sheets") {
                Task {
                    await exportHandler.exportVendors(vendors, format: .googleSheets)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
