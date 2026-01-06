//
//  Vendor+Extensions.swift
//  I Do Blueprint
//
//  Computed properties and helper methods for Vendor model
//

import SwiftUI

// MARK: - Display Properties

extension Vendor {
    /// Display name for booking status
    var statusDisplayName: String {
        if isArchived {
            return "Archived"
        }
        return isBooked == true ? "Booked" : "Available"
    }

    /// Initials from vendor name for avatar fallback
    var initials: String {
        let words = vendorName.split(separator: " ")
        let firstInitial = words.first?.first.map(String.init) ?? ""
        let lastInitial = words.count > 1 ? words.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }

    /// Status color based on booking state
    var statusColor: Color {
        if isArchived {
            return AppColors.Vendor.notContacted
        }
        return isBooked == true ? AppColors.Vendor.booked : AppColors.Vendor.pending
    }

    /// Check if vendor has any contact information
    var hasContactInfo: Bool {
        (contactName != nil && !contactName!.isEmpty) ||
        (email != nil && !email!.isEmpty) ||
        (phoneNumber != nil && !phoneNumber!.isEmpty) ||
        (website != nil && !website!.isEmpty) ||
        (instagramHandle != nil && !instagramHandle!.isEmpty)
    }

    /// Check if vendor has any financial information
    var hasFinancialInfo: Bool {
        quotedAmount != nil && quotedAmount! > 0
    }

    /// Check if vendor has notes
    var hasNotes: Bool {
        notes != nil && !notes!.isEmpty
    }
}

// MARK: - URL Helpers

extension Vendor {
    /// Formatted phone URL for calling
    var phoneURL: URL? {
        guard let phone = phoneNumber, !phone.isEmpty else { return nil }
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel:\(cleaned)")
    }

    /// Formatted email URL
    var emailURL: URL? {
        guard let email = email, !email.isEmpty else { return nil }
        return URL(string: "mailto:\(email)")
    }

    /// Website URL (handles missing protocol)
    var websiteURL: URL? {
        guard let website = website, !website.isEmpty else { return nil }
        if website.hasPrefix("http://") || website.hasPrefix("https://") {
            return URL(string: website)
        }
        return URL(string: "https://\(website)")
    }

    /// Display-friendly website string (without protocol)
    var websiteDisplayString: String? {
        guard let website = website, !website.isEmpty else { return nil }
        return website
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
    }

    /// Instagram profile URL
    var instagramURL: URL? {
        guard let handle = instagramHandle, !handle.isEmpty else { return nil }
        // Remove @ if present
        let cleanHandle = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
        return URL(string: "https://instagram.com/\(cleanHandle)")
    }

    /// Display-friendly Instagram handle (with @ prefix)
    var instagramDisplayString: String? {
        guard let handle = instagramHandle, !handle.isEmpty else { return nil }
        return handle.hasPrefix("@") ? handle : "@\(handle)"
    }
}

// MARK: - Formatting Helpers

extension Vendor {
    /// Formatted quoted amount as currency string
    var formattedQuotedAmount: String? {
        guard let amount = quotedAmount else { return nil }
        return amount.formatted(.currency(code: "USD"))
    }

    /// Formatted booking date
    var formattedBookingDate: String? {
        guard let date = dateBooked else { return nil }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    /// Category display name (uses vendorType as fallback)
    var categoryDisplayName: String? {
        budgetCategoryName ?? vendorType
    }
}

// MARK: - Icon Helpers

extension Vendor {
    /// System icon name based on vendor type
    var vendorTypeIcon: String {
        guard let type = vendorType?.lowercased() else {
            return "building.2.fill"
        }

        switch type {
        case let t where t.contains("venue"):
            return "mappin.circle.fill"
        case let t where t.contains("photo"):
            return "camera.fill"
        case let t where t.contains("video"):
            return "video.fill"
        case let t where t.contains("cater"), let t where t.contains("food"):
            return "fork.knife"
        case let t where t.contains("cake"), let t where t.contains("dessert"):
            return "birthday.cake.fill"
        case let t where t.contains("music"), let t where t.contains("dj"), let t where t.contains("band"):
            return "music.note"
        case let t where t.contains("flor"), let t where t.contains("flower"):
            return "leaf.fill"
        case let t where t.contains("dress"), let t where t.contains("attire"), let t where t.contains("bridal"):
            return "tshirt.fill"
        case let t where t.contains("hair"), let t where t.contains("makeup"), let t where t.contains("beauty"):
            return "sparkles"
        case let t where t.contains("plan"), let t where t.contains("coordinator"):
            return "calendar.badge.clock"
        case let t where t.contains("officiant"), let t where t.contains("ceremony"):
            return "person.fill"
        case let t where t.contains("transport"), let t where t.contains("limo"):
            return "car.fill"
        case let t where t.contains("rental"), let t where t.contains("decor"):
            return "chair.lounge.fill"
        case let t where t.contains("invitation"), let t where t.contains("stationery"):
            return "envelope.fill"
        case let t where t.contains("jewel"), let t where t.contains("ring"):
            return "diamond.fill"
        default:
            return "building.2.fill"
        }
    }
}

// MARK: - Test Helpers

extension Vendor {
    /// Create a test vendor for previews and testing
    static func makeTest(
        id: Int64 = 1,
        vendorName: String = "Test Vendor",
        vendorType: String? = "Photography",
        contactName: String? = "John Doe",
        phoneNumber: String? = "(555) 123-4567",
        email: String? = "test@vendor.com",
        website: String? = "www.testvendor.com",
        notes: String? = "Test notes for this vendor",
        quotedAmount: Double? = 5000,
        isBooked: Bool = true,
        dateBooked: Date? = Date(),
        includeInExport: Bool = true
    ) -> Vendor {
        Vendor(
            id: id,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: vendorName,
            vendorType: vendorType,
            vendorCategoryId: nil,
            contactName: contactName,
            phoneNumber: phoneNumber,
            email: email,
            website: website,
            notes: notes,
            quotedAmount: quotedAmount,
            imageUrl: nil,
            isBooked: isBooked,
            dateBooked: dateBooked,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: includeInExport
        )
    }
}
