//
//  GuestDetailAddressSection.swift
//  I Do Blueprint
//
//  Address information section for guest detail modal
//

import SwiftUI

struct GuestDetailAddressSection: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Address")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(SemanticColors.textPrimary)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let address1 = guest.addressLine1 {
                    Text(address1)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textPrimary)
                }
                
                if let address2 = guest.addressLine2 {
                    Text(address2)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textPrimary)
                }
                
                HStack(spacing: Spacing.xs) {
                    if let city = guest.city {
                        Text(city)
                    }
                    if let state = guest.state {
                        Text(", \(state)")
                    }
                    if let zip = guest.zipCode {
                        Text(zip)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textPrimary)
                
                if let country = guest.country {
                    Text(country)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }
        }
    }
}
