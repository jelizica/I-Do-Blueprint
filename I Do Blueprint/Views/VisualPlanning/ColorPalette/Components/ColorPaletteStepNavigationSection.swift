//
//  ColorPaletteStepNavigationSection.swift
//  My Wedding Planning App
//
//  Step navigation for Color Palette Creator
//

import SwiftUI

struct ColorPaletteStepNavigationSection: View {
    @Binding var currentStep: CreatorStep
    let getStepIcon: (CreatorStep) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Creation Steps")
                .font(.headline)

            ForEach(CreatorStep.allCases, id: \.self) { step in
                HStack {
                    Image(systemName: getStepIcon(step))
                        .foregroundColor(currentStep == step ? .blue :
                            (step.rawValue < currentStep.rawValue ? .green : .gray))
                        .font(.system(size: 16, weight: .medium))

                    Text(step.title)
                        .font(.subheadline)
                        .foregroundColor(currentStep == step ? .blue : .primary)

                    Spacer()

                    if step.rawValue < currentStep.rawValue {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                .padding(.vertical, Spacing.xs)
                .onTapGesture {
                    if step.rawValue <= currentStep.rawValue {
                        currentStep = step
                    }
                }
            }
        }
    }
}
