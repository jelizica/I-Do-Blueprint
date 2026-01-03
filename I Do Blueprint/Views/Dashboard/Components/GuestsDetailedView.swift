//
//  GuestsDetailedView.swift
//  I Do Blueprint
//
//  Detailed guest view with RSVP breakdown
//

import SwiftUI

struct GuestsDetailedView: View {
    @ObservedObject var store: GuestStoreV2

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Summary Cards
            HStack(spacing: Spacing.md) {
                let guests = store.guests
                let yesCount = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
                let pendingCount = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited || $0.rsvpStatus == .maybe }.count
                let noCount = guests.filter { $0.rsvpStatus == .declined }.count

                DashboardSummaryCard(
                    title: "Total Guests",
                    value: "\(guests.count)",
                    icon: "person.2.fill",
                    color: .blue
                )

                DashboardSummaryCard(
                    title: "Accepted",
                    value: "\(yesCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                DashboardSummaryCard(
                    title: "Pending",
                    value: "\(pendingCount)",
                    icon: "clock.fill",
                    color: .orange
                )

                DashboardSummaryCard(
                    title: "Declined",
                    value: "\(noCount)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
            }

            // Guest List
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Recent Guests")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                ForEach(Array(store.guests.prefix(10))) { guest in
                    DashboardGuestRow(guest: guest)

                    if guest.id != store.guests.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
                    .shadow(color: SemanticColors.shadowLight, radius: 8, y: 4)
            )
        }
    }
}

struct DashboardGuestRow: View {
    let guest: Guest

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(guest.fullName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                if let email = guest.email, !email.isEmpty {
                    Text(email)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()

            RSVPStatusBadge(status: guest.rsvpStatus)
        }
        .padding(.vertical, Spacing.sm)
    }
}

struct RSVPStatusBadge: View {
    let status: RSVPStatus

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = statusIcon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(statusColor)
            }

            Text(statusText)
                .font(Typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
    }

    private var statusText: String {
        switch status {
        case .invited: return "Invited"
        case .saveTheDateSent: return "Save the Date"
        case .invitationSent: return "Invited"
        case .reminded: return "Reminded"
        case .pending: return "Pending"
        case .attending: return "Attending"
        case .declined: return "Declined"
        case .maybe: return "Maybe"
        case .confirmed: return "Confirmed"
        case .noResponse: return "No Response"
        }
    }

    private var statusColor: Color {
        switch status {
        case .attending, .confirmed:
            return AppColors.Guest.confirmed
        case .declined:
            return AppColors.Guest.declined
        case .maybe:
            return AppColors.Guest.pending
        default:
            return SemanticColors.textSecondary
        }
    }

    private var statusIcon: String? {
        switch status {
        case .attending, .confirmed:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        case .maybe, .pending:
            return "clock.fill"
        default:
            return nil
        }
    }
}

#Preview {
    GuestsDetailedView(store: GuestStoreV2())
        .padding()
        .frame(width: 800)
}
