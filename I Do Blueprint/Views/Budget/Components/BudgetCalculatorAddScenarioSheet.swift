//
//  BudgetCalculatorAddScenarioSheet.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct BudgetCalculatorAddScenarioSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scenarioName = ""
    let onSave: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("New Scenario")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Scenario Name", text: $scenarioName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Create") {
                    onSave(scenarioName)
                }
                .buttonStyle(.borderedProminent)
                .disabled(scenarioName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
