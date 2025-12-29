//
//  ExportModels.swift
//  I Do Blueprint
//
//  Supporting data models for export operations
//

import Foundation
import SwiftUI

// MARK: - Export Content

struct ExportContent {
    var projectTitle: String?
    var projectSubtitle: String?
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []
    var stylePreferences: StylePreferences?
}

// MARK: - Export Customizations

struct ExportCustomizations {
    var imageScale: CGFloat = 2.0
    var jpegQuality: CGFloat = 0.9
    var includeTimestamp: Bool = true
    var customHeader: String?
    var customFooter: String?
    var pageNumbering: Bool = true
    var printOptimized: Bool = false
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case pageGenerationFailed
    case imageGenerationFailed
    case unsupportedFormat
    case templateNotFound

    var errorDescription: String? {
        switch self {
        case .pageGenerationFailed: "Failed to generate PDF page"
        case .imageGenerationFailed: "Failed to generate image"
        case .unsupportedFormat: "Unsupported export format"
        case .templateNotFound: "Template not found"
        }
    }
}
