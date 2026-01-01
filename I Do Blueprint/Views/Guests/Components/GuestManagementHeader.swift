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
                    .foregroundColor(AppColors.textPrimary)

                if windowSize != .compact {
                    Text("Manage and track all your guests in one place")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 12) {
                if windowSize == .compact {
                    // Compact: Menu with Import/Export
                    Menu {
                        Button(action: onImport) {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }

                        Button(action: onExport) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 42, height: 42)
                            .background(AppColors.cardBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.borderLight, lineWidth: 0.5)
                            )
                    }
                    .menuStyle(.borderlessButton)

                    // Add Guest Button (icon-only in compact)
                    Button(action: onAddGuest) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 42, height: 42)
                            .background(AppColors.primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Regular/Large: All buttons with text
                    Button(action: onImport) {
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

                    Button(action: onExport) {
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

                    Button(action: onAddGuest) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Add Guest")
                                .font(Typography.bodyRegular)
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .frame(height: 42)
                        .padding(.horizontal, Spacing.xl)
                        .background(AppColors.primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 68)
    }
}
