//
//  RSVPStatusParsingHelpers.swift
//  I Do Blueprint
//
//  Pure functions for parsing RSVP and related status values from import data
//

import Foundation

/// Pure RSVP and status parsing utilities for import operations
enum RSVPStatusParsingHelpers {
    /// Validate and normalize RSVP status
    static func parseRSVPStatus(_ value: String) -> String? {
        let normalized = value.lowercased().trimmingCharacters(in: .whitespaces)

        let validStatuses = [
            "attending", "confirmed", "maybe", "pending", "invited",
            "save_the_date_sent", "invitation_sent", "reminded",
            "declined", "no_response"
        ]

        // Direct match
        if validStatuses.contains(normalized) {
            return normalized
        }

        // Fuzzy matching
        switch normalized {
        case "yes", "accept", "accepted", "coming":
            return "attending"
        case "no", "not coming", "cant come", "can't come":
            return "declined"
        case "unsure", "not sure", "tentative":
            return "maybe"
        case "waiting", "no reply", "no answer":
            return "pending"
        case "save the date", "std sent":
            return "save_the_date_sent"
        case "invite sent", "invitation":
            return "invitation_sent"
        default:
            return nil
        }
    }

    /// Validate and normalize invited_by value
    static func parseInvitedBy(_ value: String) -> String? {
        let normalized = value.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalized {
        case "bride1", "partner1", "partner 1", "p1":
            return "bride1"
        case "bride2", "partner2", "partner 2", "p2":
            return "bride2"
        case "both", "shared", "mutual":
            return "both"
        default:
            return nil
        }
    }

    /// Validate and normalize preferred contact method
    static func parsePreferredContactMethod(_ value: String) -> String? {
        let normalized = value.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalized {
        case "email", "e-mail", "electronic":
            return "email"
        case "phone", "call", "telephone", "mobile", "cell":
            return "phone"
        case "mail", "postal", "letter", "post":
            return "mail"
        default:
            return nil
        }
    }
}