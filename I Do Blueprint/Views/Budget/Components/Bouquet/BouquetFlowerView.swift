//
//  BouquetFlowerView.swift
//  I Do Blueprint
//
//  The core flower visualization component for the Budget Bouquet
//  Renders petals representing budget categories in a radial layout
//  Each petal size is proportional to budget amount
//  Progress fill shows spent/budgeted ratio
//

import SwiftUI

// MARK: - Main Flower View

struct BouquetFlowerView: View {
    let categories: [BouquetCategoryData]
    let totalBudget: Double
    @Binding var hoveredCategoryId: String?
    @Binding var selectedCategoryId: String?
    let animateFlower: Bool
    
    /// Callback when a petal is tapped (for future navigation)
    var onPetalTap: ((BouquetCategoryData) -> Void)?
    
    // MARK: - Layout Constants
    
    private let centerHubRadius: CGFloat = 60
    private let petalWidthRatio: CGFloat = 0.4
    /// Minimum petal length as a ratio of max (smallest expense won't be smaller than this)
    private let minPetalRatio: CGFloat = 0.35
    /// Padding from container edge to petal tip
    /// Note: The parent container (flowerSection) already has Spacing.lg padding,
    /// so we only need a small additional margin here to match the hover details card alignment
    private let edgePadding: CGFloat = Spacing.xs  // 4px - just enough to prevent clipping
    
    // MARK: - Computed Properties
    
    /// Categories sorted by budget amount (largest first)
    private var sortedCategories: [BouquetCategoryData] {
        categories.sorted { $0.totalBudgeted > $1.totalBudgeted }
    }
    
    /// The largest budget amount among all categories
    private var maxCategoryBudget: Double {
        categories.map { $0.totalBudgeted }.max() ?? 1.0
    }
    
    /// Calculate the maximum petal length that fits in the container
    /// Formula: (half of container width) - centerHubRadius - edgePadding
    /// This ensures the petal tip reaches from the hub edge to near the container edge
    private func maxPetalLength(for containerWidth: CGFloat) -> CGFloat {
        // Max petal length = distance from center to edge - hub radius - padding
        let maxLength = (containerWidth / 2) - centerHubRadius - edgePadding
        // Ensure minimum reasonable size
        return max(60, maxLength)
    }
    
    /// Calculate petal length based on budget proportion relative to largest category
    /// The largest expense gets the maximum petal length, others scale proportionally
    private func petalLength(for category: BouquetCategoryData, maxLength: CGFloat) -> CGFloat {
        guard maxCategoryBudget > 0 else { return maxLength * minPetalRatio }
        
        // Calculate proportion relative to the largest category (not total budget)
        let proportion = category.totalBudgeted / maxCategoryBudget
        
        // Scale between minPetalRatio and 1.0 of maxLength
        // Use square root to prevent smallest petals from being too tiny
        let scaledProportion = sqrt(proportion)
        let minLength = maxLength * minPetalRatio
        return minLength + (maxLength - minLength) * CGFloat(scaledProportion)
    }
    
    /// Calculate angle for each petal - evenly distributed around the center
    private func petalAngle(at index: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        let angleStep = 360.0 / Double(total)
        // Start from top (270 degrees in standard coordinates, or -90)
        return -90 + Double(index) * angleStep
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate max petal length based on container width
            // maxPetalLength = (containerWidth / 2) - centerHubRadius - edgePadding
            let containerWidth = geometry.size.width
            let maxLength = maxPetalLength(for: containerWidth)
            
            // Position flower center so the top petal tip is at the top padding
            // Center Y = edgePadding + maxPetalLength + centerHubRadius
            let flowerCenterY = edgePadding + maxLength + centerHubRadius
            let center = CGPoint(x: containerWidth / 2, y: flowerCenterY)
            
            ZStack {
                // Background glow - use maxLength + centerHubRadius as the glow radius
                backgroundGlow(at: center, radius: maxLength + centerHubRadius)
                
                // Decorative elements (stem, leaves, pot)
                BouquetDecorativeElements(
                    center: center,
                    hubRadius: centerHubRadius,
                    containerHeight: geometry.size.height,
                    animate: animateFlower
                )
                // Decorative elements are visual-only; do not intercept clicks meant for petals.
                .allowsHitTesting(false)
                
                // Petals - all in a single layer around the center
                ForEach(Array(sortedCategories.enumerated()), id: \.element.id) { index, category in
                    let length = petalLength(for: category, maxLength: maxLength)
                    let angle = petalAngle(at: index, total: sortedCategories.count)
                    
                    RadialPetalView(
                        category: category,
                        length: length,
                        width: length * petalWidthRatio,
                        angle: angle,
                        centerOffset: centerHubRadius + 5,
                        isHovered: hoveredCategoryId == category.id,
                        isSelected: selectedCategoryId == category.id,
                        animate: animateFlower,
                        animationDelay: Double(index) * 0.05,
                        onTap: {
                            // Clicking navigates to category detail page
                            onPetalTap?(category)
                        },
                        onHoverChanged: { hovering in
                            // IMPORTANT: Do not couple hover to selection.
                            // On macOS, SwiftUI hover tracking can be frame-based (even when contentShape is set),
                            // which causes incorrect "selected" details when petals overlap.
                            // Selection for details is click-only; hover is visual-only.
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredCategoryId = hovering ? category.id : nil
                            }
                        }
                    )
                    .position(center)
                }
                
                // Center hub
                centerHub(at: center)
            }
        }
    }
    
    // MARK: - Background Glow
    
    @ViewBuilder
    private func backgroundGlow(at center: CGPoint, radius: CGFloat) -> some View {
        RadialGradient(
            gradient: Gradient(colors: [
                SemanticColors.primaryAction.opacity(Opacity.verySubtle),
                Color.clear
            ]),
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
        .frame(width: radius * 2, height: radius * 2)
        .position(center)
        .blur(radius: 30)
        .opacity(animateFlower ? 1 : 0)
        .animation(.easeInOut(duration: 0.8), value: animateFlower)
    }
    
    // MARK: - Center Hub
    
    @ViewBuilder
    private func centerHub(at center: CGPoint) -> some View {
        ZStack {
            // Outer ring with shadow
            Circle()
                .fill(SemanticColors.backgroundSecondary)
                .frame(width: centerHubRadius * 2.3, height: centerHubRadius * 2.3)
                .shadow(color: AppColors.shadowMedium, radius: 10, x: 0, y: 4)
            
            // Inner gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            SemanticColors.primaryAction,
                            SemanticColors.primaryActionHover
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: centerHubRadius * 2, height: centerHubRadius * 2)
            
            // Content
            VStack(spacing: Spacing.xxs) {
                Text(formatCurrency(totalBudget))
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text("Total Budget")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textOnPrimary.opacity(0.8))
                
                if totalBudget > 0 {
                    let spent = categories.reduce(0) { $0 + $1.totalSpent }
                    let percentage = Int((spent / totalBudget) * 100)
                    
                    Text("\(percentage)%")
                        .font(Typography.numberSmall)
                        .foregroundColor(SemanticColors.textOnPrimary)
                    
                    Text("Spent")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textOnPrimary.opacity(0.7))
                }
            }
            .padding(Spacing.sm)
        }
        .position(center)
        // Allow clicks/drags to reach petals underneath; hub is informational only.
        .allowsHitTesting(false)
        .scaleEffect(animateFlower ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: animateFlower)
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        
        if value >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            let millions = value / 1_000_000
            return "$\(String(format: "%.1f", millions))M"
        } else if value >= 1000 {
            let thousands = value / 1000
            return "$\(String(format: "%.0f", thousands))K"
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Radial Petal View

struct RadialPetalView: View {
    let category: BouquetCategoryData
    let length: CGFloat
    let width: CGFloat
    let angle: Double
    let centerOffset: CGFloat
    let isHovered: Bool
    let isSelected: Bool
    let animate: Bool
    let animationDelay: Double

    /// Callback when petal is tapped
    var onTap: (() -> Void)?
    /// Callback when hover state changes
    var onHoverChanged: ((Bool) -> Void)?
    
    private var progressRatio: CGFloat {
        CGFloat(min(1.0, category.progressRatio))
    }
    
    private var baseColor: Color {
        category.color
    }
    
    private var fillColor: Color {
        category.color.darkened(by: 0.3)
    }
    
    /// The total height needed for the petal including offset from center
    private var totalPetalHeight: CGFloat {
        length + centerOffset
    }
    
    /// Frame size large enough to contain the rotated petal
    /// When rotated, the bounding box needs to be the diagonal of the original
    private var frameSize: CGFloat {
        // Use the diagonal of the petal's bounding box to ensure it fits when rotated
        let petalWidth = width * 2
        let petalHeight = totalPetalHeight
        return max(petalWidth, petalHeight) * 1.5
    }
    
    /// The offset needed to position the petal so it starts at centerOffset from the flower center
    /// and extends outward by `length` pixels.
    /// The petal shape draws from frame bottom (petal base) to frame bottom - length (petal tip).
    /// We want: petal base at centerOffset from center, petal tip at centerOffset + length from center.
    /// Frame is centered in ZStack, so we offset by: -(centerOffset + length/2)
    private var petalOffset: CGFloat {
        -(centerOffset + length / 2)
    }
    
    var body: some View {
        // IMPORTANT: make the *offset petal drawing* be the interactive element.
        // This ensures hit-testing follows the same transform chain as what’s rendered.
        ZStack {
            Button {
                onTap?()
            } label: {
                ZStack {
                    // Glow effect for hover/selected
                    if isHovered || isSelected {
                        petalShape
                            .fill(statusColor.opacity(0.4))
                            .blur(radius: 10)
                            .scaleEffect(1.15)
                    }

                    // Background petal (lighter color)
                    petalShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    baseColor.opacity(0.5),
                                    baseColor.opacity(0.3)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )

                    // Progress fill (darker color, clipped to progress)
                    petalShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    fillColor,
                                    fillColor.opacity(0.8)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .clipShape(
                            ProgressClipShape(progress: progressRatio, petalLength: length)
                        )

                    // Petal outline
                    petalShape
                        .stroke(
                            isSelected ? statusColor : baseColor.opacity(0.6),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                }
                .frame(width: width * 2, height: totalPetalHeight)
                .offset(y: petalOffset)
            }
            .buttonStyle(.plain)
            // Hit-test exactly the petal shape in its own coordinates.
            .contentShape(.interaction, PetalShape(width: width, length: length))
        }
        .frame(width: frameSize, height: frameSize)
        .onHover { hovering in
            onHoverChanged?(hovering)
        }
        // CRITICAL FIX: Use _RotationEffect with ignoredByLayout() instead of .rotationEffect()
        // Regular .rotationEffect() affects how GeometryProxy converts frames between coordinate spaces,
        // causing hit-testing misalignment. _RotationEffect().ignoredByLayout() applies visual rotation
        // WITHOUT affecting coordinate space calculations, keeping hit-test areas aligned with visuals.
        // Reference: harshil.net article on rotationEffect and GeometryProxy
        .modifier(_RotationEffect(angle: .degrees(angle), anchor: .center).ignoredByLayout())
        .scaleEffect(isHovered ? 1.08 : (isSelected ? 1.05 : 1.0))
        .scaleEffect(animate ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.6).delay(animationDelay),
            value: animate
        )
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var petalShape: some Shape {
        PetalShape(width: width, length: length)
    }
    
    private var statusColor: Color {
        if category.isOverBudget {
            return SemanticColors.statusWarning
        } else if category.progressRatio >= 0.9 {
            return SemanticColors.statusPending
        } else if category.progressRatio > 0 {
            return SemanticColors.statusSuccess
        } else {
            return SemanticColors.textTertiary
        }
    }
}

// MARK: - Petal Shape

struct PetalShape: Shape {
    let width: CGFloat
    let length: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = rect.midX
        let bottomY = rect.maxY
        let topY = bottomY - length
        
        // Start at bottom center
        path.move(to: CGPoint(x: centerX, y: bottomY))
        
        // Left curve to top
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: topY),
            control: CGPoint(x: centerX - width, y: bottomY - length * 0.5)
        )
        
        // Right curve back to bottom
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: bottomY),
            control: CGPoint(x: centerX + width, y: bottomY - length * 0.5)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Progress Clip Shape

/// Clips the petal to show progress from bottom to top
struct ProgressClipShape: Shape {
    let progress: CGFloat
    let petalLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        // Clip from bottom up based on progress
        let clipHeight = rect.height * progress
        return Path(CGRect(
            x: rect.minX,
            y: rect.maxY - clipHeight,
            width: rect.width,
            height: clipHeight
        ))
    }
}

// MARK: - Decorative Elements

struct BouquetDecorativeElements: View {
    let center: CGPoint
    let hubRadius: CGFloat
    let containerHeight: CGFloat
    let animate: Bool
    
    private var stemStartY: CGFloat {
        center.y + hubRadius + 10
    }
    
    private var stemEndY: CGFloat {
        min(center.y + hubRadius + 180, containerHeight - 60)
    }
    
    private var potY: CGFloat {
        stemEndY + 20
    }
    
    var body: some View {
        ZStack {
            // Stem
            StemShape(
                startPoint: CGPoint(x: center.x, y: stemStartY),
                endPoint: CGPoint(x: center.x, y: stemEndY)
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.fromHex("#10b981"),
                        Color.fromHex("#059669")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 6, lineCap: .round)
            )
            .opacity(animate ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.3), value: animate)
            
            // Left leaf
            LeafShape()
                .fill(Color.fromHex("#10b981").opacity(0.8))
                .frame(width: 30, height: 50)
                .rotationEffect(.degrees(-30))
                .position(x: center.x - 25, y: stemStartY + 60)
                .scaleEffect(animate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4), value: animate)
            
            // Right leaf
            LeafShape()
                .fill(Color.fromHex("#059669").opacity(0.8))
                .frame(width: 30, height: 50)
                .rotationEffect(.degrees(30))
                .scaleEffect(x: -1, y: 1)
                .position(x: center.x + 25, y: stemStartY + 90)
                .scaleEffect(animate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5), value: animate)
            
            // Pot
            if potY < containerHeight - 20 {
                PotShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.fromHex("#8b5cf6").opacity(0.5),
                                Color.fromHex("#a78bfa").opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 50)
                    .position(x: center.x, y: potY + 25)
                    .scaleEffect(animate ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.6), value: animate)
            }
        }
    }
}

// MARK: - Stem Shape

struct StemShape: Shape {
    let startPoint: CGPoint
    let endPoint: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Slight curve for natural look
        let controlOffset: CGFloat = 10
        
        path.move(to: startPoint)
        path.addQuadCurve(
            to: endPoint,
            control: CGPoint(x: startPoint.x + controlOffset, y: (startPoint.y + endPoint.y) / 2)
        )
        
        return path
    }
}

// MARK: - Leaf Shape

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = rect.midX
        let topY = rect.minY
        let bottomY = rect.maxY
        let width = rect.width / 2
        
        path.move(to: CGPoint(x: centerX, y: bottomY))
        
        // Left curve
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: topY),
            control: CGPoint(x: centerX - width, y: rect.midY)
        )
        
        // Right curve
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: bottomY),
            control: CGPoint(x: centerX + width, y: rect.midY)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Pot Shape

struct PotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topWidth = rect.width
        let bottomWidth = rect.width * 0.7
        let cornerRadius: CGFloat = 8
        
        // Top edge
        path.move(to: CGPoint(x: (rect.width - topWidth) / 2 + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: (rect.width + topWidth) / 2 - cornerRadius, y: rect.minY))
        
        // Top right corner
        path.addQuadCurve(
            to: CGPoint(x: (rect.width + topWidth) / 2, y: rect.minY + cornerRadius),
            control: CGPoint(x: (rect.width + topWidth) / 2, y: rect.minY)
        )
        
        // Right edge (tapered)
        path.addLine(to: CGPoint(x: (rect.width + bottomWidth) / 2, y: rect.maxY - cornerRadius))
        
        // Bottom right corner
        path.addQuadCurve(
            to: CGPoint(x: (rect.width + bottomWidth) / 2 - cornerRadius, y: rect.maxY),
            control: CGPoint(x: (rect.width + bottomWidth) / 2, y: rect.maxY)
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: (rect.width - bottomWidth) / 2 + cornerRadius, y: rect.maxY))
        
        // Bottom left corner
        path.addQuadCurve(
            to: CGPoint(x: (rect.width - bottomWidth) / 2, y: rect.maxY - cornerRadius),
            control: CGPoint(x: (rect.width - bottomWidth) / 2, y: rect.maxY)
        )
        
        // Left edge (tapered)
        path.addLine(to: CGPoint(x: (rect.width - topWidth) / 2, y: rect.minY + cornerRadius))
        
        // Top left corner
        path.addQuadCurve(
            to: CGPoint(x: (rect.width - topWidth) / 2 + cornerRadius, y: rect.minY),
            control: CGPoint(x: (rect.width - topWidth) / 2, y: rect.minY)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Flower View") {
    let provider = BouquetDataProvider.preview()
    
    return BouquetFlowerView(
        categories: provider.categories,
        totalBudget: provider.totalBudgeted,
        hoveredCategoryId: .constant(nil),
        selectedCategoryId: .constant(nil),
        animateFlower: true
    )
    .frame(width: 500, height: 700)
    .background(SemanticColors.backgroundPrimary)
}

#Preview("Flower View - Dark") {
    let provider = BouquetDataProvider.preview()
    
    return BouquetFlowerView(
        categories: provider.categories,
        totalBudget: provider.totalBudgeted,
        hoveredCategoryId: .constant(nil),
        selectedCategoryId: .constant(nil),
        animateFlower: true
    )
    .frame(width: 500, height: 700)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
