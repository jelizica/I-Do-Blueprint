import SwiftUI

/// Skeleton loading placeholder for note cards
struct NoteCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Note title
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.borderLight)
                .frame(width: 180, height: 18)
                .shimmer()

            // Note content preview
            VStack(alignment: .leading, spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(height: 12)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(height: 12)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 200, height: 12)
                    .shimmer()
            }

            // Footer with date and tags
            HStack {
                Capsule()
                    .fill(AppColors.borderLight)
                    .frame(width: 80, height: 14)
                    .shimmer()

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Capsule()
                        .fill(AppColors.borderLight)
                        .frame(width: 50, height: 18)
                        .shimmer()

                    Capsule()
                        .fill(AppColors.borderLight)
                        .frame(width: 60, height: 18)
                        .shimmer()
                }
            }
        }
        .padding(Spacing.md)
        .card()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        NoteCardSkeleton()
        NoteCardSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
