//
//  ColumnMappingService.swift
//  I Do Blueprint
//
//  Service for inferring column mappings from headers
//

import Foundation

/// Protocol for column mapping operations
protocol ColumnMappingProtocol {
    func inferMappings(headers: [String], targetFields: [String]) -> [ColumnMapping]
}

/// Service responsible for inferring column mappings based on header names
final class ColumnMappingService: ColumnMappingProtocol {
    private let logger = AppLogger.general
    
    // MARK: - Public Interface
    
    /// Infer column mappings based on header names with comprehensive pattern matching
    func inferMappings(headers: [String], targetFields: [String]) -> [ColumnMapping] {
        var mappings: [ColumnMapping] = []
        var usedHeaders = Set<String>()
        
        logger.info("Inferring mappings for \(headers.count) headers: \(headers)")
        
        for header in headers {
            guard !usedHeaders.contains(header) else { continue }
            
            // Skip empty headers
            guard !header.trimmingCharacters(in: .whitespaces).isEmpty else {
                logger.warning("Skipping empty header")
                continue
            }
            
            let normalizedHeader = normalizeHeader(header)
            logger.debug("Normalized header '\(header)' -> '\(normalizedHeader)'")
            
            // Try to match with target fields using pattern matching
            if let matchedField = matchHeaderToField(normalizedHeader: normalizedHeader, targetFields: targetFields) {
                logger.info("Mapped '\(header)' -> '\(matchedField)'")
                mappings.append(ColumnMapping(
                    sourceColumn: header,
                    targetField: matchedField,
                    isRequired: isRequiredField(matchedField)
                ))
                usedHeaders.insert(header)
            } else {
                logger.warning("No match found for header '\(header)' (normalized: '\(normalizedHeader)')")
            }
        }
        
        logger.info("Created \(mappings.count) mappings")
        return mappings
    }
    
    // MARK: - Private Helpers
    
    /// Normalize header for matching
    private func normalizeHeader(_ header: String) -> String {
        return header.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
    
    /// Match a normalized header to a target field using pattern matching
    private func matchHeaderToField(normalizedHeader: String, targetFields: [String]) -> String? {
        // Try exact match first
        for field in targetFields {
            let normalizedField = field.lowercased()
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: " ", with: "")
            
            if normalizedHeader == normalizedField {
                return field
            }
        }
        
        // Try pattern matching
        let patterns = getMappingPatterns()
        for (field, variations) in patterns {
            if targetFields.contains(field) {
                for variation in variations {
                    if normalizedHeader.contains(variation) || variation.contains(normalizedHeader) {
                        return field
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Get mapping patterns for common field variations
    private func getMappingPatterns() -> [String: [String]] {
        return [
            // Guest fields
            "firstName": ["firstname", "first", "givenname", "fname"],
            "lastName": ["lastname", "last", "surname", "familyname", "lname"],
            "email": ["email", "emailaddress", "e-mail", "mail"],
            "phone": ["phone", "phonenumber", "mobile", "cell", "telephone", "tel"],
            "rsvpStatus": ["rsvpstatus", "rsvp", "status", "response"],
            "plusOneAllowed": ["plusoneallowed", "plusone", "+1allowed", "guestallowed"],
            "plusOneName": ["plusonename", "+1name", "guestname"],
            "plusOneAttending": ["plusoneattending", "+1attending", "guestattending"],
            "attendingCeremony": ["attendingceremony", "ceremony", "ceremonyattending"],
            "attendingReception": ["attendingreception", "reception", "receptionattending"],
            "dietaryRestrictions": ["dietaryrestrictions", "dietary", "restrictions", "diet", "allergies"],
            "accessibilityNeeds": ["accessibilityneeds", "accessibility", "specialneeds", "accommodations"],
            "tableAssignment": ["tableassignment", "table", "tablenumber"],
            "seatNumber": ["seatnumber", "seat", "seatassignment"],
            "preferredContactMethod": ["preferredcontactmethod", "contactmethod", "preferredcontact", "contact"],
            "addressLine1": ["addressline1", "address1", "address", "street", "streetaddress"],
            "addressLine2": ["addressline2", "address2", "apt", "apartment", "suite"],
            "city": ["city", "town"],
            "state": ["state", "province", "region"],
            "zipCode": ["zipcode", "zip", "postalcode", "postal"],
            "country": ["country", "nation"],
            "invitationNumber": ["invitationnumber", "invitation", "inviteno", "invitenum"],
            "isWeddingParty": ["isweddingparty", "weddingparty", "bridal party", "bridalparty"],
            "weddingPartyRole": ["weddingpartyrole", "role", "partyrole"],
            "relationshipToCouple": ["relationshiptocouple", "relationship", "relation"],
            "invitedBy": ["invitedby", "invited", "side"],
            "rsvpDate": ["rsvpdate", "responsedate", "replieddate"],
            "mealOption": ["mealoption", "meal", "entree", "dinner"],
            "giftReceived": ["giftreceived", "gift", "giftgiven"],
            "notes": ["notes", "note", "comments", "comment"],
            "hairDone": ["hairdone", "hair", "hairstyling"],
            "makeupDone": ["makeupdone", "makeup", "makeupstyling"],
            "preparationNotes": ["preparationnotes", "prepnotes", "preparation"],
            
            // Vendor fields
            "vendorName": ["vendorname", "vendor", "name", "businessname", "company", "business"],
            "vendorType": ["vendortype", "type", "category", "service", "servicetype"],
            "contactName": ["contactname", "contact", "contactperson", "representative", "rep"],
            "phoneNumber": ["phonenumber", "phone", "mobile", "telephone", "contactphone", "tel"],
            "website": ["website", "web", "url", "site", "homepage"],
            "quotedAmount": ["quotedamount", "quote", "price", "cost", "amount", "estimate", "quoted"],
            "isBooked": ["isbooked", "booked", "status", "confirmed", "booking"],
            "dateBooked": ["datebooked", "bookingdate", "bookeddate", "confirmationdate", "bookdate"],
            "streetAddress": ["streetaddress", "street", "address", "address1", "line1"],
            "streetAddress2": ["streetaddress2", "address2", "apt", "suite", "unit", "line2"],
            "postalCode": ["postalcode", "postal", "zip", "zipcode"],
            "latitude": ["latitude", "lat", "geo lat", "geolat"],
            "longitude": ["longitude", "long", "lng", "geo long", "geolong"],
            "budgetCategoryId": ["budgetcategory", "category", "budgetcat", "budget"],
            "vendorCategoryId": ["vendorcategory", "vendorcat", "catid"],
            "includeInExport": ["includeinexport", "export", "include", "exportflag"],
            "imageUrl": ["imageurl", "image", "photo", "picture", "logo"]
        ]
    }
    
    /// Check if a field is required
    private func isRequiredField(_ field: String) -> Bool {
        // Guest required fields
        let guestRequiredFields = ["firstName", "lastName"]
        // Vendor required fields
        let vendorRequiredFields = ["vendorName"]
        
        return guestRequiredFields.contains(field) || vendorRequiredFields.contains(field)
    }
}
