//
//  XLSXImportService.swift
//  I Do Blueprint
//
//  Service for parsing XLSX files
//

import Foundation
import CoreXLSX

/// Protocol for XLSX import operations
protocol XLSXImportProtocol {
    func parseXLSX(from url: URL) async throws -> ImportPreview
}

/// Service responsible for XLSX file parsing
final class XLSXImportService: XLSXImportProtocol {
    private let logger = AppLogger.general
    
    // MARK: - Public Interface
    
    /// Parse XLSX file and return preview
    @MainActor
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
                    domain: "XLSXImportService",
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
    
    // MARK: - Private Helpers
    
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
}
