//
//  VendorFinancialTab.swift
//  I Do Blueprint
//
//  Financial tab content for vendor detail view
//

import SwiftUI

struct VendorFinancialTab: View {
    let vendor: Vendor
    let vendorDetails: VendorDetails
    @Binding var editedVendor: Vendor
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 16) {
            if let amount = vendor.quotedAmount {
                FinancialRow(
                    title: "Quoted Amount",
                    amount: amount,
                    color: .blue)
            }

            if let paymentDate = vendorDetails.finalPaymentDue {
                DetailRow(
                    title: "Final Payment Due",
                    value: formatDate(paymentDate),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let nextPayment = vendorDetails.nextPaymentDue {
                DetailRow(
                    title: "Next Payment Due",
                    value: formatDate(nextPayment),
                    isEditing: false,
                    editValue: .constant(""))
            }

            if let paymentSummary = vendorDetails.paymentSummary {
                VStack(spacing: 12) {
                    FinancialRow(
                        title: "Total Amount",
                        amount: paymentSummary.totalAmount,
                        color: .blue)

                    FinancialRow(
                        title: "Paid Amount",
                        amount: paymentSummary.paidAmount,
                        color: .green)

                    FinancialRow(
                        title: "Remaining Amount",
                        amount: paymentSummary.remainingAmount,
                        color: .orange)
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        // Parse from database (UTC)
        guard let date = DateFormatting.parseDateFromDatabase(dateString) else {
            // Log parse failure for debugging
            AppLogger.ui.error("Failed to parse date string from database: '\(dateString)' for vendor '\(vendor.vendorName)' (ID: \(vendor.id))")
            return "Invalid Date" // Return clear placeholder instead of raw database string
        }
        
        // Format in user's timezone
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        return DateFormatting.formatDateMedium(date, timezone: userTimezone)
    }

    private func formatDate(_ date: Date) -> String {
        // Use user's timezone for date formatting
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        return DateFormatting.formatDateMedium(date, timezone: userTimezone)
    }
}
