//
//  GuestPreferencesTab.swift
//  I Do Blueprint
//
//  Preferences tab content for guest detail view
//

import SwiftUI

struct GuestPreferencesTab: View {
    let guest: Guest
    
    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            if hasMealOrDietary {
                VisualPreferencesSection(guest: guest)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Preferences Set")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add meal preferences and dietary restrictions for this guest.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }
    
    private var hasMealOrDietary: Bool {
        if let mealOption = guest.mealOption, !mealOption.isEmpty {
            return true
        }
        if let dietaryRestrictions = guest.dietaryRestrictions, !dietaryRestrictions.isEmpty {
            return true
        }
        return false
    }
}
