//
//  BouquetFlowerView.swift
//  I Do Blueprint
//
//  The core flower visualization component for the Budget Bouquet
//  Renders petals representing budget categories in a radial layout
//

import SwiftUI

// MARK: - Main Flower View

struct BouquetFlowerView: View {
    let categories: [BudgetCategory]
    let totalBudget: Double
    @Binding var hoveredCategoryId: UUID?
    @Binding var selectedCategoryId: UUID?
    let animateFlower: Bool

    // MARK: - Computed Properties

    /// Categories sorted by allocated amount (largest first for better visual layout)
    private var sortedCategories: [BudgetCategory] {
        categories.sorted { $0.allocatedAmount > $1.allocatedAmount }
    }

    /// Calculate petal angle based on budget proportion
    private func petalAngle(for category: BudgetCategory, at index: Int, total: Int) -> Double {
        let baseAngle = 360.0 / Double(max(total, 1))
        return Double(index) * baseAngle
    }

    /// Calculate petal size based on budget proportion
    private func petalSize(for category: BudgetCategory, maxRadius: CGFloat) -> CGSize {
        guard totalBudget > 0 else { return CGSize(width: 40, height: 80) }

        let proportion = category.allocatedAmount / totalBudget
        // Scale petal length based on proportion (min 60, max based on container)
        let length = max(60, min(maxRadius * 0.75, maxRadius * CGFloat(proportion) * 2.5))
        // Width is proportional to length
        let width = length * 0.4

        return CGSize(width: width, height: length)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - Spacing.xl

            ZStack {
                // Background glow
                backgroundGlow(center: center, radius: maxRadius)

                // Petals
                ForEach(Array(sortedCategories.enumerated()), id: \.element.id) { index, category in
                    PetalView(
                        category: category,
                        size: petalSize(for: category, maxRadius: maxRadius),
                        angle: petalAngle(for: category, at: index, total: sortedCategories.count),
                        isHovered: hoveredCategoryId == category.id,
                        isSelected: selectedCategoryId == category.id,
                        animateFlower: animateFlower
                    )
                    .position(center)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedCategoryId == category.id {
                                selectedCategoryId = nil
                            } else {
                                selectedCategoryId = category.id
                            }
                        }
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredCategoryId = hovering ? category.id : nil
                        }
                    }
                }

                // Center hub
                centerHub(at: center, radius: min(50, maxRadius * 0.25))
            }
        }
    }

    // MARK: - Background Glow

    @ViewBuilder
    private func backgroundGlow(center: CGPoint, radius: CGFloat) -> some View {
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
        .blur(radius: 20)
    }

    // MARK: - Center Hub

    @ViewBuilder
    private func centerHub(at center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            // Outer ring
            Circle()
                .fill(SemanticColors.backgroundSecondary)
                .frame(width: radius * 2.4, height: radius * 2.4)
                .shadow(color: AppColors.shadowLight, radius: 8, x: 0, y: 2)

            // Inner circle with gradient
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
                .frame(width: radius * 2, height: radius * 2)

            // Total amount text
            VStack(spacing: Spacing.xxs) {
                Text("Total")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textOnPrimary.opacity(0.8))

                Text(formatCurrency(totalBudget))
                    .font(Typography.numberSmall)
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .position(center)
        .scaleEffect(animateFlower ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateFlower)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0

        if value >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            return formatter.string(from: NSNumber(value: value / 1_000_000))?.replacingOccurrences(of: "$", with: "$") ?? "$0" + "M"
        } else if value >= 1000 {
            return formatter.string(from: NSNumber(value: value / 1000))?.replacingOccurrences(of: "$", with: "$") ?? "$0" + "K"
        }

        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Petal View

struct PetalView: View {
    let category: BudgetCategory
    let size: CGSize
    let angle: Double
    let isHovered: Bool
    let isSelected: Bool
    let animateFlower: Bool

    private var spendingStatus: BouquetSpendingStatus {
        BouquetSpendingStatus.from(category: category)
    }

    private var petalColor: Color {
        Color.fromHex(category.color)
    }

    private var glowColor: Color {
        spendingStatus.color
    }

    private var petalOpacity: Double {
        switch spendingStatus {
        case .notStarted: return 0.4
        case .underBudget: return 0.85
        case .onTrack: return 0.95
        case .overBudget: return 1.0
        }
    }

    var body: some View {
        ZStack {
            // Glow effect for hover/selected states
            if isHovered || isSelected {
                petalShape
                    .fill(glowColor.opacity(0.3))
                    .blur(radius: 8)
                    .scaleEffect(1.1)
            }

            // Main petal
            petalShape
                .fill(
                    LinearGradient(
                        colors: [
                            petalColor.opacity(petalOpacity),
                            petalColor.opacity(petalOpacity * 0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    petalShape
                        .stroke(
                            isSelected ? glowColor : petalColor.opacity(0.5),
                            lineWidth: isSelected ? 2 : 1
                        )
                )

            // Status indicator dot at petal tip
            if spendingStatus != .notStarted {
                statusIndicator
            }
        }
        .rotationEffect(.degrees(angle))
        .scaleEffect(isHovered ? 1.08 : (isSelected ? 1.05 : 1.0))
        .scaleEffect(animateFlower ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.6)
                .delay(Double.random(in: 0.1...0.4)),
            value: animateFlower
        )
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var petalShape: some Shape {
        PetalShape(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(glowColor)
            .frame(width: 8, height: 8)
            .shadow(color: glowColor.opacity(0.5), radius: 4)
            .offset(y: -size.height * 0.85)
    }
}

// MARK: - Petal Shape

struct PetalShape: Shape {
    let width: CGFloat
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let centerX = rect.midX
        let startY = rect.midY + 10 // Offset from center for stem attachment

        // Create an ellipse-like petal shape
        path.move(to: CGPoint(x: centerX, y: startY))

        // Left curve
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: startY - height),
            control: CGPoint(x: centerX - width, y: startY - height * 0.5)
        )

        // Right curve
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: startY),
            control: CGPoint(x: centerX + width, y: startY - height * 0.5)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Flower View") {
    BouquetFlowerView(
        categories: [
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Venue",
                allocatedAmount: 15000,
                spentAmount: 12000,
                priorityLevel: 1,
                isEssential: true,
                forecastedAmount: 15000,
                confidenceLevel: 0.9,
                lockedAllocation: false,
                color: "#EF2A78",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Photography",
                allocatedAmount: 5000,
                spentAmount: 2500,
                priorityLevel: 2,
                isEssential: true,
                forecastedAmount: 5000,
                confidenceLevel: 0.8,
                lockedAllocation: false,
                color: "#83A276",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Catering",
                allocatedAmount: 8000,
                spentAmount: 9000,
                priorityLevel: 1,
                isEssential: true,
                forecastedAmount: 8500,
                confidenceLevel: 0.7,
                lockedAllocation: false,
                color: "#8F24F5",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Flowers",
                allocatedAmount: 3000,
                spentAmount: 0,
                priorityLevel: 3,
                isEssential: false,
                forecastedAmount: 3000,
                confidenceLevel: 0.6,
                lockedAllocation: false,
                color: "#DB643D",
                createdAt: Date()
            )
        ],
        totalBudget: 31000,
        hoveredCategoryId: .constant(nil),
        selectedCategoryId: .constant(nil),
        animateFlower: true
    )
    .frame(width: 500, height: 500)
    .background(SemanticColors.backgroundPrimary)
}
