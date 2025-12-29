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
}
