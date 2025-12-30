//
//  VendorManagementHeader.swift
//  I Do Blueprint
//
//  Header component for Vendor Management with action buttons
//

import SwiftUI

struct VendorManagementHeader: View {
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
                    .foregroundColor(AppColors.textPrimary)

                Text("Manage and track all your vendors in one place")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 12) {
                importButton
                exportButton
                addVendorButton
            }
        }
        .frame(height: 68)
    }
    
    // MARK: - Action Buttons
    
    private var importButton: some View {
        Button {
            showingImportSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 14))
                Text("Import")
                    .font(Typography.bodyRegular)
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(height: 42)
            .padding(.horizontal, Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.borderLight, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibleActionButton(
            label: "Import vendors",
            hint: "Import vendors from CSV or Excel file"
        )
    }
    
    private var exportButton: some View {
        Button {
            showingExportOptions = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                Text("Export")
                    .font(Typography.bodyRegular)
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(height: 42)
            .padding(.horizontal, Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.borderLight, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibleActionButton(
            label: "Export vendors",
            hint: "Export vendor list to CSV or Google Sheets"
        )
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
    
    private var addVendorButton: some View {
        Button {
            showingAddVendor = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                Text("Add Vendor")
                    .font(Typography.bodyRegular)
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(height: 42)
            .padding(.horizontal, Spacing.xl)
            .background(AppColors.primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibleActionButton(
            label: "Add new vendor",
            hint: "Create a new vendor entry"
        )
    }
}
