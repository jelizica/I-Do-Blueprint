//
//  VendorContactTab.swift
//  I Do Blueprint
//
//  Contact tab content for vendor detail view
//

import SwiftUI

struct VendorContactTab: View {
    let vendor: Vendor
    @Binding var editedVendor: Vendor
    let isEditing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if let phone = vendor.phoneNumber {
                ContactRow(
                    icon: "phone.fill",
                    title: "Phone",
                    value: phone,
                    action: { URL(string: "tel:\(phone)") })
            }
            
            if let email = vendor.email {
                ContactRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: email,
                    action: { URL(string: "mailto:\(email)") })
            }
            
            if let website = vendor.website {
                ContactRow(
                    icon: "globe",
                    title: "Website",
                    value: website,
                    action: { URL(string: website) })
            }
        }
    }
}
