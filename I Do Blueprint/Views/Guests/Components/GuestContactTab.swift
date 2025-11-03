//
//  GuestContactTab.swift
//  I Do Blueprint
//
//  Contact tab content for guest detail view
//

import SwiftUI

struct GuestContactTab: View {
    let guest: Guest

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            if hasContactInfo {
                VisualContactSection(guest: guest)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "envelope.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Contact Information")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add email, phone, or address to this guest's profile.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    private var hasContactInfo: Bool {
        guest.email != nil || guest.phone != nil || guest.addressLine1 != nil
    }
}
