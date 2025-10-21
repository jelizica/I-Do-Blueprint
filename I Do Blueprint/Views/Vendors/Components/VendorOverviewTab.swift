//
//  VendorOverviewTab.swift
//  I Do Blueprint
//
//  Overview tab content for vendor detail view
//

import SwiftUI

struct VendorOverviewTab: View {
    let vendor: Vendor
    @Binding var editedVendor: Vendor
    let isEditing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            DetailRow(
                title: "Vendor Type",
                value: vendor.vendorType ?? "Not specified",
                isEditing: isEditing,
                editValue: Binding(
                    get: { editedVendor.vendorType ?? "" },
                    set: { editedVendor.vendorType = $0.isEmpty ? nil : $0 }))
            
            if let address = vendor.address {
                DetailRow(
                    title: "Address",
                    value: address,
                    isEditing: isEditing,
                    editValue: Binding(
                        get: { editedVendor.address ?? "" },
                        set: { _ in
                            // Note: address is a computed property that returns nil
                            // In a real implementation, this would update the appropriate database field
                        }))
            }
            
            if let description = vendor.businessDescription {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Business Description")
                        .font(.headline)
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if let notes = vendor.notes {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
