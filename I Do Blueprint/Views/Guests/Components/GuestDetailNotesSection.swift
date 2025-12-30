//
//  GuestDetailNotesSection.swift
//  I Do Blueprint
//
//  Notes section for guest detail modal
//

import SwiftUI

struct GuestDetailNotesSection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Notes")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
            
            Text(notes)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .cornerRadius(CornerRadius.md)
        }
    }
}
