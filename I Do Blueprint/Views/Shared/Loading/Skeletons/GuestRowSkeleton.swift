import SwiftUI

/// Skeleton loading placeholder for a compact guest row
struct GuestRowSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(AppColors.borderLight)
                .frame(width: 24, height: 24)
                .shimmer()

            VStack(alignment: .leading, spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 140, height: 10)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 90, height: 8)
                    .shimmer()
            }

            Spacer()

            Capsule()
                .fill(AppColors.borderLight)
                .frame(width: 70, height: 16)
                .shimmer()
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        GuestRowSkeleton()
        GuestRowSkeleton()
        GuestRowSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
