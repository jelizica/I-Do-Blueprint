import SwiftUI

struct AffordabilityImportGiftsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2

    let scenario: AffordabilityScenario?
    let existingGifts: [GiftOrOwed]
    let onImport: ([UUID]) -> Void

    @State private var selectedGifts: Set<UUID> = []

    private let logger = AppLogger.ui

    private var availableGifts: [GiftOrOwed] {
        existingGifts.filter { gift in
            // Only show gifts that aren't already linked to this scenario
            let isRightType = gift.type == .giftReceived || gift.type == .contribution
            let notLinked = gift.scenarioId != scenario?.id
            return isRightType && notLinked
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Import Existing Gifts")
                    .font(.system(size: 28, weight: .bold))
                Text("Select gifts and contributions to import into this scenario")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)

            Divider()

            // Gifts List
            ScrollView {
                if availableGifts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No gifts or contributions available")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(availableGifts) { gift in
                            AffordabilityGiftImportRow(
                                gift: gift,
                                isSelected: selectedGifts.contains(gift.id),
                                onToggle: {
                                    if selectedGifts.contains(gift.id) {
                                        selectedGifts.remove(gift.id)
                                    } else {
                                        selectedGifts.insert(gift.id)
                                    }
                                })
                        }
                    }
                    .padding(24)
                }
            }

            Divider()

            // Footer Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Import \(selectedGifts.count) Item(s)") {
                    guard let scenario = scenario else {
                        logger.warning("No scenario selected")
                        return
                    }

                    guard let coupleId = SessionManager.shared.getTenantId() else {
                        logger.warning("No couple selected")
                        return
                    }

                    let giftIds = Array(selectedGifts)

                    logger.info("Importing \(giftIds.count) gifts for scenario \(scenario.scenarioName)")
                    onImport(giftIds)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedGifts.isEmpty)
            }
            .padding(24)
        }
        .frame(width: 600, height: 500)
    }
}
