//
//  SidebarCards.swift
//  I Do Blueprint
//
//  Card components for modern sidebar
//

import SwiftUI

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.seatingAccentTeal)
                Text(title)
                    .font(.seatingH4)
            }

            Divider()

            content
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.textPrimary)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Assignment Progress Card

struct AssignmentProgressCard: View {
    let assigned: Int
    let total: Int

    private var progress: Double {
        total > 0 ? Double(assigned) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assignment Progress")
                    .font(.seatingH4)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.seatingH3)
                    .foregroundColor(.seatingAccentTeal)
            }

            ProgressView(value: progress)
                .tint(.seatingAccentTeal)

            Text("\(assigned) of \(total) guests assigned")
                .font(.seatingCaption)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.textPrimary)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.seatingH2)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.seatingCaption)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Conflict Card

struct ConflictCard: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.seatingError)

            Text("\(count) seating \(count == 1 ? "conflict" : "conflicts") detected")
                .font(.seatingBodyMedium)

            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.seatingError.opacity(0.1))
        )
    }
}

// MARK: - Unassigned Guests Panel

struct UnassignedGuestsPanel: View {
    let guests: [SeatingGuest]
    let searchText: String

    var filteredGuests: [SeatingGuest] {
        if searchText.isEmpty {
            return guests
        }
        return guests.filter { guest in
            "\(guest.firstName) \(guest.lastName)".localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        SectionCard(title: "Unassigned (\(guests.count))", icon: "person.crop.circle.badge.exclamationmark") {
            if guests.isEmpty {
                SidebarEmptyStateView(
                    icon: "checkmark.circle",
                    message: "All guests assigned!",
                    action: nil
                ) {}
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredGuests.prefix(10)) { guest in
                        UnassignedGuestRow(guest: guest)
                    }

                    if filteredGuests.count > 10 {
                        Text("+ \(filteredGuests.count - 10) more")
                            .font(.seatingCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
