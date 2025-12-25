//
//  FolderBudgetCard.swift
//  I Do Blueprint
//
//  Folder card component for budget dashboard with aggregated totals
//

import SwiftUI

struct FolderBudgetCard: View {
    let folderName: String
    let budgeted: Double
    let spent: Double
    let effectiveSpent: Double
    let childCount: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    @State private var isHovering = false
    
    private var percentageSpent: Double {
        guard budgeted > 0 else { return 0 }
        return (effectiveSpent / budgeted) * 100
    }
    
    private var remaining: Double {
        budgeted - effectiveSpent
    }
    
    private var progressColor: Color {
        if percentageSpent >= 100 {
            return .red
        } else if percentageSpent >= 90 {
            return .orange
        } else if percentageSpent >= 75 {
            return .yellow
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Header with folder icon and badge
                HStack(spacing: 8) {
                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    
                    // Folder icon
                    Image(systemName: "folder.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    // FOLDER badge
                    Text("FOLDER")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                    
                    // Item count badge
                    Text("\(childCount) items")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                
                // Circular progress indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: percentageSpent / 100)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: percentageSpent)
                    
                    // Percentage text
                    VStack(spacing: 4) {
                        Text("\(Int(percentageSpent))%")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(progressColor)
                        Text("spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, Spacing.md)
                
                // Folder name
                Text(folderName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
                
                Divider()
                    .padding(.vertical, Spacing.sm)
                
                // Budget details
                VStack(spacing: 8) {
                    HStack {
                        Text("BUDGETED")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(budgeted, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    HStack {
                        Text("SPENT")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(effectiveSpent, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(progressColor)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("REMAINING")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(remaining, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(remaining >= 0 ? .green : .red)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
            }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.5), Color.orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            // Hover effect
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.05))
                .opacity(isHovering ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            print("👆 FolderBudgetCard tapped: \(folderName)")
            onToggleExpand()
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(folderName) folder")
        .accessibilityValue("Contains \(childCount) items. \(Int(percentageSpent))% spent. Budgeted: $\(budgeted, specifier: "%.2f"), Spent: $\(effectiveSpent, specifier: "%.2f"), Remaining: $\(remaining, specifier: "%.2f")")
        .accessibilityHint(isExpanded ? "Tap to collapse folder" : "Tap to expand folder and view items")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 20) {
        FolderBudgetCard(
            folderName: "Tester Folder",
            budgeted: 1303.50,
            spent: 0,
            effectiveSpent: 0,
            childCount: 3,
            isExpanded: false,
            onToggleExpand: {}
        )
        .frame(width: 320)
        
        FolderBudgetCard(
            folderName: "Venue & Catering",
            budgeted: 15000,
            spent: 12500,
            effectiveSpent: 12500,
            childCount: 5,
            isExpanded: true,
            onToggleExpand: {}
        )
        .frame(width: 320)
        
        // Over-budget example (125%)
        FolderBudgetCard(
            folderName: "Over Budget Example",
            budgeted: 10000,
            spent: 12500,
            effectiveSpent: 12500,
            childCount: 8,
            isExpanded: false,
            onToggleExpand: {}
        )
        .frame(width: 320)
    }
    .padding()
}
