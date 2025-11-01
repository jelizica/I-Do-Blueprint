import SwiftUI

struct AffordabilityAddScenarioSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2

    let onSave: (AffordabilityScenario) -> Void

    @State private var scenarioName: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Create New Scenario")
                .font(.system(size: 20, weight: .bold))

            TextField("Scenario Name", text: $scenarioName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Create") {
                    guard !scenarioName.isEmpty else {
                        return
                    }

                    guard let coupleId = SessionManager.shared.getTenantId() else {
                        return
                    }

                    let scenario = AffordabilityScenario(
                        id: UUID(),
                        scenarioName: scenarioName,
                        partner1Monthly: 0,
                        partner2Monthly: 0,
                        calculationStartDate: Date(),
                        isPrimary: false,
                        coupleId: coupleId,
                        createdAt: Date(),
                        updatedAt: nil)
                    onSave(scenario)
                }
                .buttonStyle(.borderedProminent)
                .disabled(scenarioName.isEmpty)
            }
        }
        .padding(Spacing.xxxl)
        .frame(width: 400, height: 200)
    }
}
