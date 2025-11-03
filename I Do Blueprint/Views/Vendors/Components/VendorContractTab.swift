//
//  VendorContractTab.swift
//  I Do Blueprint
//
//  Contract tab content for vendor detail view
//

import SwiftUI

struct VendorContractTab: View {
    let vendor: Vendor
    let vendorDetails: VendorDetails
    @Binding var editedVendor: Vendor
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 16) {
            if vendorDetails.contractStatus != .none {
                DetailRow(
                    title: "Contract Status",
                    value: vendorDetails.contractStatus.displayName,
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let signedDate = vendorDetails.contractSignedDate {
                DetailRow(
                    title: "Contract Signed",
                    value: formatDate(signedDate),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let expiryDate = vendorDetails.contractExpiryDate {
                DetailRow(
                    title: "Contract Expires",
                    value: formatDate(expiryDate),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let bookingDate = vendor.bookingDate {
                DetailRow(
                    title: "Booking Date",
                    value: formatDate(bookingDate),
                    isEditing: false,
                    editValue: .constant(""))
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }

        return dateString
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
