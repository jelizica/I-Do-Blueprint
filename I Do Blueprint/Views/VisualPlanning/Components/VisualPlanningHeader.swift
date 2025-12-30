//
//  VisualPlanningHeader.swift
//  I Do Blueprint
//
//  Header section with title and stats cards
//

import SwiftUI

struct VisualPlanningHeader: View {
    let moodBoardCount: Int
    let colorPaletteCount: Int
    let seatingChartCount: Int
    let onTabSelect: (VisualPlanningTab) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Title section
            titleSection
            
            // Stats cards
            statsCardsSection
        }
        .padding()
        .background(gradientBackground)
    }
    
    // MARK: - Subviews
    
    private var titleSection: some View {
        HStack {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 32))
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Visual Planning")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Create mood boards, color palettes, and plan your visual style")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var statsCardsSection: some View {
        HStack(spacing: 12) {
            InteractiveStatCard(
                title: "Mood Boards",
                value: "\(moodBoardCount)",
                color: .blue,
                icon: "photo.on.rectangle.angled"
            ) {
                onTabSelect(.moodBoards)
            }
            
            InteractiveStatCard(
                title: "Color Palettes",
                value: "\(colorPaletteCount)",
                color: .purple,
                icon: "paintpalette"
            ) {
                onTabSelect(.colorPalettes)
            }
            
            InteractiveStatCard(
                title: "Seating Charts",
                value: "\(seatingChartCount)",
                color: .green,
                icon: "tablecells"
            ) {
                onTabSelect(.seatingChart)
            }
            
            InteractiveStatCard(
                title: "Style Guide",
                value: "Active",
                color: .orange,
                icon: "star.square"
            ) {
                onTabSelect(.stylePreferences)
            }
        }
    }
    
    private var gradientBackground: some View {
        LinearGradient(
            colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    VisualPlanningHeader(
        moodBoardCount: 3,
        colorPaletteCount: 5,
        seatingChartCount: 2,
        onTabSelect: { _ in }
    )
    .frame(width: 800)
}
