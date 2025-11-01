//
//  ProgressIndicator.swift
//  I Do Blueprint
//
//  Progress indicator components
//

import SwiftUI

/// Linear progress bar
struct ProgressBar: View {
    let value: Double // 0.0 to 1.0
    let color: Color
    let backgroundColor: Color
    let height: CGFloat
    let showPercentage: Bool
    
    init(
        value: Double,
        color: Color = .blue,
        backgroundColor: Color = AppColors.border,
        height: CGFloat = 8,
        showPercentage: Bool = false
    ) {
        self.value = min(max(value, 0), 1) // Clamp between 0 and 1
        self.color = color
        self.backgroundColor = backgroundColor
        self.height = height
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: height)
                        .animation(AnimationStyle.spring, value: value)
                }
            }
            .frame(height: height)
            
            if showPercentage {
                Text("\(Int(value * 100))%")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int(value * 100))%")
        .accessibilityValue("\(Int(value * 100)) percent complete")
    }
}

/// Circular progress indicator
struct CircularProgress: View {
    let value: Double // 0.0 to 1.0
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    let showPercentage: Bool
    
    init(
        value: Double,
        color: Color = .blue,
        lineWidth: CGFloat = 8,
        size: CGFloat = 80,
        showPercentage: Bool = true
    ) {
        self.value = min(max(value, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(AnimationStyle.spring, value: value)
            
            // Percentage text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(value * 100))")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("%")
                        .font(.system(size: size * 0.15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int(value * 100))%")
        .accessibilityValue("\(Int(value * 100)) percent complete")
    }
}

/// Step progress indicator
struct StepProgress: View {
    let currentStep: Int
    let totalSteps: Int
    let color: Color
    
    init(currentStep: Int, totalSteps: Int, color: Color = .blue) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? color : color.opacity(0.2))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: step == currentStep ? 2 : 0)
                            .frame(width: 16, height: 16)
                    )
                
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? color : color.opacity(0.2))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
    }
}

/// Labeled step progress
struct LabeledStepProgress: View {
    let steps: [String]
    let currentStep: Int
    let color: Color
    
    init(steps: [String], currentStep: Int, color: Color = .blue) {
        self.steps = steps
        self.currentStep = currentStep
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Progress line
            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                    Circle()
                        .fill(index < currentStep ? color : color.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Group {
                                if index < currentStep {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textPrimary)
                                } else if index == currentStep {
                                    Circle()
                                        .stroke(color, lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                        )
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? color : color.opacity(0.2))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            
            // Step labels
            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    Text(step)
                        .font(Typography.caption)
                        .foregroundColor(index <= currentStep ? AppColors.textPrimary : AppColors.textTertiary)
                        .fontWeight(index == currentStep ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
    }
}

// MARK: - Previews

#Preview("Progress Bars") {
    VStack(spacing: Spacing.xl) {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("25% Complete")
                .font(Typography.bodySmall)
            ProgressBar(value: 0.25, color: .blue)
        }
        
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("50% Complete")
                .font(Typography.bodySmall)
            ProgressBar(value: 0.5, color: .green, showPercentage: true)
        }
        
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("75% Complete")
                .font(Typography.bodySmall)
            ProgressBar(value: 0.75, color: .orange, height: 12)
        }
        
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("100% Complete")
                .font(Typography.bodySmall)
            ProgressBar(value: 1.0, color: .green, showPercentage: true)
        }
    }
    .padding()
}

#Preview("Circular Progress") {
    HStack(spacing: Spacing.xl) {
        CircularProgress(value: 0.25, color: .blue, size: 60)
        CircularProgress(value: 0.5, color: .green, size: 80)
        CircularProgress(value: 0.75, color: .orange, size: 100)
        CircularProgress(value: 1.0, color: .green, size: 80)
    }
    .padding()
}

#Preview("Step Progress") {
    VStack(spacing: Spacing.xl) {
        StepProgress(currentStep: 1, totalSteps: 4, color: .blue)
        StepProgress(currentStep: 2, totalSteps: 4, color: .green)
        StepProgress(currentStep: 3, totalSteps: 4, color: .orange)
        StepProgress(currentStep: 4, totalSteps: 4, color: .green)
    }
    .padding()
}

#Preview("Labeled Step Progress") {
    VStack(spacing: Spacing.xl) {
        LabeledStepProgress(
            steps: ["Details", "Guests", "Vendors", "Review"],
            currentStep: 0,
            color: .blue
        )
        
        LabeledStepProgress(
            steps: ["Details", "Guests", "Vendors", "Review"],
            currentStep: 2,
            color: .blue
        )
        
        LabeledStepProgress(
            steps: ["Details", "Guests", "Vendors", "Review"],
            currentStep: 3,
            color: .green
        )
    }
    .padding()
}
