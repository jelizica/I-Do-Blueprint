//
//  BusinessDetailsSection.swift
//  I Do Blueprint
//
//  Component for vendor business details (booking status, amount)
//

import SwiftUI

struct BusinessDetailsSection: View {
    @Binding var isBooked: Bool
    @Binding var dateBooked: Date?
    @Binding var quotedAmount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VendorSectionHeader(title: "Business Details", icon: "building.2.circle.fill")
            
            VStack(spacing: Spacing.lg) {
                VendorFormField(label: "Status") {
                    Toggle("Booked", isOn: $isBooked)
                        .toggleStyle(.switch)
                        .onChange(of: isBooked) { oldValue, newValue in
                            if newValue && dateBooked == nil {
                                dateBooked = Date()
                            }
                        }
                }
                
                if isBooked {
                    VendorFormField(label: "Booked Date") {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { dateBooked ?? Date() },
                                set: { dateBooked = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.field)
                        .labelsHidden()
                    }
                }
                
                VendorFormField(label: "Quoted Amount") {
                    HStack {
                        Text("$")
                            .foregroundColor(AppColors.textSecondary)
                        TextField("0", text: $quotedAmount)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }
}

#Preview {
    BusinessDetailsSection(
        isBooked: .constant(true),
        dateBooked: .constant(Date()),
        quotedAmount: .constant("3000")
    )
    .padding()
}
