//
//  BudgetCalculatorHeader.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct BudgetCalculatorHeader: View {
    @Binding var selectedScenarioId: UUID?
    let scenarios: [AffordabilityScenario]
    let onScenarioChange: (AffordabilityScenario) -> Void
    let onAddScenario: () -> Void
    let onDeleteScenario: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.purple)
                Text("Auto-save changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Select Scenario")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("", selection: Binding(
                get: { selectedScenarioId ?? UUID() },
                set: { newId in
                    if let scenario = scenarios.first(where: { $0.id == newId }) {
                        onScenarioChange(scenario)
                    }
                }
            )) {
                ForEach(scenarios) { scenario in
                    Text(scenario.scenarioName).tag(scenario.id)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)

            Menu {
                Button(action: onAddScenario) {
                    Label("New Scenario", systemImage: "plus.circle")
                }
                if scenarios.count > 1 {
                    Button(role: .destructive, action: onDeleteScenario) {
                        Label("Delete Scenario", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
        }
    }
}
