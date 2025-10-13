//
//  TaxRateDialogView.swift
//  I Do Blueprint
//
//  Extracted from BudgetDevelopmentView.swift
//

import SwiftUI

struct TaxRateDialogView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var customTaxRateData: CustomTaxRateData
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(
                    "To add or modify tax rates, please go to the Settings page and configure them in the Budget Settings tab.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .navigationTitle("Add Custom Tax Rate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
