//
//  VendorFormComponents.swift
//  I Do Blueprint
//
//  Shared form components for vendor views
//

import SwiftUI

// MARK: - Vendor Section Header

struct VendorSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppColors.Vendor.contacted)
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - Vendor Form Field

struct VendorFormField<Content: View>: View {
    let label: String
    var required: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if required {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            content
        }
    }
}
