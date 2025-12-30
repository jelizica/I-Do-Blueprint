//
//  VendorBasicInfoSection.swift
//  I Do Blueprint
//
//  Component for vendor basic information fields
//

import SwiftUI

struct VendorBasicInfoSection: View {
    @Binding var vendorName: String
    @Binding var vendorType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Basic Information", icon: "info.circle.fill")
            
            VStack(spacing: Spacing.lg) {
                FormField(label: "Business Name", required: true) {
                    TextField("Enter business name", text: $vendorName)
                        .textFieldStyle(.roundedBorder)
                }
                
                FormField(label: "Service Type") {
                    TextField("e.g., Photography, Catering", text: $vendorType)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}

#Preview {
    VendorBasicInfoSection(
        vendorName: .constant("Sample Vendor"),
        vendorType: .constant("Photography")
    )
    .padding()
}
