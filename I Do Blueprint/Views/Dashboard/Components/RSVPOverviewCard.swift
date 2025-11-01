//
//  RSVPOverviewCard.swift
//  I Do Blueprint
//
//  RSVP overview with donut chart
//

import SwiftUI
import Charts

struct RSVPOverviewCard: View {
    @ObservedObject var store: GuestStoreV2
    
    private struct RSVPData: Identifiable {
        let id = UUID()
        let name: String
        let value: Int
        let color: Color
    }
    
    private var rsvpData: [RSVPData] {
        let guests = store.guests
        let yesCount = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let pendingCount = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited || $0.rsvpStatus == .maybe }.count
        let noCount = guests.filter { $0.rsvpStatus == .declined }.count
        
        return [
            RSVPData(name: "Accepted", value: yesCount, color: AppColors.Guest.confirmed),
            RSVPData(name: "Pending", value: pendingCount, color: AppColors.Guest.pending),
            RSVPData(name: "Declined", value: noCount, color: AppColors.Guest.declined)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Guest Responses")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(store.guests.count) guests invited")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Donut Chart
            if #available(macOS 13.0, *) {
                Chart(rsvpData) { item in
                    SectorMark(
                        angle: .value("Count", item.value),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                }
                .frame(height: 220)
                .chartLegend(.hidden)
            } else {
                // Fallback for older macOS versions
                VStack(spacing: Spacing.md) {
                    ForEach(rsvpData) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.name)
                                .font(Typography.bodySmall)
                            
                            Spacer()
                            
                            Text("\(item.value)")
                                .font(Typography.bodySmall)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.vertical, Spacing.xl)
            }
            
            // Legend
            HStack(spacing: Spacing.lg) {
                ForEach(rsvpData) { item in
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        
                        Text("\(item.name): \(item.value)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.textPrimary.opacity(0.6))
                .shadow(color: AppColors.shadowLight, radius: 8, y: 4)
        )
    }
}

#Preview {
    RSVPOverviewCard(store: GuestStoreV2())
        .frame(width: 400)
        .padding()
}
