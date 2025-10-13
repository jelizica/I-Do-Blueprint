//
//  CollaborationSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct CollaborationSettingsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Image(systemName: "person.2.badge.gearshape")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                Text("Collaboration Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Team member management and collaboration features are coming soon!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("This feature will allow you to:")
                .font(.headline)
                .padding(.top)

            VStack(alignment: .leading, spacing: 8) {
                FeatureItem(text: "Invite team members to collaborate")
                FeatureItem(text: "Manage roles and permissions")
                FeatureItem(text: "Share planning responsibilities")
                FeatureItem(text: "Coordinate vendor communications")
            }
        }
        .frame(maxWidth: 500)
        .padding()
    }
}

struct FeatureItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    CollaborationSettingsView()
}
