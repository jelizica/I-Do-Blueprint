//
//  SettingsRow.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct SettingsRow<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .frame(width: 180, alignment: .leading)
                .foregroundColor(.primary)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.sm)
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsRow(label: "Currency") {
            TextField("Currency", text: .constant("USD"))
                .textFieldStyle(.roundedBorder)
        }

        SettingsRow(label: "Dark Mode") {
            Toggle("", isOn: .constant(false))
                .labelsHidden()
        }

        SettingsRow(label: "View") {
            Picker("View", selection: .constant("list")) {
                Text("List").tag("list")
                Text("Grid").tag("grid")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
    .padding()
}
