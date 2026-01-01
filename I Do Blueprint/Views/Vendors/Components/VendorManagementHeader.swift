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
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Title and subtitle
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Vendor Management")
                    .font(Typography.displayLarge)
                    .foregroundColor(AppColors.textPrimary)
                
                if windowSize != .compact {
                    Text("Manage and track all your vendors in one place")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Action buttons
            if windowSize == .compact {
                compactActionButtons
            } else {
                regularActionButtons
            }
        }
    }
    
    // MARK: - Compact Action Buttons
    
    private var compactActionButtons: some View {
        HStack(spacing: Spacing.sm) {
            // Combined Import/Export menu
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
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "ellipsis.circle")
                    Text("Import/Export")
                        .font(Typography.bodySmall)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // Add Vendor button (prominent)
            Button {
                showingAddVendor = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Vendor")
                        .font(Typography.bodySmall)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
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
            .tint(AppColors.primary)
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
