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
