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

    /// User's configured timezone - single source of truth for date formatting
    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    }

    private func formatDate(_ dateString: String) -> String {
        // Parse from database (UTC)
        guard let date = DateFormatting.parseDateFromDatabase(dateString) else {
            return dateString // Return original string if parsing fails
        }
        
        // Format in user's timezone
        return DateFormatting.formatDateMedium(date, timezone: userTimezone)
    }

    private func formatDate(_ date: Date) -> String {
        // Use user's timezone for date formatting
        return DateFormatting.formatDateMedium(date, timezone: userTimezone)
    }
}
