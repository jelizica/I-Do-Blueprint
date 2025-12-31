//
//  FileExportHelper.swift
//  I Do Blueprint
//
//  File saving and sharing utilities
//

import AppKit
import Foundation
import UniformTypeIdentifiers

/// Helper for file saving and sharing operations
@MainActor
struct FileExportHelper {
    
    // MARK: - Sharing
    
    /// Share file using system sharing picker
    static func shareFile(at url: URL, from view: NSView) {
        let sharingPicker = NSSharingServicePicker(items: [url])
        sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
    
    // MARK: - Saving
    
    /// Save file with save dialog
    static func saveFileWithDialog(at url: URL, suggestedFilename: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = suggestedFilename
        savePanel.allowedContentTypes = [.init(filenameExtension: url.pathExtension) ?? .data]
        
        if savePanel.runModal() == .OK, let destinationURL = savePanel.url {
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
            } catch {
                AppLogger.export.error("Failed to save file", error: error)
            }
        }
    }
}
