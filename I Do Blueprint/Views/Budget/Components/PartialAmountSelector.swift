//
//  PartialAmountSelector.swift
//  I Do Blueprint
//
//  Component for selecting full or partial expense amount for payment plans
//

import SwiftUI

/// Selector for choosing between full expense amount or a partial amount
struct PartialAmountSelector: View {
    @ObservedObject var formData: PaymentFormData
    let expenseAmount: Double
    let remainingUnpaid: Double
    @FocusState.Binding var focusedField: AddPaymentScheduleView.FocusedField?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Amount")
                .font(.headline)
            
            VStack(spacing: 16) {
                // Full amount option
                fullAmountOption
                
                // Partial amount option
                partialAmountOption
            }
            .padding()
            .background(AppColors.Budget.allocated.opacity(0.1))
            .cornerRadius(12)
            
            // Info message
            if formData.usePartialAmount {
                infoMessage
            }
        }
    }
    
    private var fullAmountOption: some View {
        HStack {
            Button(action: {
                formData.usePartialAmount = false
            }) {
                HStack(spacing: 12) {
                    Image(systemName: formData.usePartialAmount ? "circle" : "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(formData.usePartialAmount ? .secondary : AppColors.Budget.allocated)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remaining Unpaid Amount")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(NumberFormatter.currency.string(from: NSNumber(value: remainingUnpaid)) ?? "$0")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.Budget.allocated)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var partialAmountOption: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                formData.usePartialAmount = true
                focusedField = .partialAmount
            }) {
                HStack(spacing: 12) {
                    Image(systemName: formData.usePartialAmount ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(formData.usePartialAmount ? AppColors.Budget.allocated : .secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Partial Amount")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Pay a portion of the expense")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            if formData.usePartialAmount {
                HStack(spacing: 8) {
                    Text("$")
                        .foregroundColor(.secondary)
                    
                    TextField("Enter amount", value: $formData.partialAmount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .partialAmount)
                        .frame(maxWidth: 200)
                    
                    Text("of \(NumberFormatter.currency.string(from: NSNumber(value: remainingUnpaid)) ?? "$0") remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 36)
                
                // Validation message
                if formData.usePartialAmount && formData.partialAmount > 0 {
                    if formData.partialAmount > remainingUnpaid {
                        Label("Partial amount cannot exceed remaining unpaid amount", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 36)
                    } else {
                        HStack(spacing: 4) {
                            Text("Will remain unpaid:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(NumberFormatter.currency.string(from: NSNumber(value: remainingUnpaid - formData.partialAmount)) ?? "$0")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.Budget.pending)
                        }
                        .padding(.leading, 36)
                    }
                }
            }
        }
    }
    
    private var infoMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppColors.Budget.allocated)
                .font(.caption)
            
            Text("You're creating a payment plan for \(NumberFormatter.currency.string(from: NSNumber(value: formData.effectiveAmount)) ?? "$0") of the \(NumberFormatter.currency.string(from: NSNumber(value: remainingUnpaid)) ?? "$0") remaining unpaid. You can create additional payment plans for any remaining balance later.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(AppColors.Budget.allocated.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PartialAmountSelector_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @StateObject private var formData = PaymentFormData()
        @FocusState private var focusedField: AddPaymentScheduleView.FocusedField?
        
        var body: some View {
            PartialAmountSelector(
                formData: formData,
                expenseAmount: 20000,
                remainingUnpaid: 20000,
                focusedField: $focusedField)
                .padding()
                .frame(width: 500)
                .onAppear {
                    formData.totalAmount = 20000
                }
        }
    }
}
