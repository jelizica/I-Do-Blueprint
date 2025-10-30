//
//  FileImportService.swift
//  I Do Blueprint
//
//  Service for parsing CSV and XLSX files for guest/vendor import
//

import Foundation
import AppKit
import CoreXLSX

// MARK: - Import Models

struct ImportPreview {
    let headers: [String]
    let rows: [[String]]
    let totalRows: Int
    let fileName: String
    let fileType: FileType
    
    enum FileType: String {
        case csv = "CSV"
        case xlsx = "XLSX"
    }
}

struct ImportValidationResult {
    let isValid: Bool
    let errors: [ImportError]
    let warnings: [ImportWarning]
    
    struct ImportError {
        let row: Int
        let column: String
        let message: String
    }
    
    struct ImportWarning {
        let row: Int
        let column: String
        let message: String
    }
}

struct ColumnMapping {
    let sourceColumn: String
    let targetField: String
    let isRequired: Bool
}

// MARK: - File Import Service

@MainActor
final class FileImportService {
    private let logger = AppLogger.general
    
    // MARK: - CSV Parsing
    
    /// Parse CSV file and return preview
    func parseCSV(from url: URL) async throws -> ImportPreview {
        logger.info("Parsing CSV file: \(url.lastPathComponent)")
        
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard !lines.isEmpty else {
                throw FileImportError.emptyFile
            }
            
            // Parse headers
            let headers = parseCSVLine(lines[0])
            
            // Parse rows (limit preview to first 100 rows)
            let dataLines = Array(lines.dropFirst().prefix(100))
            let rows = dataLines.map { parseCSVLine($0) }
            
            let preview = ImportPreview(
                headers: headers,
                rows: rows,
                totalRows: lines.count - 1, // Exclude header
                fileName: url.lastPathComponent,
                fileType: .csv
            )
            
            logger.info("CSV parsed successfully: \(headers.count) columns, \(preview.totalRows) rows")
            return preview
            
        } catch {
            logger.error("Failed to parse CSV", error: error)
            throw FileImportError.parsingFailed(underlying: error)
        }
    }
    
    /// Parse a single CSV line handling quotes and commas
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        fields.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return fields
    }
    
    // MARK: - XLSX Parsing
    
    /// Parse XLSX file and return preview
    func parseXLSX(from url: URL) async throws -> ImportPreview {
        logger.info("Parsing XLSX file: \(url.lastPathComponent)")
        
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // Open XLSX file
            guard let file = XLSXFile(filepath: url.path) else {
                throw FileImportError.parsingFailed(underlying: NSError(
                    domain: "FileImportService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to open XLSX file"]
                ))
            }
            
            // Get worksheet paths
            let worksheetPaths = try file.parseWorksheetPaths()
            guard let firstPath = worksheetPaths.first else {
                throw FileImportError.emptyFile
            }
            
            // Parse first worksheet
            let worksheet = try file.parseWorksheet(at: firstPath)
            
            // Parse shared strings (for text cells)
            let sharedStrings = try file.parseSharedStrings()
            
            // Extract rows
            guard let rows = worksheet.data?.rows else {
                throw FileImportError.emptyFile
            }
            
            // Convert to string arrays
            var headers: [String] = []
            var dataRows: [[String]] = []
            
            for (index, row) in rows.enumerated() {
                let rowData = extractRowData(row: row, sharedStrings: sharedStrings)
                
                if index == 0 {
                    headers = rowData
                } else if index <= 100 { // Limit preview to 100 rows
                    dataRows.append(rowData)
                }
            }
            
            let preview = ImportPreview(
                headers: headers,
                rows: dataRows,
                totalRows: rows.count - 1, // Exclude header
                fileName: url.lastPathComponent,
                fileType: .xlsx
            )
            
            logger.info("XLSX parsed successfully: \(headers.count) columns, \(preview.totalRows) rows")
            return preview
            
        } catch {
            logger.error("Failed to parse XLSX", error: error)
            throw FileImportError.parsingFailed(underlying: error)
        }
    }
    
    /// Extract row data from Excel row
    private func extractRowData(row: Row, sharedStrings: SharedStrings?) -> [String] {
        var rowData: [String] = []
        
        // Get all cells in the row
        let cells = row.cells
        
        logger.debug("Extracting row with \(cells.count) cells, sharedStrings available: \(sharedStrings != nil)")
        
        // Track column index to handle empty cells
        var currentColumn = 0
        
        for cell in cells {
            // Get column reference (e.g., "A", "B", "C")
            let columnRef = cell.reference.column.value
            let columnIndex = columnLetterToIndex(columnRef)
            
            logger.debug("Cell \(columnRef): type=\(String(describing: cell.type)), value=\(String(describing: cell.value))")
            
            // Fill in empty cells if there's a gap
            while currentColumn < columnIndex {
                rowData.append("")
                currentColumn += 1
            }
            
            // Extract cell value
            let cellValue = extractCellValue(cell: cell, sharedStrings: sharedStrings)
            logger.debug("Extracted value for \(columnRef): '\(cellValue)'")
            rowData.append(cellValue)
            currentColumn += 1
        }
        
        logger.debug("Row data: \(rowData)")
        return rowData
    }
    
    /// Extract value from Excel cell
    private func extractCellValue(cell: Cell, sharedStrings: SharedStrings?) -> String {
        // Check for inline string FIRST (used by some Excel generators like openpyxl)
        if cell.type == .inlineStr, let inlineString = cell.inlineString {
            let text = inlineString.text ?? ""
            logger.debug("Extracted inline string: '\(text)'")
            return text
        }
        
        // Check if it's a shared string reference
        if cell.type == .sharedString,
           let value = cell.value,
           let index = Int(value),
           let sharedStrings = sharedStrings,
           index < sharedStrings.items.count {
            // Get the text from shared strings
            let text = sharedStrings.items[index].text ?? ""
            logger.debug("Extracted shared string at index \(index): '\(text)'")
            return text
        }
        
        // Check if it has a value
        if let value = cell.value {
            // Check if it's a date (Excel serial number)
            if let dateValue = cell.dateValue {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: dateValue)
            }
            
            // Return raw value (numbers, formulas evaluated to values)
            return value
        }
        
        return ""
    }
    
    /// Convert Excel column letter to zero-based index
    /// Examples: A=0, B=1, Z=25, AA=26, AB=27
    private func columnLetterToIndex(_ letter: String) -> Int {
        var index = 0
        for char in letter.uppercased() {
            index = index * 26 + Int(char.asciiValue! - 65) + 1
        }
        return index - 1
    }
    
    // MARK: - Validation
    
    /// Validate import data against column mappings
    func validateImport(
        preview: ImportPreview,
        mappings: [ColumnMapping]
    ) -> ImportValidationResult {
        var errors: [ImportValidationResult.ImportError] = []
        var warnings: [ImportValidationResult.ImportWarning] = []
        
        // Check required columns are mapped
        let mappedColumns = Set(mappings.map { $0.sourceColumn })
        let requiredMappings = mappings.filter { $0.isRequired }
        
        for required in requiredMappings {
            if !mappedColumns.contains(required.sourceColumn) {
                errors.append(.init(
                    row: 0,
                    column: required.targetField,
                    message: "Required field '\(required.targetField)' is not mapped"
                ))
            }
        }
        
        // Validate each row
        for (index, row) in preview.rows.enumerated() {
            let rowNumber = index + 2 // +2 because row 1 is headers, and we're 0-indexed
            
            // Check row has correct number of columns
            if row.count != preview.headers.count {
                errors.append(.init(
                    row: rowNumber,
                    column: "All",
                    message: "Row has \(row.count) columns but expected \(preview.headers.count)"
                ))
                continue
            }
            
            // Validate required fields are not empty
            for mapping in requiredMappings {
                if let columnIndex = preview.headers.firstIndex(of: mapping.sourceColumn) {
                    let value = row[columnIndex].trimmingCharacters(in: .whitespaces)
                    if value.isEmpty {
                        errors.append(.init(
                            row: rowNumber,
                            column: mapping.targetField,
                            message: "Required field '\(mapping.targetField)' is empty"
                        ))
                    }
                }
            }
            
            // Validate email format if email column exists
            if let emailMapping = mappings.first(where: { $0.targetField == "email" }),
               let columnIndex = preview.headers.firstIndex(of: emailMapping.sourceColumn) {
                let email = row[columnIndex].trimmingCharacters(in: .whitespaces)
                if !email.isEmpty && !isValidEmail(email) {
                    warnings.append(.init(
                        row: rowNumber,
                        column: "email",
                        message: "Invalid email format: \(email)"
                    ))
                }
            }
            
            // Validate phone format if phone column exists
            if let phoneMapping = mappings.first(where: { $0.targetField == "phone" }),
               let columnIndex = preview.headers.firstIndex(of: phoneMapping.sourceColumn) {
                let phone = row[columnIndex].trimmingCharacters(in: .whitespaces)
                if !phone.isEmpty && !isValidPhone(phone) {
                    warnings.append(.init(
                        row: rowNumber,
                        column: "phone",
                        message: "Invalid phone format: \(phone)"
                    ))
                }
            }
        }
        
        return ImportValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        // Basic phone validation - at least 10 digits
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digits.count >= 10
    }
    
    /// Parse boolean value from string (supports yes/no, true/false, 1/0, y/n)
    func parseBoolean(_ value: String) -> Bool? {
        let normalized = value.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "true", "yes", "y", "1", "t":
            return true
        case "false", "no", "n", "0", "f", "":
            return false
        default:
            return nil
        }
    }
    
    /// Parse date from string (supports multiple formats)
    func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        let dateFormatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "d/M/yyyy"
                return formatter
            }()
        ]
        
        for formatter in dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        
        return nil
    }
    
    /// Parse integer from string
    func parseInteger(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }
    
    /// Parse numeric/decimal value from string (for currency, coordinates, etc.)
    func parseNumeric(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
    
    /// Validate and normalize RSVP status
    func parseRSVPStatus(_ value: String) -> String? {
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
    func parseInvitedBy(_ value: String) -> String? {
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
    func parsePreferredContactMethod(_ value: String) -> String? {
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
            
            let normalizedHeader = header.lowercased()
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: " ", with: "")
            
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
    
    /// Match a normalized header to a target field using pattern matching
    private func matchHeaderToField(normalizedHeader: String, targetFields: [String]) -> String? {
        // Define mapping patterns for common variations
        let patterns: [String: [String]] = [
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
            // Vendor-specific patterns
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
    
    private func isRequiredField(_ field: String) -> Bool {
        // Define required fields based on import type
        // Guest required fields
        let guestRequiredFields = ["firstName", "lastName"]
        // Vendor required fields
        let vendorRequiredFields = ["vendorName"]
        
        return guestRequiredFields.contains(field) || vendorRequiredFields.contains(field)
    }
    
    // MARK: - Guest Conversion
    
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
            var values: [String: String] = [:]
            for mapping in mappings {
                if let columnIndex = preview.headers.firstIndex(of: mapping.sourceColumn) {
                    values[mapping.targetField] = row[columnIndex]
                }
            }
            
            // Required fields
            guard let firstName = values["firstName"]?.trimmingCharacters(in: .whitespaces),
                  !firstName.isEmpty,
                  let lastName = values["lastName"]?.trimmingCharacters(in: .whitespaces),
                  !lastName.isEmpty else {
                continue
            }
            
            // Parse RSVP status
            let rsvpStatusString = values["rsvpStatus"] ?? ""
            let rsvpStatus: RSVPStatus
            if let parsed = parseRSVPStatus(rsvpStatusString),
               let status = RSVPStatus(rawValue: parsed) {
                rsvpStatus = status
            } else {
                rsvpStatus = .pending
            }
            
            // Parse invited_by
            let invitedByString = values["invitedBy"] ?? ""
            let invitedBy: InvitedBy?
            if let parsed = parseInvitedBy(invitedByString),
               let value = InvitedBy(rawValue: parsed) {
                invitedBy = value
            } else {
                invitedBy = nil
            }
            
            // Parse preferred contact method
            let contactMethodString = values["preferredContactMethod"] ?? ""
            let preferredContactMethod: PreferredContactMethod?
            if let parsed = parsePreferredContactMethod(contactMethodString),
               let value = PreferredContactMethod(rawValue: parsed) {
                preferredContactMethod = value
            } else {
                preferredContactMethod = nil
            }
            
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
                rsvpDate: values["rsvpDate"].flatMap { parseDate($0) },
                plusOneAllowed: parseBoolean(values["plusOneAllowed"] ?? "") ?? false,
                plusOneName: values["plusOneName"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                plusOneAttending: parseBoolean(values["plusOneAttending"] ?? "") ?? false,
                attendingCeremony: parseBoolean(values["attendingCeremony"] ?? "") ?? true,
                attendingReception: parseBoolean(values["attendingReception"] ?? "") ?? true,
                attendingOtherEvents: nil,
                dietaryRestrictions: values["dietaryRestrictions"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                accessibilityNeeds: values["accessibilityNeeds"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                tableAssignment: values["tableAssignment"].flatMap { parseInteger($0) },
                seatNumber: values["seatNumber"].flatMap { parseInteger($0) },
                preferredContactMethod: preferredContactMethod,
                addressLine1: values["addressLine1"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                addressLine2: values["addressLine2"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                city: values["city"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                state: values["state"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                zipCode: values["zipCode"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                country: values["country"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? "USA",
                invitationNumber: values["invitationNumber"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                isWeddingParty: parseBoolean(values["isWeddingParty"] ?? "") ?? false,
                weddingPartyRole: values["weddingPartyRole"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                preparationNotes: values["preparationNotes"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                coupleId: coupleId,
                mealOption: values["mealOption"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                giftReceived: parseBoolean(values["giftReceived"] ?? "") ?? false,
                notes: values["notes"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                hairDone: parseBoolean(values["hairDone"] ?? "") ?? false,
                makeupDone: parseBoolean(values["makeupDone"] ?? "") ?? false
            )
            
            guests.append(guest)
        }
        
        logger.info("Converted \(guests.count) guests from CSV")
        return guests
    }
    
    // MARK: - Vendor Conversion
    
    /// Convert CSV rows to Vendor objects using column mappings
    /// Note: Vendor ID is Int64 and auto-generated by database, so we don't set it here
    func convertToVendors(
        preview: ImportPreview,
        mappings: [ColumnMapping],
        coupleId: UUID
    ) -> [VendorImportData] {
        var vendors: [VendorImportData] = []
        let now = Date()
        
        for row in preview.rows {
            // Skip rows with wrong column count
            guard row.count == preview.headers.count else { continue }
            
            // Extract values using mappings
            var values: [String: String] = [:]
            for mapping in mappings {
                if let columnIndex = preview.headers.firstIndex(of: mapping.sourceColumn) {
                    values[mapping.targetField] = row[columnIndex]
                }
            }
            
            // Required field
            guard let vendorName = values["vendorName"]?.trimmingCharacters(in: .whitespaces),
                  !vendorName.isEmpty else {
                continue
            }
            
            // Create vendor import data object
            let vendorData = VendorImportData(
                vendorName: vendorName,
                vendorType: values["vendorType"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                vendorCategoryId: values["vendorCategoryId"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                contactName: values["contactName"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                phoneNumber: values["phoneNumber"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                email: values["email"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                website: values["website"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                notes: values["notes"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                quotedAmount: values["quotedAmount"].flatMap { parseNumeric($0) },
                imageUrl: values["imageUrl"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                isBooked: parseBoolean(values["isBooked"] ?? ""),
                dateBooked: values["dateBooked"].flatMap { parseDate($0) },
                budgetCategoryId: values["budgetCategoryId"].flatMap { UUID(uuidString: $0) },
                coupleId: coupleId,
                isArchived: false,
                includeInExport: parseBoolean(values["includeInExport"] ?? "") ?? false,
                streetAddress: values["streetAddress"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                streetAddress2: values["streetAddress2"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                city: values["city"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                state: values["state"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                postalCode: values["postalCode"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                country: values["country"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? "US",
                latitude: values["latitude"].flatMap { parseNumeric($0) },
                longitude: values["longitude"].flatMap { parseNumeric($0) }
            )
            
            vendors.append(vendorData)
        }
        
        logger.info("Converted \(vendors.count) vendors from CSV")
        return vendors
    }
}

// MARK: - Vendor Import Data

/// Temporary struct for vendor import data (before database insertion)
/// Vendor uses Int64 ID which is auto-generated by database
struct VendorImportData: Codable {
    let vendorName: String
    let vendorType: String?
    let vendorCategoryId: String?
    let contactName: String?
    let phoneNumber: String?
    let email: String?
    let website: String?
    let notes: String?
    let quotedAmount: Double?
    let imageUrl: String?
    let isBooked: Bool?
    let dateBooked: Date?
    let budgetCategoryId: UUID?
    let coupleId: UUID
    let isArchived: Bool
    let includeInExport: Bool
    let streetAddress: String?
    let streetAddress2: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - File Import Errors

enum FileImportError: Error, LocalizedError {
    case emptyFile
    case parsingFailed(underlying: Error)
    case xlsxNotSupported
    case invalidFileType
    case fileAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty or contains no data"
        case .parsingFailed(let error):
            return "Failed to parse file: \(error.localizedDescription)"
        case .xlsxNotSupported:
            return "XLSX import is not yet supported. Please use CSV format."
        case .invalidFileType:
            return "Invalid file type. Please select a CSV or XLSX file."
        case .fileAccessDenied:
            return "Unable to access the file. Please check permissions."
        }
    }
}
