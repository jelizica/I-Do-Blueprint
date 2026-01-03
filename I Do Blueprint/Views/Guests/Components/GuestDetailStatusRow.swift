//
//  GuestDetailStatusRow.swift
//  I Do Blueprint
//
//  RSVP status and meal choice row for guest detail modal
//

import SwiftUI

struct GuestDetailStatusRow: View {
    let guest: Guest
    
    var body: some View {
        HStack(spacing: Spacing.xxxl) {
            // RSVP Status
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("RSVP Status")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.textSecondary)
                
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(statusColor(for: guest.rsvpStatus))
                        .frame(width: 8, height: 8)
                    
                    Text(guest.rsvpStatus.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(statusTextColor(for: guest.rsvpStatus))
                }
            }
            
            Spacer()
            
            // Meal Choice
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Meal Choice")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text(guest.mealOption ?? "Not selected")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SemanticColors.textPrimary)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func statusColor(for status: RSVPStatus) -> Color {
        switch status {
        case .confirmed, .attending:
            return SemanticColors.success
        case .pending, .invited, .maybe:
            return SemanticColors.warning
        case .declined:
            return SemanticColors.error
        default:
            return SemanticColors.textSecondary
        }
    }
    
    private func statusTextColor(for status: RSVPStatus) -> Color {
        switch status {
        case .confirmed, .attending:
            return SemanticColors.success
        case .pending, .invited, .maybe:
            return SemanticColors.warning
        case .declined:
            return SemanticColors.error
        default:
            return SemanticColors.textSecondary
        }
    }
}
