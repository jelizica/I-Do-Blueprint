//
//  TimelineDataTransformer.swift
//  I Do Blueprint
//
//  Transforms database rows into TimelineItem models
//

import Foundation

/// Service for transforming database rows into TimelineItem models
struct TimelineDataTransformer {
    private static let logger = AppLogger.api
    
    // MARK: - Payment Transformation
    
    struct PaymentRow: Codable {
        let id: Int
        let vendor: String?
        let paymentDate: String?
        let paymentAmount: Double?
        let paid: Bool?
        let notes: String?
        let vendorType: String?
        let coupleId: String?
        let createdAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id, vendor, notes
            case paymentDate = "payment_date"
            case paymentAmount = "payment_amount"
            case paid
            case vendorType = "vendor_type"
            case coupleId = "couple_id"
            case createdAt = "created_at"
        }
    }
    
    static func transformPayments(_ rows: [PaymentRow]) -> [TimelineItem] {
        logger.debug("Transforming \(rows.count) payment rows")
        
        let items = rows.compactMap { row -> TimelineItem? in
            // Skip if missing required fields
            guard let paymentDateString = row.paymentDate,
                  let date = TimelineDateParser.dateFromString(paymentDateString),
                  let amount = row.paymentAmount else {
                return nil
            }
            
            let coupleId = row.coupleId.flatMap { UUID(uuidString: $0) } ?? UUID()
            let createdAt = row.createdAt.flatMap { TimelineDateParser.iso8601DateFromString($0) } ?? Date()
            
            let title = "\(row.vendor ?? "Payment") - $\(String(format: "%.2f", amount))"
            logger.debug("Payment: \(title) on \(paymentDateString)")
            
            return TimelineItem(
                id: UUID(),
                coupleId: coupleId,
                title: title,
                description: row.notes,
                itemType: .payment,
                itemDate: date,
                endDate: nil,
                completed: row.paid ?? false,
                relatedId: String(row.id),
                createdAt: createdAt,
                updatedAt: createdAt,
                task: nil,
                milestone: nil,
                vendor: nil,
                payment: nil
            )
        }
        
        logger.debug("Converted \(items.count) payment items")
        return items
    }
    
    // MARK: - Expense Transformation
    
    struct ExpenseRow: Codable {
        let id: String
        let expenseName: String
        let amount: Double
        let expenseDate: String?
        let paymentStatus: String?
        let notes: String?
        let coupleId: String?
        let createdAt: String?
        let updatedAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case expenseName = "expense_name"
            case amount
            case expenseDate = "expense_date"
            case paymentStatus = "payment_status"
            case notes
            case coupleId = "couple_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    static func transformExpenses(_ rows: [ExpenseRow]) -> [TimelineItem] {
        logger.debug("Transforming \(rows.count) expense rows")
        
        let items = rows.compactMap { row -> TimelineItem? in
            guard let id = UUID(uuidString: row.id),
                  let expenseDateString = row.expenseDate,
                  let date = TimelineDateParser.dateFromString(expenseDateString) else {
                return nil
            }
            
            let coupleId = row.coupleId.flatMap { UUID(uuidString: $0) } ?? UUID()
            let createdAt = row.createdAt.flatMap { TimelineDateParser.iso8601DateFromString($0) } ?? Date()
            let updatedAt = row.updatedAt.flatMap { TimelineDateParser.iso8601DateFromString($0) } ?? Date()
            
            let title = "\(row.expenseName) - $\(String(format: "%.2f", row.amount))"
            let completed = row.paymentStatus?.lowercased() == "paid"
            logger.debug("Expense: \(title) on \(expenseDateString)")
            
            return TimelineItem(
                id: id,
                coupleId: coupleId,
                title: title,
                description: row.notes,
                itemType: .payment,
                itemDate: date,
                endDate: nil,
                completed: completed,
                relatedId: row.id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                task: nil,
                milestone: nil,
                vendor: nil,
                payment: nil
            )
        }
        
        logger.debug("Converted \(items.count) expense items")
        return items
    }
    
    // MARK: - Vendor Transformation
    
    struct VendorRow: Codable {
        let id: Int
        let vendorName: String
        let vendorType: String?
        let isBooked: Bool
        let dateBooked: String?
        let coupleId: String?
        let createdAt: String
        let updatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case vendorName = "vendor_name"
            case vendorType = "vendor_type"
            case isBooked = "is_booked"
            case dateBooked = "date_booked"
            case coupleId = "couple_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    static func transformVendors(_ rows: [VendorRow]) -> [TimelineItem] {
        logger.debug("Transforming \(rows.count) vendor rows")
        
        let items = rows.compactMap { row -> TimelineItem? in
            // Only include vendors that have a dateBooked
            guard let dateBookedString = row.dateBooked,
                  let dateBooked = TimelineDateParser.iso8601DateFromString(dateBookedString) else {
                return nil
            }
            
            let coupleId = row.coupleId.flatMap { UUID(uuidString: $0) } ?? UUID()
            let createdAt = TimelineDateParser.iso8601DateFromString(row.createdAt) ?? Date()
            let updatedAt = TimelineDateParser.iso8601DateFromString(row.updatedAt) ?? Date()
            
            let title = "Vendor: \(row.vendorName)"
            logger.debug("Vendor: \(title) booked on \(dateBookedString)")
            
            return TimelineItem(
                id: UUID(),
                coupleId: coupleId,
                title: title,
                description: row.vendorType,
                itemType: .vendorEvent,
                itemDate: dateBooked,
                endDate: nil,
                completed: row.isBooked,
                relatedId: String(row.id),
                createdAt: createdAt,
                updatedAt: updatedAt,
                task: nil,
                milestone: nil,
                vendor: nil,
                payment: nil
            )
        }
        
        logger.debug("Converted \(items.count) vendor items")
        return items
    }
    
    // MARK: - Guest Transformation
    
    struct GuestRow: Codable {
        let id: String
        let firstName: String
        let lastName: String
        let rsvpStatus: String?
        let rsvpDate: String?
        let coupleId: String
        let createdAt: String
        let updatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case firstName = "first_name"
            case lastName = "last_name"
            case rsvpStatus = "rsvp_status"
            case rsvpDate = "rsvp_date"
            case coupleId = "couple_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    static func transformGuests(_ rows: [GuestRow]) -> [TimelineItem] {
        logger.debug("Transforming \(rows.count) guest rows")
        
        let items = rows.compactMap { row -> TimelineItem? in
            // Only include guests who have RSVPed
            guard let rsvpDateString = row.rsvpDate,
                  let rsvpDate = TimelineDateParser.dateFromString(rsvpDateString),
                  let id = UUID(uuidString: row.id),
                  let coupleId = UUID(uuidString: row.coupleId),
                  let createdAt = TimelineDateParser.iso8601DateFromString(row.createdAt),
                  let updatedAt = TimelineDateParser.iso8601DateFromString(row.updatedAt),
                  let rsvpStatus = row.rsvpStatus else {
                return nil
            }
            
            let title = "RSVP: \(row.firstName) \(row.lastName)"
            let completed = rsvpStatus.lowercased() == "accepted"
            logger.debug("Guest: \(title) - \(rsvpStatus)")
            
            return TimelineItem(
                id: id,
                coupleId: coupleId,
                title: title,
                description: "RSVP Status: \(rsvpStatus)",
                itemType: .reminder,
                itemDate: rsvpDate,
                endDate: nil,
                completed: completed,
                relatedId: row.id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                task: nil,
                milestone: nil,
                vendor: nil,
                payment: nil
            )
        }
        
        logger.debug("Converted \(items.count) guest items")
        return items
    }
}
