//
//  ColorPaletteHarmonySection.swift
//  My Wedding Planning App
//
//  Color harmony selection section for Color Palette Creator
//

import SwiftUI

struct ColorPaletteHarmonySection: View {
    @Binding var currentHarmonyType: ColorHarmonyType
    @Binding var selectedPaletteColors: [PaletteColor]

    let generateHarmonyColors: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Color Harmony")
                    .font(.headline)

                Text("Choose a color harmony type to generate complementary colors")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Harmony type picker
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ColorHarmonyType.allCases, id: \.self) { harmonyType in
                        HStack {
                            Button(action: {
                                currentHarmonyType = harmonyType
                                generateHarmonyColors()
                            }) {
                                HStack {
                                    Circle()
                                        .fill(currentHarmonyType == harmonyType ? Color.blue : Color.clear)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.blue, lineWidth: 2))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(harmonyType.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text(harmonyType.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Generated colors preview
                if !selectedPaletteColors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated Colors:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            ForEach(selectedPaletteColors.indices, id: \.self) { index in
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(selectedPaletteColors[index].color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))

                                    Text(selectedPaletteColors[index].role.title)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                HStack {
                    Button("Back") {
                        onBack()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Next: Refine") {
                        onNext()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPaletteColors.isEmpty)
                }
            }
        }
    }
}
