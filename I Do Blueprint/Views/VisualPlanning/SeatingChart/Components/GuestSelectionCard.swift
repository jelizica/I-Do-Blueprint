//
//  GuestSelectionCard.swift
//  I Do Blueprint
//
//  Guest selection component with search functionality
//

import SwiftUI

struct GuestSelectionCard: View {
    let guests: [SeatingGuest]
    @Binding var selectedGuestId: UUID
    @Binding var searchText: String
    
    private var filteredGuests: [SeatingGuest] {
        if searchText.isEmpty {
            return guests
        }
        return guests.filter { guest in
            guest.firstName.localizedCaseInsensitiveContains(searchText) ||
            guest.lastName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Guest")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
                .accessibleHeading(level: 2)

            Divider()

            // Search
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                TextField("Search guests...", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibleFormField(
                        label: "Search guests",
                        hint: "Filter guests by name"
                    )
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(AppColors.backgroundSecondary)
            )

            // Guest List
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(filteredGuests) { guest in
                        GuestSelectionRow(
                            guest: guest,
                            isSelected: guest.id == selectedGuestId,
                            onSelect: {
                                selectedGuestId = guest.id
                            }
                        )
                    }

                    if filteredGuests.isEmpty {
                        Text("No guests found")
                            .font(Typography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(
                    color: AppColors.shadowLight,
                    radius: ShadowStyle.light.radius,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(AppColors.borderLight, lineWidth: 1)
        )
    }
}

// MARK: - Guest Selection Row

struct GuestSelectionRow: View {
    let guest: SeatingGuest
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(guest.relationship.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(guest.initials)
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(guest.relationship.color)
                }

                // Guest Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(guest.fullName)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)

                    Text(guest.relationship.displayName)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? AppColors.primaryLight : (isHovering ? AppColors.hoverBackground : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .animation(AnimationStyle.fast, value: isHovering)
            .animation(AnimationStyle.fast, value: isSelected)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .buttonStyle(.plain)
        .accessibleActionButton(
            label: guest.fullName,
            hint: isSelected ? "Currently selected" : "Select this guest"
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedId = UUID()
    @Previewable @State var searchText = ""
    
    let sampleGuests = [
        SeatingGuest(firstName: "John", lastName: "Doe", relationship: .friend),
        SeatingGuest(firstName: "Jane", lastName: "Smith", relationship: .family),
        SeatingGuest(firstName: "Bob", lastName: "Johnson", relationship: .coworker),
    ]
    
    GuestSelectionCard(
        guests: sampleGuests,
        selectedGuestId: $selectedId,
        searchText: $searchText
    )
    .frame(width: 600)
    .padding()
}
