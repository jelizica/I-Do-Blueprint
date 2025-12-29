//
//  ImportValidationService.swift
//  I Do Blueprint
//
//  Service for validating import data
//

import Foundation

/// Protocol for import validation operations
protocol ImportValidationProtocol {
    func validateImport(preview: ImportPreview, mappings: [ColumnMapping]) -> ImportValidationResult
}

/// Service responsible for validating import data against column mappings
final class ImportValidationService: ImportValidationProtocol {
    
    // MARK: - Public Interface
    
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
                if !email.isEmpty && !StringValidationHelpers.isValidEmail(email) {
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
                if !phone.isEmpty && !StringValidationHelpers.isValidPhone(phone) {
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
}
