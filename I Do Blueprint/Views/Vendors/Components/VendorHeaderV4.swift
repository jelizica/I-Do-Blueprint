//
//  VendorHeaderV4.swift
//  I Do Blueprint
//
//  Premium header component for Vendor Management V4
//

import SwiftUI

struct VendorHeaderV4: View {
    let windowSize: WindowSize
    @Binding var showingImportSheet: Bool
    @Binding var showingExportOptions: Bool
    @Binding var showingAddVendor: Bool
    @ObservedObject var exportHandler: VendorExportHandler
    let vendors: [Vendor]

    var body: some View {
        HStack(alignment: .center) {
            // Title and Description
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Vendor Management")
                    .font(Typography.displaySmall)
                    .foregroundColor(SemanticColors.textPrimary)

                if windowSize != .compact {
                    Text("Manage and track all your wedding vendors in one place")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()

            // Action Buttons
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
            // Import/Export menu
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

            // Add Vendor button
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
            // Import button
            Button {
                showingImportSheet = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import")
                }
                .font(Typography.bodySmall)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )
            .help("Import vendors from CSV file")

            // Export button
            Button {
                showingExportOptions = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .font(Typography.bodySmall)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )
            .disabled(vendors.isEmpty)
            .opacity(vendors.isEmpty ? 0.5 : 1)
            .help("Export vendors to CSV or Google Sheets")

            // Add Vendor button (primary action)
            Button {
                showingAddVendor = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus")
                    Text("Add Vendor")
                }
                .font(Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(SemanticColors.primaryAction)
            )
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
