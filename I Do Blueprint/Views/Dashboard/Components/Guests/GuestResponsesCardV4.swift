//
//  GuestResponsesCardV4.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Guest responses card showing RSVP statistics and recent guest list
//

import SwiftUI

struct GuestResponsesCardV4: View {
    @ObservedObject var store: GuestStoreV2

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Guest Responses")
                    .font(Typography.subheading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("\(respondedCount) of \(totalGuests) guests responded")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)

            Divider()

            // Stats
            HStack(spacing: Spacing.xl) {
                StatColumn(value: attendingCount, label: "Attending", color: SemanticColors.success)
                StatColumn(value: declinedCount, label: "Declined", color: SemanticColors.error)
                StatColumn(value: pendingCount, label: "Pending", color: SemanticColors.textSecondary)
            }
            .padding(.vertical, Spacing.md)

            Divider()

            // Recent Responses
            VStack(spacing: Spacing.md) {
                ForEach(store.guests.prefix(8)) { guest in
                    DashboardV4GuestRow(guest: guest)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 407)
        .background(SemanticColors.backgroundSecondary)
        .shadow(color: SemanticColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }

    private var totalGuests: Int {
        store.guests.count
    }

    private var attendingCount: Int {
        store.guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
    }

    private var declinedCount: Int {
        store.guests.filter { $0.rsvpStatus == .declined }.count
    }

    private var pendingCount: Int {
        store.guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited }.count
    }

    private var respondedCount: Int {
        attendingCount + declinedCount
    }
}
