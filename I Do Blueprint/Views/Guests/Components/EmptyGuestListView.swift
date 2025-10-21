//
//  EmptyGuestListView.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct EmptyGuestListView: View {
    var onAddGuest: (() -> Void)? = nil

    var body: some View {
        SharedEmptyStateView(
            icon: "person.2.circle",
            title: "No Guests Yet",
            message: "Start building your guest list by adding your first guest. You can track RSVPs, meal preferences, plus-ones, and more.",
            actionTitle: onAddGuest != nil ? "Add Your First Guest" : nil,
            action: onAddGuest
        )
    }
}
