//
//  TimelineMilestonesCard.swift
//  I Do Blueprint
//
//  Wedding timeline with animated progress line
//

import SwiftUI

struct TimelineMilestonesCard: View {
    @ObservedObject var store: TimelineStoreV2
    
    struct TimelineMilestone: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let progress: Double
        let items: [String]
    }
    
    private var milestones: [TimelineMilestone] {
        [
            TimelineMilestone(
                title: "6 Months Before",
                description: "Venue booked, save-the-dates sent",
                progress: 1.0,
                items: ["Venue Secured", "Invites Sent"]
            ),
            TimelineMilestone(
                title: "3 Months Before",
                description: "Vendors confirmed, menu finalized",
                progress: 0.75,
                items: []
            ),
            TimelineMilestone(
                title: "1 Month Before",
                description: "Final details and rehearsal",
                progress: 0.0,
                items: ["Rehearsal Dinner", "Final Fittings", "Seating Chart"]
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(Color.fromHex( "EC4899"))
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Wedding Timeline")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Your journey to the big day")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Timeline
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                    TimelineMilestoneRow(
                        milestone: milestone,
                        isLast: index == milestones.count - 1
                    )
                }
            }
            .padding(.top, Spacing.md)
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.textPrimary.opacity(0.6))
                .shadow(color: AppColors.shadowLight, radius: 8, y: 4)
        )
    }
}

struct TimelineMilestoneRow: View {
    let milestone: TimelineMilestonesCard.TimelineMilestone
    let isLast: Bool
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .shadow(color: AppColors.shadowLight, radius: 4)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.fromHex( "EC4899"), Color.fromHex( "F43F5E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 16, height: 16)
                        .opacity(milestone.progress > 0 ? 1 : 0.3)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.fromHex( "EC4899").opacity(animatedProgress),
                                    Color.fromHex( "F43F5E").opacity(animatedProgress * 0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 60)
                        .padding(.top, Spacing.xs)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(milestone.title)
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(milestone.description)
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Progress bar if applicable
                if milestone.progress > 0 && milestone.progress < 1 {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ProgressView(value: animatedProgress, total: 1.0)
                            .tint(Color.fromHex( "EC4899"))
                        
                        Text("\(Int(animatedProgress * 100))% of planning complete")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Items
                if !milestone.items.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(milestone.items, id: \.self) { item in
                            Text(item)
                                .font(Typography.caption2)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .fill(AppColors.textPrimary.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                                .stroke(AppColors.borderLight, lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
            }
            .padding(.top, Spacing.xs)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = milestone.progress
            }
        }
    }
}

#Preview {
    TimelineMilestonesCard(store: TimelineStoreV2())
        .frame(width: 600)
        .padding()
}
