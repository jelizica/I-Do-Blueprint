import SwiftUI

/// Payment details form component that adapts based on payment type
struct PaymentDetailsForm: View {
    @ObservedObject var formData: PaymentFormData
    @FocusState.Binding var focusedField: AddPaymentScheduleView.FocusedField?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                DatePicker(
                    formData.paymentType == .individual ? "Payment Date" : "Start Date",
                    selection: $formData.startDate,
                    displayedComponents: .date)
                
                switch formData.paymentType {
                case .individual:
                    IndividualPaymentDetails(formData: formData, focusedField: $focusedField)
                case .monthly:
                    MonthlyPaymentDetails(formData: formData, focusedField: $focusedField)
                case .interval:
                    IntervalPaymentDetails(formData: formData, focusedField: $focusedField)
                case .cyclical:
                    CyclicalPaymentDetails(formData: formData, focusedField: $focusedField)
                }
            }
            .padding()
            .background(AppColors.Budget.allocated.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Individual Payment Details

struct IndividualPaymentDetails: View {
    @ObservedObject var formData: PaymentFormData
    @FocusState.Binding var focusedField: AddPaymentScheduleView.FocusedField?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Payment Amount")
                Spacer()
                TextField("$0.00", value: $formData.individualAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    .focused($focusedField, equals: .individualAmount)
                    .onSubmit { focusedField = nil }
            }
            
            PaymentTypeRadioGroup(
                isDeposit: $formData.isIndividualDeposit,
                isRetainer: $formData.isIndividualRetainer)
        }
    }
}

// MARK: - Monthly Payment Details

struct MonthlyPaymentDetails: View {
    @ObservedObject var formData: PaymentFormData
    @FocusState.Binding var focusedField: AddPaymentScheduleView.FocusedField?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Monthly Payment Amount")
                Spacer()
                TextField("$0.00", value: $formData.monthlyAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    .focused($focusedField, equals: .monthlyAmount)
                    .onSubmit { focusedField = nil }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("First Payment Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                PaymentTypeRadioGroup(
                    isDeposit: $formData.isFirstMonthlyDeposit,
                    isRetainer: $formData.isFirstMonthlyRetainer,
                    prefix: "First Payment is a ")
            }
        }
    }
}

// MARK: - Interval Payment Details

struct IntervalPaymentDetails: View {
    @ObservedObject var formData: PaymentFormData
    @FocusState.Binding var focusedField: AddPaymentScheduleView.FocusedField?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Payment Amount")
                Spacer()
                TextField("$0.00", value: $formData.intervalAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    .focused($focusedField, equals: .intervalAmount)
                    .onSubmit { focusedField = nil }
            }
            
            HStack {
                Text("Interval (Months)")
                Spacer()
                Stepper(value: $formData.intervalMonths, in: 1 ... 12) {
                    Text("\(formData.intervalMonths) month\(formData.intervalMonths == 1 ? "" : "s")")
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("First Payment Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                PaymentTypeRadioGroup(
                    isDeposit: $formData.isFirstIntervalDeposit,
                    isRetainer: $formData.isFirstIntervalRetainer,
                    prefix: "First Payment is a ")
            }
        }
    }
}

// MARK: - Cyclical Payment Details

struct CyclicalPaymentDetails: View {
    @ObservedObject var formData: PaymentFormData
    @FocusState.Binding var focusedField: AddPaymentScheduleView.FocusedField?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cyclical Payment Pattern")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Add Payment") {
                    let nextOrder = (formData.cyclicalPayments.map(\.order).max() ?? 0) + 1
                    formData.cyclicalPayments.append(CyclicalPayment(order: nextOrder))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            ForEach(formData.cyclicalPayments.indices, id: \.self) { index in
                HStack {
                    Text("#\(formData.cyclicalPayments[index].order)")
                        .frame(width: 30)
                    
                    TextField("$0.00", value: $formData.cyclicalPayments[index].amount, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .cyclicalAmount(index))
                        .onSubmit { focusedField = nil }
                    
                    if formData.cyclicalPayments.count > 1 {
                        Button("Remove") {
                            formData.cyclicalPayments.remove(at: index)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            Text("This pattern will repeat until the total amount is paid.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("First Payment Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                PaymentTypeRadioGroup(
                    isDeposit: $formData.isFirstCyclicalDeposit,
                    isRetainer: $formData.isFirstCyclicalRetainer,
                    prefix: "First Payment is a ")
            }
        }
    }
}

// MARK: - Payment Type Radio Group

struct PaymentTypeRadioGroup: View {
    @Binding var isDeposit: Bool
    @Binding var isRetainer: Bool
    var prefix: String = ""
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                isDeposit = false
                isRetainer = false
            }) {
                HStack {
                    Image(systemName: (!isDeposit && !isRetainer) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor((!isDeposit && !isRetainer) ? AppColors.Budget.allocated : .gray)
                    Text(prefix.isEmpty ? "Regular Payment" : "\(prefix)Regular Payment")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: {
                isDeposit = true
                isRetainer = false
            }) {
                HStack {
                    Image(systemName: isDeposit ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isDeposit ? AppColors.Budget.allocated : .gray)
                    Text(prefix.isEmpty ? "Deposit" : "\(prefix)Deposit")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: {
                isDeposit = false
                isRetainer = true
            }) {
                HStack {
                    Image(systemName: isRetainer ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isRetainer ? AppColors.Budget.allocated : .gray)
                    Text(prefix.isEmpty ? "Retainer" : "\(prefix)Retainer")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    @FocusState var focusedField: AddPaymentScheduleView.FocusedField?
    let formData = PaymentFormData()
    
    return PaymentDetailsForm(formData: formData, focusedField: $focusedField)
        .padding()
}
