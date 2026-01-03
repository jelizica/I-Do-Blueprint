//
//  GuestManagementHeader.swift
//  I Do Blueprint
//
//  Header section for guest management view
//

import SwiftUI

struct GuestManagementHeader: View {
    let windowSize: WindowSize
    let onImport: () -> Void
    let onExport: () -> Void
    let onAddGuest: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Guest Management")
                    .font(Typography.displaySmall)
                    .foregroundColor(SemanticColors.textPrimary)

                if windowSize != .compact {
                    Text("Manage and track all your guests in one place")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: Spacing.sm) {
                if windowSize == .compact {
                    // Import/Export menu (icon only)
                    Menu {
                        Button(action: onImport) {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }

                        Button(action: onExport) {
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

                    // Add Guest button (icon only)
                    Button(action: onAddGuest) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(SemanticColors.primaryAction)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Add Guest")
                } else {
                    // Regular/Large: All buttons with text
                    Button(action: onImport) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                            Text("Import")
                                .font(Typography.bodyRegular)
                        }
                        .foregroundColor(SemanticColors.textPrimary)
                        .frame(height: 42)
                        .padding(.horizontal, Spacing.lg)
                        .background(SemanticColors.backgroundSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(SemanticColors.borderPrimaryLight, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onExport) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text("Export")
                                .font(Typography.bodyRegular)
                        }
                        .foregroundColor(SemanticColors.textPrimary)
                        .frame(height: 42)
                        .padding(.horizontal, Spacing.lg)
                        .background(SemanticColors.backgroundSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(SemanticColors.borderPrimaryLight, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onAddGuest) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Add Guest")
                                .font(Typography.bodyRegular)
                        }
                        .foregroundColor(SemanticColors.textPrimary)
                        .frame(height: 42)
                        .padding(.horizontal, Spacing.xl)
                        .background(SemanticColors.primaryAction)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 68)
    }
}
