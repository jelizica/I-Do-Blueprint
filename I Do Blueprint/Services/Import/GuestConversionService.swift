//
//  GuestConversionService.swift
//  I Do Blueprint
//
//  Service for converting import data to Guest objects
//

import Foundation

/// Protocol for guest conversion operations
protocol GuestConversionProtocol {
    func convertToGuests(preview: ImportPreview, mappings: [ColumnMapping], coupleId: UUID) -> [Guest]
}

/// Service responsible for converting CSV/XLSX rows to Guest objects
final class GuestConversionService: GuestConversionProtocol {
    private let logger = AppLogger.general
    
    // MARK: - Public Interface
    
    /// Convert CSV rows to Guest objects using column mappings
    func convertToGuests(
        preview: ImportPreview,
        mappings: [ColumnMapping],
        coupleId: UUID
    ) -> [Guest] {
        var guests: [Guest] = []
        let now = Date()
        
        logger.info("Converting guests: \(preview.rows.count) rows, \(mappings.count) mappings")
        logger.info("Mappings: \(mappings.map { "\($0.sourceColumn) -> \($0.targetField)" }.joined(separator: ", "))")
        
        for row in preview.rows {
            // Skip rows with wrong column count
            guard row.count == preview.headers.count else { continue }
            
            // Extract values using mappings
            let values = extractValues(from: row, headers: preview.headers, mappings: mappings)
            
            // Required fields
            guard let firstName = values["firstName"]?.trimmingCharacters(in: .whitespaces),
                  !firstName.isEmpty,
                  let lastName = values["lastName"]?.trimmingCharacters(in: .whitespaces),
                  !lastName.isEmpty else {
                continue
            }
            
            // Parse RSVP status
            let rsvpStatus = parseRSVPStatus(from: values["rsvpStatus"])
            
            // Parse invited_by
            let invitedBy = parseInvitedBy(from: values["invitedBy"])
            
            // Parse preferred contact method
            let preferredContactMethod = parsePreferredContactMethod(from: values["preferredContactMethod"])
            
            // Create guest object
            let guest = Guest(
                id: UUID(),
                createdAt: now,
                updatedAt: now,
                firstName: firstName,
                lastName: lastName,
                email: values["email"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                phone: values["phone"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                guestGroupId: nil,
                relationshipToCouple: values["relationshipToCouple"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                invitedBy: invitedBy,
                rsvpStatus: rsvpStatus,
                rsvpDate: values["rsvpDate"].flatMap { DateParsingHelpers.parseDate($0) },
                plusOneAllowed: DateParsingHelpers.parseBoolean(values["plusOneAllowed"] ?? "") ?? false,
                plusOneName: values["plusOneName"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                plusOneAttending: DateParsingHelpers.parseBoolean(values["plusOneAttending"] ?? "") ?? false,
                attendingCeremony: DateParsingHelpers.parseBoolean(values["attendingCeremony"] ?? "") ?? true,
                attendingReception: DateParsingHelpers.parseBoolean(values["attendingReception"] ?? "") ?? true,
                attendingRehearsal: DateParsingHelpers.parseBoolean(values["attendingRehearsal"] ?? "") ?? true,
                attendingOtherEvents: nil,
                dietaryRestrictions: values["dietaryRestrictions"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                accessibilityNeeds: values["accessibilityNeeds"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                tableAssignment: values["tableAssignment"].flatMap { DateParsingHelpers.parseInteger($0) },
                seatNumber: values["seatNumber"].flatMap { DateParsingHelpers.parseInteger($0) },
                preferredContactMethod: preferredContactMethod,
                addressLine1: values["addressLine1"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                addressLine2: values["addressLine2"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                city: values["city"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                state: values["state"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                zipCode: values["zipCode"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                country: values["country"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? "USA",
                invitationNumber: values["invitationNumber"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                isWeddingParty: DateParsingHelpers.parseBoolean(values["isWeddingParty"] ?? "") ?? false,
                weddingPartyRole: values["weddingPartyRole"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                preparationNotes: values["preparationNotes"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                coupleId: coupleId,
                mealOption: values["mealOption"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                giftReceived: DateParsingHelpers.parseBoolean(values["giftReceived"] ?? "") ?? false,
                notes: values["notes"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                hairDone: DateParsingHelpers.parseBoolean(values["hairDone"] ?? "") ?? false,
                makeupDone: DateParsingHelpers.parseBoolean(values["makeupDone"] ?? "") ?? false
            )
            
            guests.append(guest)
        }
        
        logger.info("Converted \(guests.count) guests from import")
        return guests
    }
    
    // MARK: - Private Helpers
    
    /// Extract values from row using mappings
    private func extractValues(from row: [String], headers: [String], mappings: [ColumnMapping]) -> [String: String] {
        var values: [String: String] = [:]
        for mapping in mappings {
            if let columnIndex = headers.firstIndex(of: mapping.sourceColumn) {
                values[mapping.targetField] = row[columnIndex]
            }
        }
        return values
    }
    
    /// Parse RSVP status from string value
    private func parseRSVPStatus(from value: String?) -> RSVPStatus {
        guard let value = value else { return .pending }
        
        if let parsed = RSVPStatusParsingHelpers.parseRSVPStatus(value),
           let status = RSVPStatus(rawValue: parsed) {
            return status
        }
        return .pending
    }
    
    /// Parse invited by from string value
    private func parseInvitedBy(from value: String?) -> InvitedBy? {
        guard let value = value else { return nil }
        
        if let parsed = RSVPStatusParsingHelpers.parseInvitedBy(value),
           let invitedBy = InvitedBy(rawValue: parsed) {
            return invitedBy
        }
        return nil
    }
    
    /// Parse preferred contact method from string value
    private func parsePreferredContactMethod(from value: String?) -> PreferredContactMethod? {
        guard let value = value else { return nil }
        
        if let parsed = RSVPStatusParsingHelpers.parsePreferredContactMethod(value),
           let method = PreferredContactMethod(rawValue: parsed) {
            return method
        }
        return nil
    }
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
