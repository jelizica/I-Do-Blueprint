//
//  GuestDetailDietarySection.swift
//  I Do Blueprint
//
//  Dietary restrictions section for guest detail modal
//

import SwiftUI

struct GuestDetailDietarySection: View {
    let restrictions: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Dietary Restrictions")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textSecondary)
            
            // Parse restrictions and create badges
            HStack(spacing: Spacing.sm) {
                ForEach(parseRestrictions(restrictions), id: \.self) { restriction in
                    DietaryBadge(text: restriction)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func parseRestrictions(_ restrictions: String) -> [String] {
        // Split by common delimiters
        let separators = CharacterSet(charactersIn: ",;")
        return restrictions.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Dietary Badge Component

struct DietaryBadge: View {
    let text: String
    
    private var badgeColor: (background: Color, text: Color) {
        // Alternate colors for variety
        let colors: [(Color, Color)] = [
            (SemanticColors.warningLight, SemanticColors.warning),
            (SemanticColors.infoLight, SemanticColors.info)
        ]
        let index = abs(text.hashValue) % colors.count
        return (colors[index].0, colors[index].1)
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(badgeColor.text)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(badgeColor.background)
            .cornerRadius(CornerRadius.pill)
    }
}
