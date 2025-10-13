import Foundation

/// Represents contract information from vendor_documents table
struct VendorContract: Codable, Hashable {
    let vendorId: Int64
    let contractSignedDate: Date?
    let contractExpiryDate: Date?
    let contractStatus: ContractStatus

    private enum CodingKeys: String, CodingKey {
        case vendorId = "vendor_id"
        case contractSignedDate = "contract_signed_date"
        case contractExpiryDate = "contract_expiry_date"
        case contractStatus = "contract_status"
    }
}
