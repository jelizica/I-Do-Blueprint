//
//  UUID+Identifiable.swift
//  I Do Blueprint
//
//  Extension to make UUID conform to Identifiable for use with SwiftUI's .sheet(item:)
//

import Foundation

extension UUID: Identifiable {
    public var id: UUID { self }
}
