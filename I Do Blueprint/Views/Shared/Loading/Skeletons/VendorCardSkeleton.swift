import SwiftUI

/// Skeleton loading placeholder for vendor cards
struct VendorCardSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Avatar skeleton
            Circle()
                .fill(AppColors.borderLight)
                .frame(width: 48, height: 48)
                .shimmer()

            // Content skeleton
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Vendor name
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 140, height: 16)
                    .shimmer()

                // Status badge and category
                HStack(spacing: Spacing.sm) {
                    Capsule()
                        .fill(AppColors.borderLight)
                        .frame(width: 60, height: 18)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.borderLight)
                        .frame(width: 80, height: 12)
                        .shimmer()
                }
            }

            Spacer()

            // Price skeleton
            Capsule()
                .fill(AppColors.borderLight)
                .frame(width: 70, height: 22)
                .shimmer()
        }
        .padding(Spacing.md)
        .card()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        VendorCardSkeleton()
        VendorCardSkeleton()
        VendorCardSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
