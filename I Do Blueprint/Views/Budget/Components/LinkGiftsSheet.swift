//
//  LinkGiftsSheet.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct LinkGiftsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let availableGifts: [GiftOrOwed]
    let onLink: ([UUID]) -> Void
    @State private var selectedGiftIds: Set<UUID> = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Link Existing Gifts")
                .font(.title2)
                .fontWeight(.bold)

            if availableGifts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No gifts available to link")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("All existing gifts are already linked to this scenario")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(availableGifts) { gift in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Image(systemName: gift.type.iconName)
                                            .foregroundStyle(.secondary)
                                        Text(gift.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }

                                    if let fromPerson = gift.fromPerson {
                                        Text("From: \(fromPerson)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Text(formatCurrency(gift.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Toggle("", isOn: Binding(
                                    get: { selectedGiftIds.contains(gift.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedGiftIds.insert(gift.id)
                                        } else {
                                            selectedGiftIds.remove(gift.id)
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }
                            .padding(12)
                            .background(selectedGiftIds.contains(gift.id) ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Link Selected (\(selectedGiftIds.count))") {
                    onLink(Array(selectedGiftIds))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedGiftIds.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
