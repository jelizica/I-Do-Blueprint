//
//  SharedCardComponents.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

// MARK: - Circle Progress View

struct CircleProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    .linearGradient(
                        colors: [color.opacity(0.8), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text("Complete")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Quick Stat

struct QuickStat: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08)))
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Native Icon Badge (V6)

struct NativeIconBadge: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Image(systemName: systemName)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Native Divider Style (V6)

struct NativeDividerStyle: View {
    let opacity: Double
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(nsColor: .separatorColor).opacity(opacity),
                        Color(nsColor: .separatorColor).opacity(opacity * 0.5),
                        Color(nsColor: .separatorColor).opacity(opacity)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}
