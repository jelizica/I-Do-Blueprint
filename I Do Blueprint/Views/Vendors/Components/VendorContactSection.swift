//
//  VendorContactSection.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct VendorContactSection: View {
    let vendor: Vendor

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Contact",
                icon: "envelope.circle.fill",
                color: .blue
            )

            VStack(spacing: Spacing.sm) {
                if let contactName = vendor.contactName {
                    GuestContactRow(
                        icon: "person.fill",
                        label: "Contact Person",
                        value: contactName,
                        color: .purple
                    )
                }

                if let email = vendor.email {
                    GuestContactRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        color: .blue
                    )
                }

                if let phone = vendor.phoneNumber {
                    GuestContactRow(
                        icon: "phone.fill",
                        label: "Phone",
                        value: phone,
                        color: .green
                    )
                }

                if let website = vendor.website {
                    GuestContactRow(
                        icon: "globe",
                        label: "Website",
                        value: website,
                        color: .cyan
                    )
                }
            }
        }
    }
}
