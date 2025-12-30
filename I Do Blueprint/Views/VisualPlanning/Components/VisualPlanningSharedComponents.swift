//
//  VisualPlanningSharedComponents.swift
//  I Do Blueprint
//
//  Reusable components for visual planning views
//

import SwiftUI

// MARK: - Interactive Stat Card

struct InteractiveStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                iconView
                
                valueText
                
                titleText
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundView)
            .overlay(borderView)
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    // MARK: - Subviews
    
    private var iconView: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Spacer()
        }
    }
    
    private var valueText: some View {
        Text(value)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
    }
    
    private var titleText: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(NSColor.controlBackgroundColor))
            .shadow(
                color: .black.opacity(isHovering ? 0.12 : 0.06),
                radius: isHovering ? 8 : 3,
                x: 0,
                y: isHovering ? 4 : 2
            )
    }
    
    private var borderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(isHovering ? 0.4 : 0.3), lineWidth: 1)
    }
}

// MARK: - Visual Planning Card

struct VisualPlanningCard<Content: View>: View {
    let content: Content
    let action: (() -> Void)?
    @State private var isHovering = false
    
    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var cardContent: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: .black.opacity(isHovering ? 0.12 : 0.06),
                        radius: isHovering ? 8 : 4,
                        x: 0,
                        y: isHovering ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.textSecondary.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1)
            )
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}

// MARK: - Skeleton Loaders

struct SkeletonLoader: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.textSecondary.opacity(0.3))
            .frame(width: width, height: height)
            .modifier(ShimmerModifier())
    }
}

struct SkeletonCardLoader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.textSecondary.opacity(0.3))
                .frame(height: 200)
                .modifier(ShimmerModifier())
            
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.textSecondary.opacity(0.3))
                .frame(width: 150, height: 16)
                .modifier(ShimmerModifier())
            
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.textSecondary.opacity(0.3))
                .frame(width: 200, height: 12)
                .modifier(ShimmerModifier())
            
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.textSecondary.opacity(0.3))
                .frame(width: 100, height: 12)
                .modifier(ShimmerModifier())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Previews

#Preview("Interactive Stat Card") {
    InteractiveStatCard(
        title: "Mood Boards",
        value: "3",
        color: .blue,
        icon: "photo.on.rectangle.angled",
        action: {}
    )
    .frame(width: 200)
}

#Preview("Visual Planning Card") {
    VisualPlanningCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Title")
                .font(.headline)
            Text("Card content goes here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    .frame(width: 300)
}

#Preview("Skeleton Loader") {
    VStack(spacing: 12) {
        SkeletonLoader(width: 200, height: 20)
        SkeletonLoader(width: 150, height: 16)
        SkeletonCardLoader()
    }
    .padding()
    .frame(width: 400)
}
