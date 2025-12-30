//
//  BasicInformationSection.swift
//  I Do Blueprint
//
//  Component for vendor basic information fields
//

import SwiftUI

struct BasicInformationSection: View {
    @Binding var vendorName: String
    @Binding var vendorType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VendorSectionHeader(title: "Basic Information", icon: "info.circle.fill")
            
            VStack(spacing: Spacing.lg) {
                VendorFormField(label: "Business Name", required: true) {
                    TextField("Enter business name", text: $vendorName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VendorFormField(label: "Service Type") {
                    TextField("e.g., Photography, Catering", text: $vendorType)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}

#Preview {
    BasicInformationSection(
        vendorName: .constant("Sample Photography"),
        vendorType: .constant("Photography")
    )
    .padding()
}
