import SwiftUI

struct UnifiedErrorView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRecovery: (ErrorRecoveryOption) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)
                .padding(.bottom, 8)

            Text(error.userMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(error.recoveryOptions, id: \.self) { option in
                    Button(option.title) {
                        onRecovery(option)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(Text(option.title))
                }
            }
            .padding(.top, 8)

            #if DEBUG
            Text(error.technicalDetails)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            #endif

            Button("Dismiss") {
                onDismiss()
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(minWidth: 420)
    }

    private var iconName: String {
        switch error.severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }

    private var iconColor: Color {
        switch error.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}
