//
//  ContactInformationSection.swift
//  I Do Blueprint
//
//  Component for vendor contact information fields
//

import SwiftUI

struct ContactInformationSection: View {
    @Binding var contactName: String
    @Binding var email: String
    @Binding var phoneNumber: String
    @Binding var website: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VendorSectionHeader(title: "Contact Information", icon: "envelope.circle.fill")
            
            VStack(spacing: Spacing.lg) {
                VendorFormField(label: "Contact Person") {
                    TextField("Contact name", text: $contactName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VendorFormField(label: "Email") {
                    TextField("contact@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                }
                
                VendorFormField(label: "Phone") {
                    TextField("(555) 123-4567", text: $phoneNumber)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                }
                
                VendorFormField(label: "Website") {
                    TextField("https://example.com", text: $website)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                }
            }
        }
    }
}

#Preview {
    ContactInformationSection(
        contactName: .constant("John Doe"),
        email: .constant("john@example.com"),
        phoneNumber: .constant("(555) 123-4567"),
        website: .constant("https://example.com")
    )
    .padding()
}
