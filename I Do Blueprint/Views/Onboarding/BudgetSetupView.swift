//
//  BudgetSetupView.swift
//  I Do Blueprint
//
//  Budget setup wizard for onboarding
//

import SwiftUI

struct BudgetSetupView: View {
    @State private var totalBudget: String = ""
    @State private var selectedCategories: Set<String> = []

    private let defaultCategories = [
        "Venue", "Catering", "Photography", "Videography",
        "Florist", "Music/DJ", "Attire", "Invitations",
        "Decorations", "Transportation", "Favors", "Other"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                headerSection
                budgetInputSection
                categoriesSection
                noteSection

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AppColors.background)
    }

    // MARK: - View Sections

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)

            Text("Budget Setup")
                .font(Typography.title1)
                .foregroundColor(AppColors.textPrimary)

            Text("Set up your wedding budget and select categories to track")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xl)
    }

    private var budgetInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Total Budget (Optional)")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            HStack {
                Text("$")
                    .font(Typography.bodyLarge)
                    .foregroundColor(AppColors.textSecondary)

                TextField("Enter total budget", text: $totalBudget)
                    .textFieldStyle(.plain)
                    .font(Typography.bodyRegular)
            }
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)

            Text("You can set this later or adjust it anytime")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Budget Categories")
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            Text("Select categories you want to track")
                .font(Typography.bodySmall)
                .foregroundColor(AppColors.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(defaultCategories, id: \.self) { category in
                    CategoryToggle(
                        category: category,
                        isSelected: selectedCategories.contains(category),
                        onToggle: {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    )
                }
            }
        }
    }

    private var noteSection: some View {
        Text("Note: Full budget wizard with category allocations and detailed setup will be available in the main budget section after onboarding.")
            .font(Typography.bodySmall)
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(Spacing.md)
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Category Toggle

struct CategoryToggle: View {
    let category: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)

                Text(category)
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }
            .padding(Spacing.md)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(category)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Tap to \(isSelected ? "deselect" : "select") \(category) category")
    }
}

// MARK: - Preview

#Preview("Budget Setup View") {
    BudgetSetupView()
}

#Preview("Category Toggle - Selected") {
    CategoryToggle(
        category: "Venue",
        isSelected: true,
        onToggle: {}
    )
    .padding()
    .frame(width: 200)
}

#Preview("Category Toggle - Unselected") {
    CategoryToggle(
        category: "Catering",
        isSelected: false,
        onToggle: {}
    )
    .padding()
    .frame(width: 200)
}
