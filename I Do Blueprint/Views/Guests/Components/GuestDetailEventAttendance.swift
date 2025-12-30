//
//  GuestDetailEventAttendance.swift
//  I Do Blueprint
//
//  Event attendance section for guest detail modal
//

import SwiftUI

struct GuestDetailEventAttendance: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Event Attendance")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: Spacing.xxxl) {
                AttendanceItem(
                    label: "Ceremony",
                    isAttending: guest.attendingCeremony
                )
                
                AttendanceItem(
                    label: "Reception",
                    isAttending: guest.attendingReception
                )
            }
        }
    }
}

// MARK: - Attendance Item Component

struct AttendanceItem: View {
    let label: String
    let isAttending: Bool
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: isAttending ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(isAttending ? AppColors.success : AppColors.textTertiary)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}
