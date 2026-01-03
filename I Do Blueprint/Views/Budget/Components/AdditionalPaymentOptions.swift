import SwiftUI

/// Additional payment options component for reminders and notes
struct AdditionalPaymentOptions: View {
    @Binding var enableReminders: Bool
    @Binding var notes: String
    @FocusState.Binding var focusedField: AddPaymentScheduleView.FocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Options")
                .font(.headline)

            VStack(spacing: 12) {
                Toggle("Enable Reminders", isOn: $enableReminders)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Enter any additional notes...", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3 ... 6)
                        .focused($focusedField, equals: .notes)
                        .onSubmit { focusedField = nil }
                }
            }
            .padding()
            .background(SemanticColors.textSecondary.opacity(Opacity.subtle))
            .cornerRadius(12)
        }
    }
}

#Preview {
    @FocusState var focusedField: AddPaymentScheduleView.FocusedField?

    return AdditionalPaymentOptions(
        enableReminders: .constant(true),
        notes: .constant(""),
        focusedField: $focusedField)
    .padding()
}
