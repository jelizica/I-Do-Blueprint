//
//  CSVImportService.swift
//  I Do Blueprint
//
//  Service for parsing CSV files
//

import Foundation

/// Protocol for CSV import operations
protocol CSVImportProtocol {
    func parseCSV(from url: URL) async throws -> ImportPreview
}

/// Service responsible for CSV file parsing
final class CSVImportService: CSVImportProtocol {
    private let logger = AppLogger.general
    
    // MARK: - Public Interface
    
    /// Parse CSV file and return preview
    @MainActor
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
    
    // MARK: - Private Helpers
    
    /// Parse a single CSV line handling quotes and commas per RFC 4180
    /// Handles escaped quotes ("") within quoted fields
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false

        let chars = Array(line)
        var i = 0

        while i < chars.count {
            let char = chars[i]

            if char == "\"" {
                // Check if this is an escaped quote (RFC 4180: "" represents a single ")
                if insideQuotes && i + 1 < chars.count && chars[i + 1] == "\"" {
                    // Escaped quote: add single quote to field and skip both characters
                    currentField.append("\"")
                    i += 2
                    continue
                } else {
                    // Toggle quote state
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                // Field separator outside of quotes
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                // Regular character
                currentField.append(char)
            }

            i += 1
        }

        // Add the last field
        fields.append(currentField.trimmingCharacters(in: .whitespaces))

        return fields
    }
}
