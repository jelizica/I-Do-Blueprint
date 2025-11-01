//
//  VendorsDetailedView.swift
//  I Do Blueprint
//
//  Detailed vendor view with status cards
//

import SwiftUI

struct VendorsDetailedView: View {
    @ObservedObject var store: VendorStoreV2
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Summary Cards
            HStack(spacing: Spacing.md) {
                let bookedCount = store.vendors.filter { $0.isBooked == true }.count
                
                DashboardSummaryCard(
                    title: "Total Vendors",
                    value: "\(store.vendors.count)",
                    icon: "briefcase.fill",
                    color: .purple
                )
                
                DashboardSummaryCard(
                    title: "Booked",
                    value: "\(bookedCount)",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
                
                DashboardSummaryCard(
                    title: "Pending",
                    value: "\(store.vendors.count - bookedCount)",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            // Vendor Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(store.vendors) { vendor in
                    VendorCard(vendor: vendor)
                }
            }
        }
    }
}

struct VendorCard: View {
    let vendor: Vendor
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: vendorIcon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Text(vendor.isBooked == true ? "Booked" : "Pending")
                    .font(Typography.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(vendor.isBooked == true ? AppColors.success : AppColors.warning)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        Capsule()
                            .fill((vendor.isBooked == true ? AppColors.success : AppColors.warning).opacity(0.1))
                    )
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(vendor.vendorName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                
                Text(vendor.vendorType ?? "Other")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                if let amount = vendor.quotedAmount {
                    Text("$\(Int(amount).formatted())")
                        .font(Typography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.textPrimary.opacity(0.6))
                .shadow(color: AppColors.shadowLight, radius: 8, y: 4)
        )
    }
    
    private var vendorIcon: String {
        guard let type = vendor.vendorType?.lowercased() else { return "briefcase.fill" }
        
        switch type {
        case "venue": return "mappin.circle.fill"
        case "photography", "photographer": return "camera.fill"
        case "catering", "caterer": return "fork.knife"
        case "music", "dj", "band": return "music.note"
        case "florist", "flowers": return "leaf.fill"
        default: return "briefcase.fill"
        }
    }
    
    private var gradientColors: [Color] {
        guard let type = vendor.vendorType?.lowercased() else {
            return [Color.fromHex( "6366F1"), Color.fromHex( "8B5CF6")]
        }
        
        switch type {
        case "venue": return [Color.fromHex( "EC4899"), Color.fromHex( "F43F5E")]
        case "photography", "photographer": return [Color.fromHex( "A855F7"), Color.fromHex( "EC4899")]
        case "catering", "caterer": return [Color.fromHex( "F97316"), Color.fromHex( "EC4899")]
        case "music", "dj", "band": return [Color.fromHex( "3B82F6"), Color.fromHex( "A855F7")]
        case "florist", "flowers": return [Color.fromHex( "10B981"), Color.fromHex( "059669")]
        default: return [Color.fromHex( "6366F1"), Color.fromHex( "8B5CF6")]
        }
    }
}

#Preview {
    VendorsDetailedView(store: VendorStoreV2())
        .padding()
        .frame(width: 1000)
}
