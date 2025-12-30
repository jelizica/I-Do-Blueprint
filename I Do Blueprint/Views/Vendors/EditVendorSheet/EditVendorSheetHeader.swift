//
//  EditVendorSheetHeader.swift
//  I Do Blueprint
//
//  Component for edit vendor sheet header
//

import SwiftUI

struct EditVendorSheetHeader: View {
    let vendorName: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Edit Vendor")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                
                Text(vendorName)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding()
        .background(AppColors.controlBackground)
    }
}

#Preview {
    EditVendorSheetHeader(
        vendorName: "Sample Photography Studio",
        onDismiss: {}
    )
}
