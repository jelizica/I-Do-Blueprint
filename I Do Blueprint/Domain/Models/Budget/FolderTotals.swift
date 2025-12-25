//
//  FolderTotals.swift
//  I Do Blueprint
//
//  Model for budget folder total calculations
//

import Foundation

/// Represents calculated totals for a budget folder
///
/// This struct contains the aggregated financial totals for all items
/// within a folder, including nested folders. Totals are calculated
/// recursively to include all descendants.
struct FolderTotals: Codable, Sendable, Equatable {
    /// Total amount without tax
    let withoutTax: Double
    
    /// Total tax amount
    let tax: Double
    
    /// Total amount including tax
    let withTax: Double
    
    /// Tax as a percentage (0-100) of the total amount with tax
    ///
    /// Calculates what percentage of the total (with tax) is tax itself.
    /// For example, if withTax is $100 and tax is $9.35, this returns 9.35%.
    var taxPercentage: Double {
        guard withTax > 0 else { return 0 }
        return (tax / withTax) * 100
    }
    
    /// Creates a FolderTotals instance
    /// - Parameters:
    ///   - withoutTax: Total amount without tax
    ///   - tax: Total tax amount
    ///   - withTax: Total amount including tax
    init(withoutTax: Double, tax: Double, withTax: Double) {
        self.withoutTax = withoutTax
        self.tax = tax
        self.withTax = withTax
    }
    
    /// Creates an empty FolderTotals instance with all values set to zero
    static var zero: FolderTotals {
        FolderTotals(withoutTax: 0, tax: 0, withTax: 0)
    }
}
