//
//  GuestEventDetailsTab.swift
//  I Do Blueprint
//
//  Event details tab content for guest detail view
//

import SwiftUI

struct GuestEventDetailsTab: View {
    let guest: Guest
    
    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            // Event Details
            VisualEventDetailsSection(guest: guest)
        }
    }
}
