import SwiftUI

/// Header section for payment plan setup view
struct PaymentPlanHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text("Payment Plan Setup")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create a payment schedule for your wedding expenses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PaymentPlanHeader()
        .padding()
}
