import SwiftUI

/// Skeleton loading placeholder for guest cards
struct GuestCardSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Avatar skeleton
            Circle()
                .fill(AppColors.borderLight)
                .frame(width: 48, height: 48)
                .shimmer()

            // Content skeleton
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Guest name
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 160, height: 16)
                    .shimmer()

                // RSVP status and party size
                HStack(spacing: Spacing.sm) {
                    Capsule()
                        .fill(AppColors.borderLight)
                        .frame(width: 70, height: 18)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.borderLight)
                        .frame(width: 50, height: 12)
                        .shimmer()
                }
            }

            Spacer()

            // Plus one indicator skeleton
            Circle()
                .fill(AppColors.borderLight)
                .frame(width: 24, height: 24)
                .shimmer()
        }
        .padding(Spacing.md)
        .card()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        GuestCardSkeleton()
        GuestCardSkeleton()
        GuestCardSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
