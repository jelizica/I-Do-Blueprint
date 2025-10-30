//
//  UTType+Extensions.swift
//  I Do Blueprint
//
//  Extensions for UniformTypeIdentifiers
//

import UniformTypeIdentifiers

extension UTType {
    /// Excel spreadsheet file type (.xlsx)
    static var xlsx: UTType {
        UTType(filenameExtension: "xlsx")!
    }
}
