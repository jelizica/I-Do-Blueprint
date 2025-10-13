import Foundation

/// Summary of payment information for a vendor (from vendor_payment_summary view)
struct VendorPaymentSummary: Codable, Hashable {
    let vendorId: Int64
    let totalAmount: Double
    let paidAmount: Double
    let remainingAmount: Double
    let nextPaymentDue: Date?
    let finalPaymentDue: Date?

    private enum CodingKeys: String, CodingKey {
        case vendorId = "vendor_id"
        case totalAmount = "total_amount"
        case paidAmount = "paid_amount"
        case remainingAmount = "remaining_amount"
        case nextPaymentDue = "next_payment_due"
        case finalPaymentDue = "final_payment_due"
    }
}
