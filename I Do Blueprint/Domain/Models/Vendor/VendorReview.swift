import Foundation

/// Represents a review for a vendor
struct VendorReview: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let vendorId: Int64
    let coupleId: UUID

    // Review content
    var rating: Int // 1-5 stars
    var reviewTitle: String?
    var reviewText: String?
    var reviewerName: String?
    var reviewerEmail: String?
    var weddingDate: Date?

    // Detailed ratings
    var communicationRating: Int?
    var qualityRating: Int?
    var valueRating: Int?

    // Status
    var isVerified: Bool
    var wouldRecommend: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case vendorId = "vendor_id"
        case coupleId = "couple_id"
        case rating
        case reviewTitle = "review_title"
        case reviewText = "review_text"
        case reviewerName = "reviewer_name"
        case reviewerEmail = "reviewer_email"
        case weddingDate = "wedding_date"
        case communicationRating = "communication_rating"
        case qualityRating = "quality_rating"
        case valueRating = "value_rating"
        case isVerified = "is_verified"
        case wouldRecommend = "would_recommend"
    }
}

/// Aggregated review statistics for a vendor
struct VendorReviewStats: Codable, Hashable {
    let avgRating: Double
    let reviewCount: Int
    let avgCommunicationRating: Double?
    let avgQualityRating: Double?
    let avgValueRating: Double?
    let recommendationRate: Double? // Percentage who would recommend
}
