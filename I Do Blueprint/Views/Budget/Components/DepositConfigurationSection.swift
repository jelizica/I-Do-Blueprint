import SwiftUI

/// Deposit/Retainer configuration section with percentage or fixed amount options
struct DepositConfigurationSection: View {
    @ObservedObject var formData: PaymentFormData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deposit/Retainer")
                    .font(.headline)
                
                Spacer()
                
                Toggle("", isOn: $formData.hasDeposit)
                    .labelsHidden()
            }
            
            if formData.hasDeposit {
                VStack(spacing: 12) {
                    Picker("Deposit Type", selection: $formData.usePercentage) {
                        Text("Percentage").tag(true)
                        Text("Fixed Amount").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    if formData.usePercentage {
                        percentageDepositView
                    } else {
                        fixedAmountDepositView
                    }
                    
                    Toggle("This deposit is a retainer", isOn: $formData.isDepositRetainer)
                }
                .padding()
                .background(AppColors.textSecondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var percentageDepositView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Deposit Percentage")
                Spacer()
                Text("\(Int(formData.depositPercentage))%")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $formData.depositPercentage, in: 1 ... 99, step: 1)
            
            Text("Deposit amount: \(NumberFormatter.currency.string(from: NSNumber(value: formData.actualDepositAmount)) ?? "$0")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var fixedAmountDepositView: some View {
        HStack {
            Text("Deposit Amount")
            Spacer()
            TextField("$0.00", value: $formData.depositAmount, format: .currency(code: "USD"))
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
        }
    }
}

#Preview {
    let formData = PaymentFormData()
    formData.hasDeposit = true
    formData.totalAmount = 1000
    
    return DepositConfigurationSection(formData: formData)
        .padding()
}
