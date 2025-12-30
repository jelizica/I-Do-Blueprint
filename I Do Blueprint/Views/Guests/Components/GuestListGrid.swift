//
//  GuestListGrid.swift
//  I Do Blueprint
//
//  Grid display for guest list
//

import SwiftUI

struct GuestListGrid: View {
    let guests: [Guest]
    let settings: CoupleSettings
    let renderId: Int
    let onGuestTap: (Guest) -> Void
    let onAddGuest: () -> Void
    
    var body: some View {
        Group {
            if guests.isEmpty {
                GuestEmptyState(onAddGuest: onAddGuest)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg)
                ], spacing: Spacing.lg) {
                    ForEach(guests, id: \.id) { guest in
                        GuestCardV4(guest: guest, settings: settings)
                            .onTapGesture {
                                onGuestTap(guest)
                            }
                    }
                }
                .id(renderId)
            }
        }
    }
}

// MARK: - Empty State

struct GuestEmptyState: View {
    let onAddGuest: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)

            Text("No guests found")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Text("Add your first guest to get started")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)

            Button(action: onAddGuest) {
                Text("Add Guest")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.xl)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Error View

struct GuestErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(AppColors.error)

            Text("Error Loading Guests")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Text(error.localizedDescription)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Text("Try Again")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.xl)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
}
