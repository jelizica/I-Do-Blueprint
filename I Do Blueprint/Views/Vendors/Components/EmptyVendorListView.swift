//
//  EmptyVendorListView.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/9/25.
//  Empty state view for vendor list
//

import SwiftUI

struct EmptyVendorListView: View {
    var onAddVendor: (() -> Void)? = nil

    var body: some View {
        SharedEmptyStateView(
            icon: "briefcase.circle",
            title: "No Vendors Yet",
            message: "Keep track of all your wedding vendors in one place. Add vendors for catering, photography, venue, flowers, and more.",
            actionTitle: onAddVendor != nil ? "Add Your First Vendor" : nil,
            action: onAddVendor
        )
    }
}
