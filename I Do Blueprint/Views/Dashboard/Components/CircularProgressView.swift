//
//  CircularProgressView.swift
//  I Do Blueprint
//
//  Animated circular progress indicator
//

import SwiftUI

struct DashboardCircularProgressView: View {
    let currentValue: Double
    let goalValue: Double
    var size: CGFloat = 200
    var strokeWidth: CGFloat = 16
    var color: Color = AppColors.primary
    
    @State private var animatedProgress: Double = 0
    
    private var progressPercentage: Double {
        guard goalValue > 0 else { return 0 }
        let percentage = (currentValue / goalValue) * 100
        guard percentage.isFinite else { return 0 }
        return min(max(percentage, 0), 100)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(AppColors.borderLight, lineWidth: strokeWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress / 100)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.5), value: animatedProgress)
            
            // Center content
            VStack(spacing: Spacing.xs) {
                Text("\(Int(animatedProgress.isFinite ? animatedProgress : 0))%")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("$\(Int(currentValue).formatted()) / $\(Int(goalValue).formatted())")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .onAppear {
            withAnimation {
                animatedProgress = progressPercentage
            }
        }
        .onChange(of: progressPercentage) { newValue in
            withAnimation(.easeOut(duration: 1.5)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    DashboardCircularProgressView(
        currentValue: 32500,
        goalValue: 50000,
        size: 220,
        strokeWidth: 20,
        color: .green
    )
    .padding()
}
