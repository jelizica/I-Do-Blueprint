import SwiftUI

/// DEPRECATED: This view is no longer used for auth/tenant gating.
/// All app flow logic is centralized in RootFlowView.
/// This file only contains legacy placeholder views.
/// Consider removing this file entirely if placeholders are moved elsewhere.

// MARK: - Placeholder Views for Future Implementation

struct TimelinePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Wedding Timeline")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Plan your wedding day timeline, set reminders, and coordinate with vendors.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Button("Coming Soon") {
                    // Placeholder action
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(true)
            }
            .padding()
            .navigationTitle("Timeline")
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Configure your wedding details, preferences, and app settings.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Button("Coming Soon") {
                    // Placeholder action
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .disabled(true)
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    TimelinePlaceholderView()
}
