import SwiftUI

/// Payment type selector component for choosing between individual, monthly, interval, and cyclical payments
struct PaymentTypeSelector: View {
    @Binding var selectedType: PaymentType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Type")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(PaymentType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(selectedType == type ? .white : AppColors.Budget.allocated)
                            
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedType == type ? .white : .primary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(selectedType == type ? AppColors.Budget.allocated : AppColors.Budget.allocated.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    PaymentTypeSelector(selectedType: .constant(.individual))
        .padding()
}
