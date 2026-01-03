//
//  VendorStatusCard.swift
//  I Do Blueprint
//
//  Vendor status overview with gradient cards
//

import SwiftUI

struct VendorStatusCard: View {
    @ObservedObject var store: VendorStoreV2
    @State private var selectedVendor: Vendor?

    struct VendorCategory: Identifiable {
        let id = UUID()
        let name: String
        let category: String
        let status: String
        let icon: String
        let gradientColors: [Color]
    }

    private var vendorCategories: [VendorCategory] {
        let vendors = store.vendors.prefix(6)
        return vendors.map { vendor in
            VendorCategory(
                name: vendor.vendorName,
                category: vendor.vendorType ?? "Other",
                status: vendor.isBooked == true ? "Confirmed" : "Pending",
                icon: iconForVendorType(vendor.vendorType ?? ""),
                gradientColors: gradientForVendorType(vendor.vendorType ?? "")
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color.fromHex( "A855F7"))

                Text("Our Vendors")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()
            }

            // Vendor Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(vendorCategories) { vendorCategory in
                    VendorCategoryCard(vendor: vendorCategory) {
                        // Find the actual vendor from the store
                        if let actualVendor = store.vendors.first(where: { $0.vendorName == vendorCategory.name }) {
                        selectedVendor = actualVendor
                        }
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
                .shadow(color: SemanticColors.shadowLight, radius: 8, y: 4)
        )
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailModal(vendor: vendor, vendorStore: store)
                .frame(width: 900, height: 700)
        }
    }

    private func iconForVendorType(_ type: String) -> String {
        switch type.lowercased() {
        case "venue": return "mappin.circle.fill"
        case "photography", "photographer": return "camera.fill"
        case "catering", "caterer": return "fork.knife"
        case "music", "dj", "band": return "music.note"
        case "florist", "flowers": return "leaf.fill"
        default: return "briefcase.fill"
        }
    }

    private func gradientForVendorType(_ type: String) -> [Color] {
        switch type.lowercased() {
        case "venue": return [Color.fromHex( "EC4899"), Color.fromHex( "F43F5E")]
        case "photography", "photographer": return [Color.fromHex( "A855F7"), Color.fromHex( "EC4899")]
        case "catering", "caterer": return [Color.fromHex( "F97316"), Color.fromHex( "EC4899")]
        case "music", "dj", "band": return [Color.fromHex( "3B82F6"), Color.fromHex( "A855F7")]
        case "florist", "flowers": return [Color.fromHex( "10B981"), Color.fromHex( "059669")]
        default: return [Color.fromHex( "6366F1"), Color.fromHex( "8B5CF6")]
        }
    }
}

struct VendorCategoryCard: View {
    let vendor: VendorStatusCard.VendorCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: vendor.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: vendor.icon)
                        .font(.system(size: 20))
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Spacer()

                Text(vendor.status)
                    .font(Typography.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(vendor.status == "Confirmed" ? SemanticColors.success : SemanticColors.warning)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(vendor.status == "Confirmed" ? AppColors.success.opacity(0.1) : AppColors.warning.opacity(0.1))
                    )
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(vendor.name)
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                Text(vendor.category)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.textPrimary.opacity(Opacity.strong))
                .shadow(color: SemanticColors.shadowLight, radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.clear, lineWidth: 0)
        )
    }
}

#Preview {
    VendorStatusCard(store: VendorStoreV2())
        .frame(width: 500)
        .padding()
}
